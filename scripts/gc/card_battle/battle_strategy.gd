extends Node
class_name BattleStrategy

@export var priority: int = 1

func applicable(_hand: Array[BattleCardData], _max_cards: int) -> bool:
    return true

func select_cards(hand: Array[BattleCardData], max_cards: int) -> Array[BattleCardData]:
    var hand_size: int = hand.size()
    if hand_size == 0 || max_cards == 0:
        return []

    var indicies: Array[int] = ArrayUtils.int_range(hand_size)
    ArrayUtils.shuffle_array(indicies)

    var cards: Array[BattleCardData]
    for idx: int in indicies.slice(0, mini(hand_size, max_cards)):
        cards.append(hand[idx])

    return cards
