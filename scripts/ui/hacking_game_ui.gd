extends CanvasLayer
class_name HackingGameUI

@export
var _game: HackingGame

func _ready() -> void:
    visible = false

    if _game.on_change_attempts.connect(_handle_attempts_updated) != OK:
        push_error("Could not connect to attempts updated")

func _handle_attempts_updated(_attempts: int) -> void:
    pass
