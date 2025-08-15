extends Node
class_name PunishmentDeck

@export var _deck: Array[BattleCardData]

var _given_out_cards: Array[BattleCardData] = []

# TODO: Save/Track cards that are out in play from gridded level
# TODO: Get back cards when entities dies

func get_random_card() -> BattleCardData:
    var _remaining: Array[BattleCardData] = _deck.filter(func (card: BattleCardData) -> bool: return !_given_out_cards.has(card))
    if _remaining.is_empty():
        return null

    var selected: BattleCardData = _remaining[randi_range(0, _remaining.size() - 1)]
    _given_out_cards.append(selected)


    return selected

func return_card(card: BattleCardData) -> void:
    _given_out_cards.erase(card)
