extends BattleDeck
class_name EnemyBattleDeck

@export
var _start_deck: Array[BattleCardData]

var _gained_cards: Array[BattleCardData]

func _ready() -> void:
    if _draw_pile.is_empty() && _active_hand.is_empty() && _discard_pile.is_empty():
        _draw_pile.append_array(_start_deck)
        shuffle()

func restore_start_deck() -> void:
    _draw_pile.clear()
    _active_hand.clear()
    _discard_pile.clear()
    _draw_pile.append_array(_start_deck)
    shuffle()

func gain_card(card: BattleCardData) -> void:
    _gained_cards.append(card)
    _draw_pile.append(card)
    _draw_pile.shuffle()

    on_shuffle.emit(_draw_pile)
    on_updated_piles.emit(_draw_pile, _active_hand, _discard_pile)

func get_gained_card_ids() -> Array[String]:
    if _gained_cards.is_empty():
        return []

    var ids: Array[String] = []
    for card: BattleCardData in _gained_cards:
        ids.append(card.id)

    return ids

func loose_card(card: BattleCardData) -> void:
    if _draw_pile.has(card):
        _draw_pile.erase(card)
    elif _discard_pile.has(card):
        _discard_pile.erase(card)
    elif _active_hand.has(card):
        _active_hand.erase(card)
    else:
        push_error("Enemy deck %s doesn't have card %s" % [self, card.id])
        return

    on_updated_piles.emit(_draw_pile, _active_hand, _discard_pile)
