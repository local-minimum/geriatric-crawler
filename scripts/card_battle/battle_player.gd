extends BattleEntity
class_name BattlePlayer

signal on_player_select_targets(
    player: BattlePlayer,
    count: int,
    options: Array[BattleEntity],
    effect: BattleCardPrimaryEffect.EffectMode,
    target_type: BattleCardPrimaryEffect.EffectTarget,
)
signal on_player_select_targets_complete()
signal on_before_execute_effect_on_target(target: BattleEntity)
signal on_after_execute_effect_on_target(target: BattleEntity)
signal on_after_execute_card()

const _ID_KEY: String = "id"

@export var character_id: String = "main"

@export var _slots: BattleCardSlots

func play_actions(
    allies: Array[BattleEntity],
    enemies: Array[BattleEntity],
    hand: Array[BattleCardData] = [],
) -> void:
    _halted = false
    on_start_turn.emit(self)
    print_debug("Start player turn")

    _slots.show_slotted_cards()
    await get_tree().create_timer(0.5).timeout

    _allies = allies
    _enemies = enemies
    _hand = hand

    _execute_next_card()

var _hand: Array[BattleCardData]
var _allies: Array[BattleEntity]
var _enemies: Array[BattleEntity]
var _active_card_index: int
var _active_card_effect_index: int

func _execute_next_card() -> void:
    if _halted:
        return

    if _active_card_index >= _slots.slotted_cards.size():
        on_end_turn.emit(self)
        return

    var card: BattleCard = _slots.slotted_cards[_active_card_index]
    if card == null:
        on_end_turn.emit(self)
        return

    var battle: BattleMode = BattleMode.find_battle_parent(self)
    var suit_bonus: int = 0 if battle == null else battle.suit_bonus
    var rank_bonus: int = 0 if battle == null else battle.rank_bonus

    card.card_played = true

    var tween: Tween = get_tree().create_tween()
    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        card,
        "scale",
        Vector2.ONE * 1.5,
        0.2).set_trans(Tween.TRANS_SINE)
    @warning_ignore_restore("return_value_discarded")

    tween.play()

    var next: BattleCard = _slots.slotted_cards[_active_card_index + 1] if _active_card_index < _slots.slotted_cards.size() - 1 else null
    suit_bonus = get_suit_bonus(
        card.data,
        suit_bonus,
        battle.get_suit_bonus_step() if battle != null else 0,
        battle.previous_card if battle != null else null,
        next.data if next != null else null,
        _active_card_index == 0,
        _hand,
    )

    rank_bonus = get_rank_bonus(
        card.data,
        rank_bonus,
        battle.get_rank_bonus_step() if battle != null else 0,
        battle.previous_card if battle != null else null,
        battle.rank_direction if battle != null else 0,
        next.data if next != null else null,
        _active_card_index == 0,
        battle.get_rank_bonus_allow_descending(),
        _hand,
    )


    if battle != null:
        battle.rank_bonus = rank_bonus
        battle.rank_direction = signi(card.data.rank - battle.previous_card.rank) if battle.previous_card != null else 0

        battle.suit_bonus = suit_bonus

        battle.previous_card = card.data

    _active_card_effect_index = 0

    _execute_next_effect()


func _restore_card_size() -> void:
    if _active_card_index >= _slots.slotted_cards.size():
        return

    var card: BattleCard = _slots.slotted_cards[_active_card_index]

    if card == null:
        return

    var tween: Tween = get_tree().create_tween()
    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        card,
        "scale",
        Vector2.ONE,
        0.2).set_trans(Tween.TRANS_SINE)
    @warning_ignore_restore("return_value_discarded")

    tween.play()

func _execute_next_effect() -> void:
    var card: BattleCard = _slots.slotted_cards[_active_card_index]
    if card == null:
        push_warning("We should probably be halted %s, slot idx %s doesn't have a card" % [_halted, _active_card_index])

        on_after_execute_card.emit()

        _active_card_index += 1
        _execute_next_card()
        return

    if _active_card_effect_index >= card.data.primary_effects.size():
        _restore_card_size()

        on_after_execute_card.emit()

        _active_card_index += 1
        _execute_next_card()
        return

    var effect: BattleCardPrimaryEffect = card.data.primary_effects[_active_card_effect_index]

    var targets_range: Array[int] = effect.get_target_range()
    var n_targets: int = randi_range(targets_range[0], targets_range[1])

    _active_effect = effect
    if effect.targets_allies() && effect.targets_enemies():
        _possible_effect_targets = _enemies + _allies
    elif effect.targets_enemies():
        _possible_effect_targets = _enemies
    elif effect.targets_allies():
        _possible_effect_targets = _allies
    elif effect.targets_self():
        _possible_effect_targets = [self]
    else:
        push_warning("Card %s's effect %s has no effect" % [card.name, effect])
        _active_card_effect_index += 1
        _execute_next_effect()
        return

    _execute_effect(n_targets)

