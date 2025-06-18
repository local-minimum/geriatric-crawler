extends Node
class_name BattleBrain

@export
var strategies: Array[BattleStrategy]

func select_cards(hand: Array[BattleCardData], max_cards: int) -> Array[BattleCardData]:
    var available: Dictionary[BattleStrategy, int] = {}
    var total_prio: int = 0

    for strategy: BattleStrategy in strategies:
        if strategy.applicable(hand, max_cards):
            var prio: int = strategy.priority
            available[strategy] = prio
            total_prio += prio

    if total_prio == 0:
        return []

    var target: int = randi_range(0, total_prio - 1)

    for strategy: BattleStrategy in available.keys():
        var prio: int = available[strategy]
        if target <= prio:
            return strategy.select_cards(hand, max_cards)
        target -= prio

    push_error("Priority corruption, this code should not be reachable, %s vs %s vs %s" % [strategies, total_prio, target])
    return []
