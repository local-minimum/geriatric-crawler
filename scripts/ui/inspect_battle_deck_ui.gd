extends Control
class_name InspectBattleDeckUI

@export var cards_root: Control

const _inspect_card_resource: PackedScene = preload("res://scenes/ui/inspect_card_ui.tscn")

var _prev_cards: Array[Control]

func list_cards(all_cards: Array[BattleCardData]) -> void:
    var cards: Dictionary[BattleCardData, int] = _count_cards(all_cards)

    for prev_card: Control in _prev_cards:
        prev_card.queue_free()
    _prev_cards.clear()

    var keys: Array[BattleCardData] = cards.keys()
    keys.sort_custom(
        func (a: BattleCardData, b: BattleCardData) -> bool:
            return a.name <= b.name && a.rank <= b.rank
    )

    for data: BattleCardData in keys:
        var card: InspectBattleCardUI = _inspect_card_resource.instantiate()
        card.sync(data, cards[data])

        _prev_cards.append(card)
        cards_root.add_child(card)

func _count_cards(all_cards: Array[BattleCardData]) -> Dictionary[BattleCardData, int]:
    var counts: Dictionary[String, int] = {}
    var data_lookup: Dictionary[String, BattleCardData] = {}

    for card: BattleCardData in all_cards:
        if counts.has(card.id):
            counts[card.id] += 1
        else:
            counts[card.id] = 1
            data_lookup[card.id] = card

    var result: Dictionary[BattleCardData, int] = {}
    for id: String in counts:
        result[data_lookup[id]] = counts[id]

    return result
