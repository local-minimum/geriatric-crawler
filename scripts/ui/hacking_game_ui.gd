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
var _playing_field_container_lower: GridContainer

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

@export
var attempt_history: Container

@export
var most_recent_attempt: Container

func _ready() -> void:
    hide()

    if _game.on_change_attempts.connect(_handle_attempts_updated) != OK:
        push_error("Could not connect to attempts updated")

    if _game.on_new_attempts.connect(_handle_new_attempts) != OK:
        push_error("Could not connect to new attempts")

var _best_attempt: Array[String]
var _best_attempt_statuses: Array[HackingGame.WordStatus]

func _handle_new_attempts(attempts: Array[Array], statuses: Array[Array]) -> void:
    if attempts.size() == 0:
        return

    if _best_attempt.size() > 0:
        var hbox: HBoxContainer = HBoxContainer.new()
        attempt_history.add_child(hbox)
        _add_attempt_passphrase(hbox, _best_attempt, _best_attempt_statuses)

    _clear_container(most_recent_attempt)
    for idx: int in range(attempts.size()):
        if idx == 0:
            _add_attempt_passphrase(most_recent_attempt, attempts[idx], statuses[idx])
            _best_attempt = attempts[idx]
            _best_attempt_statuses = statuses[idx]
        else:
            var hbox: HBoxContainer = HBoxContainer.new()
            attempt_history.add_child(hbox)
            _add_attempt_passphrase(hbox, attempts[idx], statuses[idx])

func _add_attempt_passphrase(root: Container, attempt: Array[String], statuses: Array[HackingGame.WordStatus]) -> void:
    for idx: int in range(_game.get_passphrase_length()):
        var in_attempt: bool = idx < statuses.size()
        _add_word_ui_to_container(
            root,
            "??" if !in_attempt else attempt[idx],
            func (_label: Label, bg: TextureRect, _root: Control) -> void:
                bg.texture = _status_to_texture(HackingGame.WordStatus.DEFAULT if !in_attempt else statuses[idx])
        )

func _handle_attempts_updated(attempts: int) -> void:
    _attempts_label.text = "%02d" % attempts

    var out_of_attempts: bool = attempts <= 0

    _attempt_button.disabled = out_of_attempts

    if out_of_attempts:
        for btn: Button in _shift_buttons:
            btn.disabled = true

var _field_labels: Dictionary[Vector2i, Label]
var _field_backgrounds: Dictionary[Vector2i, TextureRect]
var _field_roots: Dictionary[Vector2i, Control]
var _shift_buttons: Array[Button]

var _tween: Tween

const SLIDE_TIME: float = 0.3

func show_game() -> void:
    # Actual columns, one empty column inbetween each and then shifting buttons at the edges
    var columns: int = _game.width + _game.width - 1 + 2
    var rows: int = _game.height +  _game.height - 1 + 2

    _playing_field_outer_container.ratio = columns as float / rows as float
    _playing_field_container.columns = columns
    _playing_field_container_lower.columns = columns

    _clear_container(_playing_field_container_lower)
    _clear_container(_playing_field_container)
    _clear_container(most_recent_attempt)
    _clear_container(attempt_history)

    _field_labels.clear()
    _field_backgrounds.clear()
    _field_roots.clear()
    _shift_buttons.clear()

    _setup_lower_field(columns, rows)
    _setup_field(columns)
    _setup_placeholder_passphrase()

func _setup_placeholder_passphrase() -> void:
    for _idx: int in range(_game.get_passphrase_length()):
        _add_word_ui_to_container(
            most_recent_attempt,
            "??",
            func (_label: Label, bg: TextureRect, _root: Control) -> void:
                bg.texture = _status_to_texture(HackingGame.WordStatus.DEFAULT)
        )

