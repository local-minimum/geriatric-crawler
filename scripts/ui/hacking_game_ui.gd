extends CanvasLayer
class_name HackingGameUI

@export
var _game: HackingGame

@export
var _attempts_label: Label

@export
var _attempt_button: Button

@export
var outer_spacer_color: Color

@export
var inner_spacer_color: Color

@export
var tex_up: Texture

@export
var tex_down: Texture

@export
var tex_left: Texture

@export
var tex_right: Texture

@export
var _playing_field_outer_container: AspectRatioContainer

@export
var _playing_field_container: GridContainer

@export
var destroyed_text_color: Color

@export
var default_text_color: Color

@export
var discoverd_text_color: Color

@export
var discoverd_not_text_color: Color

@export
var word_bg_tex_default: Texture

@export
var word_bg_tex_destroyed: Texture

@export
var word_bg_tex_correct: Texture

@export
var word_bg_tex_wrong_place: Texture

func _ready() -> void:
    hide()

    if _game.on_change_attempts.connect(_handle_attempts_updated) != OK:
        push_error("Could not connect to attempts updated")

func _handle_attempts_updated(_attempts: int) -> void:
    _attempts_label.text = "%02d" % _attempts
    _attempt_button.disabled = _attempts <= 0

var _field_labels: Dictionary[Vector2i, Label]
var _field_backgrounds: Dictionary[Vector2i, TextureRect]

func show_game() -> void:
    # Actual columns, one empty column inbetween each and then shifting buttons at the edges
    var columns: int = _game.width + _game.width - 1 + 2
    var rows: int = _game.height +  _game.height - 1 + 2

    _playing_field_outer_container.ratio = columns as float / rows as float
    _playing_field_container.columns = columns

    for child_idx: int in range(_playing_field_container.get_child_count()):
        _playing_field_container.get_child(child_idx).queue_free()

    _field_labels.clear()
    _field_backgrounds.clear()

    var btn: Button

    for full_col: int in range(columns):
        if posmod(full_col, 2) == 0:
            _playing_field_container.add_child(_get_spacer(outer_spacer_color))

        else:
            btn = _get_shift_button("down", tex_down)
            if btn.connect(
                "pressed",
                func () -> void:
                    @warning_ignore_start("integer_division")
                    _game.shift_col((full_col - 1) / 2, 1)
                    @warning_ignore_restore("integer_division")
                    _sync_board()
                    ,
            ) != OK:
                push_error("failed to connect shift down callback")

    for row: int in range(_game.height):

        for col: int in range(_game.width):
            if col == 0:
                btn = _get_shift_button("right", tex_right)
                if btn.connect(
                    "pressed",
                    func () -> void:
                        _game.shift_row(row, 1)
                        _sync_board()
                        ,
                ) != OK:
                    push_error("failed to connect shift right callback")

            else:
                _playing_field_container.add_child(_get_spacer(inner_spacer_color))

            _create_and_add_code_place(row, col)

        btn = _get_shift_button("left", tex_left)
        if btn.connect(
            "pressed",
            func () -> void:
                _game.shift_row(row, -1)
                _sync_board()
                ,
        ) != OK:
            push_error("failed to connect shift left callback")

        if row < _game.height - 1:
            for full_col: int in range(columns):
                _playing_field_container.add_child(_get_spacer(outer_spacer_color if full_col == 0 || full_col == columns - 1 else inner_spacer_color))

    for full_col: int in range(columns):
        if posmod(full_col, 2) == 0:
            _playing_field_container.add_child(_get_spacer(outer_spacer_color))

        else:
            btn = _get_shift_button("up", tex_up)
            if btn.connect(
                "pressed",
                func () -> void:
                    @warning_ignore_start("integer_division")
                    _game.shift_col((full_col - 1) / 2, -1)
                    @warning_ignore_restore("integer_division")
                    _sync_board()
                    ,
            ) != OK:
                push_error("failed to connect shift down callback")

    _sync_board()
    show()

func _create_and_add_code_place(row: int, col: int) -> void:
    var container: Container = _get_shape_container()

    var bg: TextureRect = TextureRect.new()
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

    _size_playing_field_item(bg)
    container.add_child(bg)

    var label: Label = Label.new()
    label.text = _game.get_word(Vector2i(col, row))
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    _size_playing_field_item(label)
    container.add_child(label)

    _playing_field_container.add_child(container)

    var coords: Vector2i = Vector2i(col, row)
    _field_labels[coords] = label
    _field_backgrounds[coords] = bg

func _get_spacer(color: Color) -> Control:
    var container: Container = _get_shape_container()
    var rect: ColorRect = ColorRect.new()
    rect.color = color
    _size_playing_field_item(rect)

    container.add_child(rect)
    return container

func _get_shift_button(direction: String, tex: Texture) -> Button:
    var container: Container = _get_shape_container()
    var btn: Button = Button.new()
    btn.icon = tex
    btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    btn.expand_icon = true
    btn.tooltip_text = "Shift codes %s" % direction
    _size_playing_field_item(btn)

    container.add_child(btn)
    _playing_field_container.add_child(container)
    return btn

func _get_shape_container() -> Control:
    var container: AspectRatioContainer = AspectRatioContainer.new()
    _size_playing_field_item(container)
    container.ratio = 1
    return container

func _size_playing_field_item(control: Control) -> void:
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _sync_board() -> void:
    for coords: Vector2i in _field_labels:
        _field_labels[coords].text = _game.get_word(coords)
        var discovered: bool = _game.is_discovered_present(coords)
        var not_present: bool = _game.is_discovered_not_present(coords)

        var _status: HackingGame.WordStatus = _game.get_word_status(coords)
        match _status:
            HackingGame.WordStatus.DEFAULT:
                _field_backgrounds[coords].texture = word_bg_tex_default
                _field_labels[coords].add_theme_color_override("font_color", _get_word_text_color(discovered, not_present))
            HackingGame.WordStatus.DESTROYED:
                _field_backgrounds[coords].texture = word_bg_tex_destroyed
                _field_labels[coords].add_theme_color_override("font_color", destroyed_text_color)
            HackingGame.WordStatus.WRONG_POSITION:
                _field_backgrounds[coords].texture = word_bg_tex_wrong_place
                _field_labels[coords].add_theme_color_override("font_color",  _get_word_text_color(discovered, not_present))
            HackingGame.WordStatus.CORRECT:
                _field_backgrounds[coords].texture = word_bg_tex_correct
                _field_labels[coords].add_theme_color_override("font_color",  _get_word_text_color(discovered, not_present))


func _get_word_text_color(discovered: bool, not_present: bool) -> Color:
    if discovered:
        return discoverd_text_color
    if not_present:
        return discoverd_not_text_color
    return default_text_color

func _on_hack_button_pressed() -> void:
    # TODO: Add some effect while hacking
    _game.hack()
    _sync_board()
