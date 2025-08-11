extends CanvasLayer
class_name HackingGameUI

@export
var _game: HackingGame

@export
var _attempts_label: Label

@export
var _attempt_button: Button

@export
var _playing_field_outer_container: AspectRatioContainer

var _playing_field_container: GridContainer

func _ready() -> void:
    hide()

    if _game.on_change_attempts.connect(_handle_attempts_updated) != OK:
        push_error("Could not connect to attempts updated")

func _handle_attempts_updated(_attempts: int) -> void:
    _attempts_label.text = "%02d" % _attempts
    _attempt_button.disabled = _attempts <= 0

func show_game() -> void:
    # Actual columns, one empty column inbetween each and then shifting buttons at the edges
    var columns: int = _game.width + _game.width - 1 + 2
    var rows: int = _game.height +  _game.height - 1 + 2

    _playing_field_outer_container.ratio = columns as float / rows as float
    _playing_field_container.columns = columns

    for child_idx: int in range(_playing_field_container.get_child_count()):
        _playing_field_container.get_child(child_idx).queue_free()

    # TODO: Add instances of new children
    show()