func _execute_effect(n_targets: int) -> void:
    _effect_target_type = _active_effect.target_type()
    print_debug("Target type is %s" % _effect_target_type)

    var rng_target: bool = _active_effect.targets_random()
    var target_order: Array[int] = ArrayUtils.int_range(_possible_effect_targets.size())
    target_order.shuffle()
    _effect_targets_count = mini(n_targets, _possible_effect_targets.size())

    _effect_mode = _active_effect.mode
    _effect_targets.clear()

    var automatic: bool = _effect_targets_count >= _possible_effect_targets.size() || rng_target
    if automatic:
        for i: int in range(_effect_targets_count):
            var target: BattleEntity = _possible_effect_targets[target_order[i]]
            _effect_targets.append(target)

        await get_tree().create_timer(0.5).timeout

        _execute_effect_on_targets()
        return

    # Someone else does the selection handling and calls add_target
    on_player_select_targets.emit(self, n_targets, _possible_effect_targets, _effect_mode, _effect_target_type)

var _effect_targets_count: int
var _active_effect: BattleCardPrimaryEffect
var _effect_targets: Array[BattleEntity]
var _possible_effect_targets: Array[BattleEntity]
var _effect_mode: BattleCardPrimaryEffect.EffectMode
var _effect_target_type: BattleCardPrimaryEffect.EffectTarget

func add_target(target: BattleEntity) -> bool:
    var n_targets: int = _effect_targets.size()
    if n_targets > _effect_targets_count:
        return false

    if _effect_targets.has(target):
        _effect_targets.erase(target)
    else:
        _effect_targets.append(target)

    n_targets = _effect_targets.size()

    if n_targets == _effect_targets_count:
        on_player_select_targets_complete.emit()
        _execute_effect_on_targets.call_deferred()
    else:
        on_player_select_targets.emit(self, _effect_targets_count - n_targets, _possible_effect_targets, _effect_mode, _effect_target_type)
    return true

func _execute_effect_on_targets() -> void:
    var battle: BattleMode = BattleMode.find_battle_parent(self)
    var suit_bonus: int = 0 if battle == null else battle.suit_bonus
    var rank_bonus: int = 0 if battle == null else battle.rank_bonus

    for target: BattleEntity in _effect_targets:
        on_before_execute_effect_on_target.emit(target)

        var effect_magnitude: int = _active_effect.calculate_effect(suit_bonus + rank_bonus, _allies.has(target))
        print_debug("Doing %s %s to %s" % [effect_magnitude, BattleCardPrimaryEffect.humanize(_effect_mode), target.name])

        match _effect_mode:
            BattleCardPrimaryEffect.EffectMode.Damage:
                await target.hurt(effect_magnitude)
                if !target.is_alive():
                    if _allies.has(target):
                        _allies.erase(target)
                    if _enemies.has(target):
                        _enemies.erase(target)

            BattleCardPrimaryEffect.EffectMode.Heal:
                target.heal(effect_magnitude)
            BattleCardPrimaryEffect.EffectMode.Defence:
                target.add_shield(effect_magnitude)

        await get_tree().create_timer(0.25).timeout

        on_after_execute_effect_on_target.emit(target)

    _active_card_effect_index += 1
    _execute_next_effect()

var _robot: Robot

func use_robot(robot: Robot) -> void:
    _robot = robot

    if _robot != null && _robot.model != null:
        max_health = _robot.model.max_hp
    else:
        max_health = 0

    validate_health()


func get_entity_name() -> String:
    return tr("NO_ROBOT_NAME") if _robot == null else _robot.given_name

func clean_up_round() -> void:
    _restore_card_size()
    _allies = []
    _enemies = []
    _active_card_index = 0
    _active_card_effect_index = 0
    print_debug("Player end round cleaned")

func clean_up_battle() -> void:
    super.clean_up_battle()
    var card: BattleCardData = _robot.remove_one_punishment_card()
    if card != null:
        NotificationsManager.important(tr("NOTICE_INSPIRATION"), tr("LOST_PUNISHMENT").format({"card": card.localized_name()}))
        PunishmentDeck.instance.return_card(card)

func collect_save_data() -> Dictionary:
    var data: Dictionary = super.collect_save_data()
    data.merge({
        _ID_KEY: character_id,
    }, true)
    return data

func load_from_save(data: Dictionary) -> void:
    if data.has(_ID_KEY) && data[_ID_KEY] != character_id:
        push_error("Attmpted to load %s onto %s" % [data[_ID_KEY], character_id])
        return

    _health = maxi(0, DictionaryUtils.safe_geti(data, _HEALTH_KEY, max_health))
