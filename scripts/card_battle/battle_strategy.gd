extends Node
class_name BattleStrategy

@export
var priority: int = 1

func applicable(_hand: Array[BattleCard], _max_cards: int) -> bool:
    return true

func select_cards(hand: Array[BattleCard], max_cards: int) -> Array[BattleCard]:
    var hand_size: int = hand.size()
    if hand_size == 0 || max_cards == 0:
        return []

    return [hand[randi_range(0, hand_size - 1)]]
