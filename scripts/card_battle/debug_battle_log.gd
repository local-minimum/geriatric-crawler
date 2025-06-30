extends Label

@export
var _hand: BattleHandManager

@export
var _show_messages: int = 10

func _ready() -> void:
    if _hand.on_hand_debug.connect(_add_message) != OK:
        push_error("Failed to connect on _hand debug")

    _sync()

var _messages: Array[String]

func _add_message(msg: String) -> void:
    _messages.append(msg)
    _sync()

func _sync() -> void:
    text = "\n".join(_messages.slice(maxi(0, _messages.size() - _show_messages - 1)))
