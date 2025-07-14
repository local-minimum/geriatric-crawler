extends BattleDeck
class_name EnemyBattleDeck

@export
var _start_deck: Array[BattleCardData]

func _ready() -> void:
    if _draw_pile.is_empty() && _active_hand.is_empty() && _discard_pile.is_empty():
        _draw_pile.append_array(_start_deck)
        shuffle()