func _setup_lower_field(columns: int, rows: int) -> void:
    var btn: Button
    for full_row: int in range(rows):
        for full_col: int in range(columns):
            if full_row == 0:
                if posmod(full_col, 2) == 0:
                    _playing_field_container_lower.add_child(_get_spacer(outer_spacer_color))

                else:
                    btn = _get_shift_button("down", tex_down)
                    _shift_buttons.append(btn)
                    if btn.connect(
                        "pressed",
                        func () -> void:
                            if _tween != null && _tween.is_running():
                                _tween.kill()
                                _sync_board()

                            @warning_ignore_start("integer_division")
                            var col: int =  (full_col - 1) / 2
                            @warning_ignore_restore("integer_division")

                            _game.shift_col(col, 1)

                            _tween = create_tween()
                            @warning_ignore_start("return_value_discarded")
                            _tween.set_parallel()
                            for row: int in range(_game.height):
                                var root: Control = _field_roots[Vector2i(col, row)]
                                var distance: float = root.get_global_rect().size.y * 2
                                _tween.tween_property(root, "global_position:y", root.global_position.y + distance, SLIDE_TIME)
                            @warning_ignore_restore("return_value_discarded")

                            await get_tree().create_timer(SLIDE_TIME * 1.1).timeout
                            _sync_board()
                            ,
                    ) != OK:
                        push_error("failed to connect shift down callback")
            elif full_row == rows - 1:
                if posmod(full_col, 2) == 0:
                    _playing_field_container_lower.add_child(_get_spacer(outer_spacer_color))

                else:
                    btn = _get_shift_button("up", tex_up)
                    _shift_buttons.append(btn)
                    if btn.connect(
                        "pressed",
                        func () -> void:
                            if _tween != null && _tween.is_running():
                                _tween.kill()
                                _sync_board()

                            @warning_ignore_start("integer_division")
                            var col: int = (full_col - 1) / 2
                            @warning_ignore_restore("integer_division")

                            _game.shift_col(col, -1)

                            _tween = create_tween()
                            @warning_ignore_start("return_value_discarded")
                            _tween.set_parallel()
                            for row: int in range(_game.height):
                                var root: Control = _field_roots[Vector2i(col, row)]
                                var distance: float = root.get_global_rect().size.y * 2
                                _tween.tween_property(root, "global_position:y", root.global_position.y - distance, SLIDE_TIME)
                            @warning_ignore_restore("return_value_discarded")

                            await get_tree().create_timer(SLIDE_TIME * 1.1).timeout
                            _sync_board()
                            ,
                    ) != OK:
                        push_error("failed to connect shift down callback")
            else:
                @warning_ignore_start("integer_division")
                var row: int = (full_row - 1) / 2
                @warning_ignore_restore("integer_division")

                if full_col == 0:
                    if posmod(full_row, 2) == 1:
                        btn = _get_shift_button("right", tex_right)
                        _shift_buttons.append(btn)
                        if btn.connect(
                            "pressed",
                            func () -> void:
                                if _tween != null && _tween.is_running():
                                    _tween.kill()
                                    _sync_board()

                                _game.shift_row(row, 1)

                                _tween = create_tween()
                                @warning_ignore_start("return_value_discarded")
                                _tween.set_parallel()
                                for idx: int in range(_game.width):
                                    var root: Control = _field_roots[Vector2i(idx, row)]
                                    var distance: float = root.get_global_rect().size.x * 2
                                    _tween.tween_property(root, "global_position:x", root.global_position.x + distance, SLIDE_TIME)
                                @warning_ignore_restore("return_value_discarded")

                                await get_tree().create_timer(SLIDE_TIME * 1.1).timeout
                                _sync_board()
                                ,
                        ) != OK:
                            push_error("failed to connect shift right callback")
                    else:
                        _playing_field_container_lower.add_child(_get_spacer(outer_spacer_color))
                elif full_col == columns - 1:
                    if posmod(full_row, 2) == 1:
                        btn = _get_shift_button("left", tex_left)
                        _shift_buttons.append(btn)
                        if btn.connect(
                            "pressed",
                            func () -> void:
                                if _tween != null && _tween.is_running():
                                    _tween.kill()
                                    _sync_board()


                                _game.shift_row(row, -1)

                                _tween = create_tween()
                                @warning_ignore_start("return_value_discarded")
                                _tween.set_parallel()
                                for idx: int in range(_game.width):
                                    var root: Control = _field_roots[Vector2i(idx, row)]
                                    var distance: float = root.get_global_rect().size.x * 2
                                    _tween.tween_property(root, "global_position:x", root.global_position.x - distance, SLIDE_TIME)
                                @warning_ignore_restore("return_value_discarded")

                                await get_tree().create_timer(SLIDE_TIME * 1.1).timeout
                                _sync_board()
                                ,
                        ) != OK:
                            push_error("failed to connect shift left callback")
                    else:
                        _playing_field_container_lower.add_child(_get_spacer(outer_spacer_color))
                else:
                    _playing_field_container_lower.add_child(_get_empty_container() if posmod(full_col, 2) == 1 && posmod(full_row, 2) == 1 else  _get_spacer(inner_spacer_color))

