extends Node
class_name BattleMode

@export
var animator: AnimationPlayer

@export
var battle_hand: BattleHandManager

@export
var player_deck: BattleDeck

@export
var _active_cards: Control

var trigger: GridEncounterEffect

var suit_crit_bonus: int = 0
var rank_crit_bonus: int = 0

const _battle_card_resource: PackedScene = preload("res://scenes/battle_card.tscn")
var _cards: Array[BattleCard] = []

func _ready() -> void:
    if battle_hand.on_hand_drawn.connect(after_deal) != OK:
        push_error("Failed to connect callback to hand dealt")
    if battle_hand.slots.on_update_slotted.connect(handle_update_slotted):
        push_error("Failed to connect callback to slotted cards updated")

func handle_update_slotted(cards: Array[BattleCard]) -> void:
    var acc_suit_bonus: int
    var prev_card: BattleCardData = null

    var slotted_cards: Array[BattleCard]
    slotted_cards.append_array(cards)
    ArrayUtils.erase_all_occurances(slotted_cards, null)

    var idx: int = 0

    for card: BattleCard in slotted_cards:
        idx += 1

        var suited_rule: bool = false
        if card.data.secondary_effects.has(BattleCardData.SecondaryEffect.Accelerated):
            if card.data.has_identical_suit(prev_card):
                acc_suit_bonus = max(acc_suit_bonus + 1, acc_suit_bonus * 2)
            else:
                acc_suit_bonus = -1
            suited_rule = true

        if card.data.secondary_effects.has(BattleCardData.SecondaryEffect.SuitedUp):
            var next_card: BattleCard = slotted_cards[idx + 1] if idx + 1 < slotted_cards.size() else null
            if card.data.has_suit_intersection(prev_card) && next_card != null && card.data.has_suit_intersection(next_card.data):
                acc_suit_bonus += 1
            else:
                acc_suit_bonus = 0
            suited_rule = true

        if !suited_rule && idx > 0:
            if card.data.has_suit_intersection(prev_card):
                acc_suit_bonus += 1
            else:
                acc_suit_bonus = 0

        card.sync_display(acc_suit_bonus)

        prev_card = card.data

func enter_battle(battle_trigger: GridEncounterEffect) -> void:
    trigger = battle_trigger

    await get_tree().create_timer(0.5).timeout

    animator.play("fade_in_battle")

    await get_tree().create_timer(1.0).timeout

    if trigger.hide_encounter_on_trigger:
        trigger.encounter.visible = false

    # Show F I G H T
    await get_tree().create_timer(1.0).timeout

    deal_hand()

func deal_hand() -> void:
    # TODO: Ask someone what the cards should actually be
    var hand_size: int = 6
    var hand: Array[BattleCard] = []

    var card_data: Array[BattleCardData] = player_deck.draw(hand_size)

    var idx: int = 0
    for card: BattleCard in _cards:
        if idx >= _cards.size():
            break

        _cards[idx].data = card_data[idx]
        hand.append(_cards[idx])

    while idx < hand_size:
        var new_card: BattleCard = _battle_card_resource.instantiate()
        new_card.visible = false
        new_card.data = card_data[idx]

        _active_cards.add_child(new_card)
        new_card.owner = _active_cards.get_tree().root

        _cards.append(new_card)
        hand.append(new_card)
        idx += 1

    battle_hand.draw_hand(hand)

func after_deal() -> void:
    battle_hand.slots.show_slots(3)

func exit_battle() -> void:
    battle_hand.hide_hand()

    animator.play("fade_out_battle")
    await get_tree().create_timer(0.5).timeout
    trigger.complete()
