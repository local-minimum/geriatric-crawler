extends BattleEntity
class_name BattleEnemy

signal on_prepare_hand(battle_enemy: BattleEnemy, slotted_cards: Array[BattleCard])
signal on_start_turn(battle_enemy: BattleEnemy)
signal on_play_card(card: BattleCardData, suit_bonus: int, pause: float)


## This is the variant ID of the enemy character in the blob, e.g. "space-slug". It shouldn't be unique. But if there are variants like "space-slug-lvl2" it should be named as such
@export
var variant_id: String

## Human readable / display name
@export
var variant_name: String

@export
var level: int

@export
var difficulty: int = 0

@export
var hand_size: int = 3

@export
var play_slots: int = 1

@export
var deck: BattleDeck

@export
var brain: BattleBrain

var _hand: Array[BattleCardData]
var _slotted: Array[BattleCardData]

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

    on_prepare_hand.emit(self, _slotted)

func play_actions(
    allies: Array[BattleEntity],
    enemies: Array[BattleEntity],
) -> void:
    var previous: BattleCardData = null
    var idx: int = 0
    var suit_bonus: int
    var card_pause: float = 3

    ArrayUtils.shift_nulls_to_end(_slotted)

    print_debug("%s starts its turn with %s cards" % [name, _slotted.size() - _slotted.count(null)])

    on_start_turn.emit(self)

    await get_tree().create_timer(1).timeout

    for card: BattleCardData in _slotted:
        if card == null:
            break

        print_debug("%s playes card %s with %s effects" % [name, card.name, card.primary_effects.size()])

        var next: BattleCardData = _slotted[idx + 1] if idx < _slotted.size() - 1 else null

        suit_bonus = get_suit_bonus(card, suit_bonus, previous, next, idx == 0)

        on_play_card.emit(card, suit_bonus, card_pause)

        await get_tree().create_timer(card_pause).timeout

        for effect: BattleCardPrimaryEffect in card.primary_effects:
            var targets_range: Array[int] = effect.get_target_range()
            var n_targets: int = randi_range(targets_range[0], targets_range[1])
            var had_effect: bool = false

            if effect.targets_enemies():
                _execute_effect(effect, suit_bonus, enemies, n_targets, false)
                had_effect = true

            if effect.targets_allies():
                _execute_effect(effect, suit_bonus, allies , n_targets, true)
                had_effect = true
            elif effect.targets_self():
                _execute_effect(effect, suit_bonus, [self], n_targets, true)
                had_effect = true

            if !had_effect:
                push_warning("Card %s's effect %s has no effect" % [card.name, effect])

        idx += 1
        previous = card

    print_debug("%s ends its turn" % name)

    on_turn_done.emit()

func _execute_effect(
    effect: BattleCardPrimaryEffect,
    suit_bonus: int,
    targets: Array[BattleEntity],
    n_targets: int,
    allies: bool,
) -> void:
    var value: int = effect.calculate_effect(suit_bonus, allies)

    # TODO: Strategic targets
    var _rng_target: bool = effect.targets_random()
    var target_order: Array[int] = ArrayUtils.int_range(targets.size())
    target_order.shuffle()

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