func _setup_field(columns: int) -> void:
    for full_col: int in range(columns):
        _playing_field_container.add_child(_get_empty_container())

    for row: int in range(_game.height):

        for col: int in range(_game.width):
            _playing_field_container.add_child(_get_empty_container())
            _create_and_add_code_place(row, col)

        _playing_field_container.add_child(_get_empty_container())

        for full_col: int in range(columns):
            _playing_field_container.add_child(_get_empty_container())

    _sync_board()
    show()

func _create_and_add_code_place(row: int, col: int) -> void:
    var coords: Vector2i = Vector2i(col, row)
    _add_word_ui_to_container(
        _playing_field_container,
        _game.get_word(coords),
        func (label: Label, bg: TextureRect, container: Control) -> void:
            _field_labels[coords] = label
            _field_backgrounds[coords] = bg
            _field_roots[coords] = container
    )

func _add_word_ui_to_container(parent: Container, word: String, parts_assignment: Variant = null) -> void:
    var container: Container = _get_empty_container()

    var bg: TextureRect = TextureRect.new()
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

    _size_playing_field_item(bg)
    container.add_child(bg)

    var label: Label = Label.new()
    label.text = word
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    _size_playing_field_item(label)
    container.add_child(label)

    parent.add_child(container)

    if parts_assignment != null && parts_assignment is Callable:
        @warning_ignore_start("unsafe_cast")
        (parts_assignment as Callable).call(label, bg, container)
        @warning_ignore_restore("unsafe_cast")


func _get_spacer(color: Color) -> Control:
    var container: Container = _get_empty_container()
    var rect: ColorRect = ColorRect.new()
    rect.color = color
    _size_playing_field_item(rect)

    container.add_child(rect)
    return container

func _get_shift_button(direction: String, tex: Texture) -> Button:
    var container: Container = _get_empty_container()
    var btn: Button = Button.new()
    btn.icon = tex
    btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    btn.expand_icon = true
    btn.tooltip_text = "Shift codes %s" % direction
    _size_playing_field_item(btn)

    container.add_child(btn)
    _playing_field_container_lower.add_child(container)
    return btn

func _get_empty_container() -> Control:
    var container: AspectRatioContainer = AspectRatioContainer.new()
    _size_playing_field_item(container)
    container.ratio = 1
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return container

func _size_playing_field_item(control: Control) -> void:
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _sync_board() -> void:
    if _tween != null && _tween.is_running():
        _tween.kill()

    for coords: Vector2i in _field_labels:
        _field_labels[coords].text = _game.get_word(coords)
        var discovered: bool = _game.is_discovered_present(coords)
        var not_present: bool = _game.is_discovered_not_present(coords)

        var status: HackingGame.WordStatus = _game.get_word_status(coords)
        _field_backgrounds[coords].texture = _status_to_texture(status)

        match status:
            HackingGame.WordStatus.DEFAULT:
                _field_labels[coords].add_theme_color_override("font_color", _get_word_text_color(discovered, not_present))
            HackingGame.WordStatus.DESTROYED:
                _field_labels[coords].add_theme_color_override("font_color", destroyed_text_color)
            HackingGame.WordStatus.WRONG_POSITION:
                _field_labels[coords].add_theme_color_override("font_color",  _get_word_text_color(discovered, not_present))
            HackingGame.WordStatus.CORRECT:
                _field_labels[coords].add_theme_color_override("font_color",  _get_word_text_color(discovered, not_present))


func _status_to_texture(status: HackingGame.WordStatus) -> Texture:
    match status:
        HackingGame.WordStatus.DEFAULT:
            return word_bg_tex_default
        HackingGame.WordStatus.DESTROYED:
            return word_bg_tex_destroyed
        HackingGame.WordStatus.WRONG_POSITION:
            return word_bg_tex_wrong_place
        HackingGame.WordStatus.CORRECT:
            return word_bg_tex_correct
        _:
            print_debug("Status %s not known as texture, using default" % status)
            return word_bg_tex_default

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

func _clear_container(container: Container) -> void:
    for child_idx: int in range(container.get_child_count()):
        container.get_child(child_idx).queue_free()
