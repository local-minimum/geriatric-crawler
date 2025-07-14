extends Node
class_name BattleDeck

signal on_shuffle(draw: Array[BattleCardData])
signal on_updated_piles(draw: Array[BattleCardData], hand: Array[BattleCardData], discard: Array[BattleCardData])

var _draw_pile: Array[BattleCardData] = []
var _active_hand: Array[BattleCardData] = []
var _discard_pile: Array[BattleCardData] = []

func load_deck(deck: Array[BattleCardData]) -> void:
    _draw_pile.clear()
    _discard_pile.clear()
    _active_hand.clear()
    _draw_pile.append_array(deck)
    shuffle()

func shuffle(include_hand: bool = false) -> void:
    if include_hand:
        _draw_pile.append_array(_active_hand)
        _active_hand.clear()

    _draw_pile.append_array(_discard_pile)
    _discard_pile.clear()

    _draw_pile.shuffle()

    on_shuffle.emit(_draw_pile)
    on_updated_piles.emit(_draw_pile, _active_hand, _discard_pile)

func draw(n_cards: int) -> Array[BattleCardData]:
    var cards: Array[BattleCardData]
    var no_more_cards: bool

    while cards.size() < n_cards:
        var card: BattleCardData = _draw_pile.pop_front()
        if card == null:
            # Panic exit if there are actually not enough cards around
            if no_more_cards:
                break
            shuffle()
            no_more_cards = true
        else:
            cards.append(card)
            no_more_cards = false

    _active_hand.append_array(cards)
    on_updated_piles.emit(_draw_pile, _active_hand, _discard_pile)

    return cards

func discard_from_hand(cards: Array[BattleCardData]) -> void:
    for card: BattleCardData in cards:
        if card == null:
            continue

        if _active_hand.has(card):
            _active_hand.erase(card)
            _discard_pile.append(card)
        else:
            push_error("%s is not in hand %s" % [card, _active_hand])

    on_updated_piles.emit(_draw_pile, _active_hand, _discard_pile)

func discard_hand() -> void:
    discard_from_hand(_active_hand)

func get_card(id: String) -> BattleCardData:
    for card: BattleCardData in _draw_pile:
        if card.id == id:
            return card

    for card: BattleCardData in _active_hand:
        if card.id == id:
            return card

    for card: BattleCardData in _discard_pile:
        if card.id == id:
            return card

    push_error("No '%s' card in deck" % id)
    return null
