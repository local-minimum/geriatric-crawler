extends Node
class_name PunishmentDeck

@export var _deck: Array[BattleCardData]

var _given_out_cards: Array[BattleCardData] = []

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

func collect_save_data() -> Array[String]:
    var ids: Array[String]
    for card: BattleCardData in _given_out_cards:
        ids.append(card.id)

    return ids

func load_from_save(save: Array) -> void:
    for card_id: Variant in save:
        if card_id is String:
            var card_idx: int = _deck.find_custom(func (card: BattleCardData) -> bool: return card.id == card_id)
            if card_idx >= 0:
                var card: BattleCardData = _deck[card_idx]
                if _given_out_cards.has(card):
                    push_warning("Card id %s has been given out twice, this shouldn't be possible. Ignoring" % card_id)
                else:
                    _given_out_cards.append(card)
            else:
                push_warning("Card id %s not in %s. Ignored" % [card_id, _deck.map(func (c: BattleCardData) -> String: return c.id)])
        else:
            push_warning("Expected save items to be strings but got %s" % card_id)
