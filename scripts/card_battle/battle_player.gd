extends BattleEntity
class_name BattlePlayer

@export
var _slots: BattleCardSlots


func play_actions(
    allies: Array[BattleEntity],
    enemies: Array[BattleEntity],
) -> void:
    on_start_turn.emit(self)
    print_debug("Start player turn")

    _slots.show_slotted_cards()
    await get_tree().create_timer(0.5).timeout

    _allies = allies
    _enemies = enemies

    _execute_next_card()

var _allies: Array[BattleEntity]
var _enemies: Array[BattleEntity]
var _active_card_index: int
var _active_card_effect_index: int
var _previous_card: BattleCard = null
var _suit_bonus: int

func _execute_next_card() -> void:
    if _active_card_index >= _slots.slotted_cards.size():
        on_end_turn.emit(self)
        return

    var card: BattleCard = _slots.slotted_cards[_active_card_index]
    if card == null:
        on_end_turn.emit(self)
        return

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
    _suit_bonus = get_suit_bonus(
        card.data,
        _suit_bonus,
        _previous_card.data if _previous_card != null else null,
        next.data if next != null else null,
        _active_card_index == 0,
    )

    _active_card_effect_index = 0

    _execute_next_effect()

    _previous_card = card

func _execute_next_effect() -> void:
    var card: BattleCard = _slots.slotted_cards[_active_card_index]

    if _active_card_effect_index >= card.data.primary_effects.size():
        _active_card_index += 1

        var tween: Tween = get_tree().create_tween()
        @warning_ignore_start("return_value_discarded")
        tween.tween_property(
            card,
            "scale",
            Vector2.ONE,
            0.2).set_trans(Tween.TRANS_SINE)
        @warning_ignore_restore("return_value_discarded")

        tween.play()

        _execute_next_card()
        return

    var effect: BattleCardPrimaryEffect = card.data.primary_effects[_active_card_effect_index]

    var targets_range: Array[int] = effect.get_target_range()
    var n_targets: int = randi_range(targets_range[0], targets_range[1])
    var had_effect: bool = false

    if effect.targets_enemies():
        _execute_effect(effect, _suit_bonus, _enemies, n_targets, false)
        had_effect = true

    if effect.targets_allies():
        _execute_effect(effect, _suit_bonus, _allies , n_targets, true)
        had_effect = true
    elif effect.targets_self():
        _execute_effect(effect, _suit_bonus, [self], n_targets, true)
        had_effect = true

    if !had_effect:
        push_warning("Card %s's effect %s has no effect" % [card.name, effect])

func _execute_effect(
    effect: BattleCardPrimaryEffect,
    suit_bonus: int,
    targets: Array[BattleEntity],
    n_targets: int,
    allies: bool,
) -> void:
    var value: int = effect.calculate_effect(suit_bonus, allies)

    # TODO: Allow player to select targets
    var rng_target: bool = effect.targets_random()
    var target_order: Array[int] = ArrayUtils.int_range(targets.size())
    target_order.shuffle()
    n_targets = mini(n_targets, targets.size())

    await get_tree().create_timer(0.5).timeout

    if n_targets >= targets.size() || rng_target:
        for i: int in range(n_targets):
            var target: BattleEntity = targets[target_order[i]]

            print_debug("Doing %s %s to %s" % [value, effect.mode_name(), target.name])

            match effect.mode:
                BattleCardPrimaryEffect.EffectMode.Damage:
                    target.hurt(value)
                BattleCardPrimaryEffect.EffectMode.Heal:
                    target.heal(value)
                BattleCardPrimaryEffect.EffectMode.Defence:
                    target.add_shield(value)

            await get_tree().create_timer(0.25).timeout

    _active_card_effect_index += 1
    _execute_next_effect()

func get_entity_name() -> String:
    return "Simon Cyberdeck"
