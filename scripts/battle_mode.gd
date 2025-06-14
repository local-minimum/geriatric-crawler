extends Node
class_name BattleMode

@export
var animator: AnimationPlayer

@export
var battle_hand: BattleHandManager

@export
var _active_cards: Control

var trigger: GridEncounterEffect

const _battle_card_resource: PackedScene = preload("res://scenes/battle_card.tscn")
var _cards: Array[BattleCard] = []

func _ready() -> void:
    if battle_hand.on_hand_drawn.connect(after_deal) != OK:
        push_error("Failed to connect callback to hand dealt")

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

    var idx: int = 0
    for card: BattleCard in _cards:
        if idx >= _cards.size():
            break

        hand.append(_cards[0])

    while idx < hand_size:
        var new_card: BattleCard = _battle_card_resource.instantiate()
        new_card.visible = false
        new_card.name = "Card %s" % idx

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
