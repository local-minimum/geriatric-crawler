extends BattleEntity
class_name BattleEnemy

## This should be a unique ID within each battle mode trigger / group of enemies
@export var id: String = "first"

## This is the variant ID of the enemy character in the blob, e.g. "space-slug". It shouldn't be unique. But if there are variants like "space-slug-lvl2" it should be named as such
@export var variant_id: String

## Human readable / display name
@export var variant_name: String

@export var level: int

@export var difficulty: int = 0

@export var max_health: int = 20

@export var carried_credits: int = 0

@export var hand_size: int = 3

@export var play_slots: int = 1

@export var deck: EnemyBattleDeck

@export var brain: BattleBrain

@export var _target_system: BattleEnemyTargetSystem

@export var _rank_bonus_step_size: int = 1

@export var _suit_bonus_step_size: int = 0

@export var _suit_bonus_on_descending: bool

var _hand: Array[BattleCardData]
var _slotted: Array[BattleCardData]

func ready_for_battle() -> void:
    _health = max_health

#region HEALTH
var _health: int = -1:
    set (value):
        print_debug("%s health %s -> %s" % [name, _health, value])
        _health = value

func get_health() -> int:
    return _health

func get_max_health() -> int:
    return max_health

func get_healthiness() -> float:
    return _health as float / max_health

func validate_health() -> void:
    if _health < 0:
        _health = max_health
        __SignalBus.on_heal.emit(self, 0, _health, false)

    if _health > max_health:
        _health = max_health
        __SignalBus.on_heal.emit(self, 0, _health, false)

func is_alive() -> bool:
    return _health > 0

func _hurt(amount: int) -> void:
    _health = max(0, _health - amount)
    __SignalBus.on_hurt.emit(self, amount, _health)

    if _health == 0:
        __SignalBus.on_death.emit(self)

func _heal(amount: int) -> void:
    var raw_new: int = _health + amount
    var overshoot: bool = raw_new > max_health
    _health = min(raw_new, max_health)

    __SignalBus.on_heal.emit(self, amount - (raw_new - _health), _health, overshoot)
#endregion HEALTH

func get_entity_name() -> String:
    return variant_name

func initiative() -> int:
    if _slotted.is_empty():
        return -1

    return _slotted[0].rank

func passing() -> bool:
    return _slotted.is_empty()

## Draws cards and asks a strategy to slot them
func prepare_hand() -> void:
    var draw_cards: int = hand_size - _hand.size()
    _hand.append_array(deck.draw(draw_cards))
    _slotted = brain.select_cards(_hand, play_slots)

    for card: BattleCardData in _slotted:
        _hand.erase(card)

    __SignalBus.on_prepare_enemy_hand.emit(self, _slotted)

func play_actions(
    allies: Array[BattleEntity],
    enemies: Array[BattleEntity],
    __hand: Array[BattleCardData] = [],
) -> void:
    _halted = false
    var previous: BattleCardData = null
    var idx: int = 0
    var suit_bonuses: Array[int]
    var rank_bonuses: Array[int]
    var suit_bonus: int = 0
    var rank_bonus: int = 0
    var rank_direction: int
    var card_pause: float = 2

    ArrayUtils.shift_nulls_to_end(_slotted)

    print_debug("%s starts its turn with %s cards" % [name, _slotted.size() - _slotted.count(null)])

    __SignalBus.on_start_turn.emit(self)

    await get_tree().create_timer(0.3).timeout
    for card_idx: int in range(_slotted.size()):
        var card: BattleCardData = _slotted[card_idx]

        var next: BattleCardData = _slotted[idx + 1] if idx < _slotted.size() - 1 else null

        suit_bonuses.append(get_suit_bonus(card, suit_bonus, _suit_bonus_step_size, previous, next, idx == 0, _hand))
        rank_bonuses.append(get_rank_bonus(card, rank_bonus, _rank_bonus_step_size, previous, rank_direction, next, idx == 0, _suit_bonus_on_descending, _hand))

        __SignalBus.on_show_enemy_card.emit(self, card_idx, card, suit_bonus, rank_bonus)

        await get_tree().create_timer(0.1).timeout

    await get_tree().create_timer(0.5).timeout

    for card_idx: int in range(_slotted.size()):
        if _halted:
            break

        var card: BattleCardData = _slotted[card_idx]

        if card == null:
            continue

        suit_bonus = suit_bonuses[card_idx]
        rank_bonus = rank_bonuses[card_idx]

        print_debug("%s playes card %s with %s effects" % [name, card.name, card.primary_effects.size()])

        if previous != null:
            rank_direction = signi(card.rank - previous.rank)

        __SignalBus.on_play_enemy_card.emit(self, card_idx)

        await get_tree().create_timer(card_pause * 0.3).timeout

        for effect: BattleCardPrimaryEffect in card.primary_effects:
            if _halted:
                continue

            var targets_range: Array[int] = effect.get_target_range()
            var n_targets: int = randi_range(targets_range[0], targets_range[1])
            var had_effect: bool = false

            if effect.targets_enemies() && effect.targets_allies():
                await _execute_effect(card, effect, suit_bonus + rank_bonus, enemies + allies, n_targets, allies)
                had_effect = true
            elif effect.targets_enemies():
                await _execute_effect(card, effect, suit_bonus + rank_bonus, enemies, n_targets, allies)
                had_effect = true
            elif effect.targets_allies():
                await _execute_effect(card, effect, suit_bonus + rank_bonus, allies , n_targets, allies)
                had_effect = true
            elif effect.targets_self():
                await _execute_effect(card, effect, suit_bonus + rank_bonus, [self], n_targets, allies)
                had_effect = true

            if !had_effect:
                push_warning("Card %s's effect %s has no effect" % [card.name, effect])

            enemies = enemies.filter(func (e: BattleEntity) -> bool: return e.is_alive())
            allies = allies.filter(func (e: BattleEntity) -> bool: return e.is_alive())

        idx += 1
        previous = card

        await get_tree().create_timer(card_pause * 0.7).timeout
        __SignalBus.on_hide_enemy_card.emit(self, card_idx)

    print_debug("%s ends its turn" % name)

    __SignalBus.on_end_turn.emit(self)

func _execute_effect(
    card: BattleCardData,
    effect: BattleCardPrimaryEffect,
    bonus: int,
    targets: Array[BattleEntity],
    n_targets: int,
    allies: Array[BattleEntity],
) -> void:
    var target_order: Array[int] = []
    if effect.targets_random():
        target_order = ArrayUtils.int_range(targets.size())
        target_order.shuffle()
    else:
        target_order = _target_system.get_target_order(effect, bonus, targets, n_targets, allies)

    n_targets = mini(n_targets, targets.size())
    for i: int in range(n_targets):
        var target: BattleEntity = targets[target_order[i]]

        var value: int = effect.calculate_effect(bonus, allies.has(target))

        print_debug("[Battle Enemy] %s doing %s %s to %s" % [card.id, value, effect.mode_name(), target.name])

        match effect.mode:
            BattleCardPrimaryEffect.EffectMode.Damage:
                target.hurt(value)
            BattleCardPrimaryEffect.EffectMode.Heal:
                target.heal(value)
            BattleCardPrimaryEffect.EffectMode.Defence:
                target.add_shield(value)

        await get_tree().create_timer(0.25).timeout

        if _halted:
            return

func clean_up_battle() -> void:
    super.clean_up_battle()
    _health = max_health

    var gained_cards: Array[String] = deck.get_gained_card_ids()
    deck.restore_start_deck()

    for card_id: String in gained_cards:
        PunishmentDeck.instance.return_card_id(card_id)
