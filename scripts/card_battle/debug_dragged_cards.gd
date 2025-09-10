extends Label

func _ready() -> void:
    if __SignalBus.on_player_hand_drawn.connect(_sync) != OK:
        push_error("Couldn't connect to hand drawn")

    if __SignalBus.on_card_drag_start.connect(_add_dragged_card) != OK:
        push_error("Failed to connect to on drag start")
    if __SignalBus.on_card_drag_end.connect(_remove_dragged_card) != OK:
        push_error("Failed to connect to on drag end")
    if __SignalBus.on_card_hover_start.connect(_add_hovered_card) != OK:
        push_error("Failed to connect to on hover start")
    if __SignalBus.on_card_hover_end.connect(_remove_hovered_card) != OK:
        push_error("Failed to connect to on hover end")

var _dragged: Array[BattleCard] = []

func _add_dragged_card(card: BattleCard) -> void:
    _dragged.append(card)
    _sync()

func _remove_dragged_card(card: BattleCard) -> void:
    _dragged.erase(card)
    _sync()

var _hovered: Array[BattleCard] = []

func _add_hovered_card(card: BattleCard) -> void:
    _hovered.append(card)
    _sync()

func _remove_hovered_card(card: BattleCard) -> void:
    _hovered.erase(card)
    _sync()

func _sync() -> void:
    var dragged: String = " | ".join(_dragged.map(func (card: BattleCard) -> String: return card.data.id if card.data != null else "-EMPTY CARD-"))
    var hovered: String = " | ".join(_hovered.map(func (card: BattleCard) -> String: return card.data.id if card.data != null else "-EMPTY CARD-"))
    text = "%s  ===  %s" % [dragged, hovered]
