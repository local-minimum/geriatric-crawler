extends Node
class_name BattleStrategy

@export
var priority: int = 1

func applicable(_hand: Array[BattleCardData], _max_cards: int) -> bool:
    return true

func select_cards(hand: Array[BattleCardData], max_cards: int) -> Array[BattleCardData]:
    var hand_size: int = hand.size()
    if hand_size == 0 || max_cards == 0:
        return []

    return [hand[randi_range(0, hand_size - 1)]]
