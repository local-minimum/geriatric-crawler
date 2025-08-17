extends CanvasLayer
class_name HackingGameUI

@export var _game: HackingGame

@export var _attempts_label: Label

@export var _attempt_button: Button

@export var _bombs_label: Label

@export var _bombs_counter: Label

@export var _worms_label: Label

@export var _worms_counter: Label

@export var _worming: HackingGameWorm

@export var _deploy_bomb_button: Button

@export var background_tex: Texture

@export var outer_spacer_color: Color

@export var inner_spacer_color: Color

@export var tex_up: Texture

@export var tex_down: Texture

@export var tex_left: Texture

@export var tex_right: Texture

@export var _playing_field_outer_container: AspectRatioContainer

@export var _playing_field_container: GridContainer

@export var _playing_field_container_lower: GridContainer

@export var destroyed_text_color: Color

@export var default_text_color: Color

@export var discoverd_text_color: Color

@export var discoverd_not_text_color: Color

@export var target_text_color: Color = Color.HOT_PINK

@export var word_bg_tex_default: Texture

@export var word_bg_tex_destroyed: Texture

@export var word_bg_tex_correct: Texture

@export var word_bg_tex_wrong_place: Texture

@export var attempt_history: Container

@export var most_recent_attempt: Container

const DEPLOY_BOMB_TEXT: String = "Deploy Bomb"
const CANCEL_BOMB_TEXT: String = "Abort Bomb Deployment"

func _ready() -> void:
    hide()

    if _game.on_change_attempts.connect(_handle_attempts_updated) != OK:
        push_error("Could not connect to attempts updated")

    if _game.on_new_attempts.connect(_handle_new_attempts) != OK:
        push_error("Could not connect to new attempts")

    if _game.on_board_changed.connect(_sync_board) != OK:
        push_error("Could not connect to board changed")

    if _game.on_solve_game.connect(_handle_solve_game) != OK:
        push_error("Could not connect to hacking solved")

    if _game.on_fail_game.connect(_handle_fail_game) != OK:
        push_error("Could not connect to hacking failed")

    _bombs_label.text = HackingGame.item_id_to_text(HackingGame.ITEM_HACKING_BOMB)
    _worms_label.text = HackingGame.item_id_to_text(HackingGame.ITEM_HACKING_WORM)

func _unhandled_input(event: InputEvent) -> void:
    if !_bombing || !_hovering || event.is_echo():
        return

    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event
        if mouse.button_index == MOUSE_BUTTON_LEFT && mouse.pressed:
            _on_hover_exit(_hover_coordinates)
            _game.bomb_coords(_marked_targets)
            _cancel_bombing()
            sync_inventory_actions()

    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _on_hover_exit(_hover_coordinates)
            _game.bomb_coords(_marked_targets)
            _cancel_bombing()
            sync_inventory_actions()

func is_game_coords(coords: Vector2i) -> bool:
    return posmod(coords.x, 2) == 1 && posmod(coords.y, 2) == 1

func translate_to_game_coords(coords: Vector2i) -> Vector2i:
    @warning_ignore_start("integer_division")
    return Vector2i(coords.x / 2, coords.y / 2)
    @warning_ignore_restore("integer_division")

func _handle_solve_game(solution_start: Vector2i) -> void:
    _disable_everything()
    var rect: Rect2i = Rect2i(solution_start, Vector2i( _game.get_passphrase_length(), 1))
    for coords: Vector2i in _field_roots:
        _field_labels[coords].visible = rect.has_point(coords)
        _field_backgrounds[coords].visible = rect.has_point(coords)

    await get_tree().create_timer(1.5).timeout

    hide()
    _game.end_game()

func _handle_fail_game() -> void:
    _disable_everything()

    for coords: Vector2i in _field_roots:
        _field_labels[coords].visible = false
        _field_backgrounds[coords].visible = false
        await get_tree().create_timer(0.01).timeout

    await get_tree().create_timer(0.8).timeout

    hide()
    _game.end_game()

func _disable_everything() -> void:
    toggle_shift_buttons(false)
    toggle_word_controls(false)
    _attempt_button.disabled = true
    _deploy_bomb_button.disabled = true
    _worming.disabled = true


var _attempts: Array[String]
var _best_attempt: Array[String]
var _best_attempt_statuses: Array[HackingGame.WordStatus]

func _handle_new_attempts(attempts: Array[Array], statuses: Array[Array]) -> void:
    if attempts.size() == 0:
        return

    # We should always show best attempt on current board so best attempt from previous should move to history if novel
    if _best_attempt.size() > 0 && !_attempts.has("".join(_best_attempt)):
        var hbox: HBoxContainer = HBoxContainer.new()
        attempt_history.add_child(hbox)
        _attempts.append("".join(_best_attempt))
        _add_attempt_passphrase(hbox, _best_attempt, _best_attempt_statuses)

    UIUtils.clear_control(most_recent_attempt)
    for idx: int in range(attempts.size()):
        var phrase: String = "".join(attempts[idx])
        if idx == 0:
            _add_attempt_passphrase(most_recent_attempt, attempts[idx], statuses[idx])
            _best_attempt = attempts[idx]
            _best_attempt_statuses = statuses[idx]
        elif !_attempts.has(phrase):
            var hbox: HBoxContainer = HBoxContainer.new()
            attempt_history.add_child(hbox)
            _add_attempt_passphrase(hbox, attempts[idx], statuses[idx])
            _attempts.append(phrase)

func _add_attempt_passphrase(root: Container, attempt: Array[String], statuses: Array[HackingGame.WordStatus]) -> void:
    for idx: int in range(_game.get_passphrase_length()):
        var in_attempt: bool = idx < statuses.size()
        HackingGameUIBuilder.add_word_ui_to_container(
            root,
            "??" if !in_attempt else attempt[idx],
            func (_label: Label, bg: TextureRect, _root: Control) -> void:
                bg.texture = _status_to_texture(HackingGame.WordStatus.DEFAULT if !in_attempt else statuses[idx])
        )

func reset_phase() -> void:
    var out_of_attempts: bool = _game.attempts_remaining <= 0
    _attempt_button.disabled = out_of_attempts

    if out_of_attempts:
        _worming.disabled = true
        _deploy_bomb_button.disabled = true
        toggle_shift_buttons(true)

func set_worm_phase() -> void:
    _deploy_bomb_button.disabled = true
    _attempt_button.disabled = true


func _handle_attempts_updated(attempts: int) -> void:
    print_debug("Got new attempts %s" % attempts)
    _attempts_label.text = "%02d" % attempts

    reset_phase()

func toggle_shift_buttons(disabled: bool) -> void:
    for btn: Button in _shift_buttons:
        btn.disabled = disabled

func toggle_word_controls(interactable: bool) -> void:
    for coords: Vector2i in _field_roots:
        _field_roots[coords].mouse_default_cursor_shape = Control.CursorShape.CURSOR_POINTING_HAND if interactable else Control.CursorShape.CURSOR_ARROW

var _field_labels: Dictionary[Vector2i, Label]
var _field_backgrounds: Dictionary[Vector2i, TextureRect]
var _field_roots: Dictionary[Vector2i, Control]
var _shift_buttons: Array[Button]
var lower_field: Dictionary[Vector2i, TextureRect]

var _tween: Tween

const SLIDE_TIME: float = 0.3

func show_game() -> void:
    # Actual columns, one empty column inbetween each and then shifting buttons at the edges
    var columns: int = _game.width + _game.width - 1 + 2
    var rows: int = _game.height +  _game.height - 1 + 2

    _playing_field_outer_container.ratio = columns as float / rows as float
    _playing_field_container.columns = columns
    _playing_field_container_lower.columns = columns

    _worming.reset_phase()

    UIUtils.clear_control(_playing_field_container_lower)
    UIUtils.clear_control(_playing_field_container)
    UIUtils.clear_control(most_recent_attempt)
    UIUtils.clear_control(attempt_history)

    _field_labels.clear()
    _field_backgrounds.clear()
    _field_roots.clear()
    _shift_buttons.clear()
    _attempts.clear()
    _best_attempt.clear()
    _best_attempt_statuses.clear()

    _setup_lower_field(columns, rows)
    _setup_field(columns)
    _setup_placeholder_passphrase()
    sync_inventory_actions()

    show()

func sync_inventory_actions() -> void:
    var inventory: Inventory = Inventory.active_inventory
    var bombs: int = roundi(inventory.get_item_count(HackingGame.ITEM_HACKING_BOMB))
    var worms: int = roundi(inventory.get_item_count(HackingGame.ITEM_HACKING_WORM))

    _bombs_counter.text = "%03d" % bombs
    _deploy_bomb_button.text = DEPLOY_BOMB_TEXT
    _deploy_bomb_button.disabled = bombs == 0

    _worms_counter.text = "%03d" % worms
    _worming.disabled = worms == 0
    _worming.reset_deploy_button_text()

func _setup_placeholder_passphrase() -> void:
    for _idx: int in range(_game.get_passphrase_length()):
        HackingGameUIBuilder.add_word_ui_to_container(
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
                    _playing_field_container_lower.add_child(HackingGameUIBuilder.get_spacer(outer_spacer_color))

                else:
                    btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, "down", tex_down)
                    _shift_buttons.append(btn)
                    if btn.connect(
                        "pressed",
                        func () -> void:
                            toggle_shift_buttons(true)
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
                            toggle_shift_buttons(false)
                            ,
                    ) != OK:
                        push_error("failed to connect shift down callback")
            elif full_row == rows - 1:
                if posmod(full_col, 2) == 0:
                    _playing_field_container_lower.add_child(HackingGameUIBuilder.get_spacer(outer_spacer_color))

                else:
                    btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, "up", tex_up)
                    _shift_buttons.append(btn)
                    if btn.connect(
                        "pressed",
                        func () -> void:
                            toggle_shift_buttons(true)
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
                            toggle_shift_buttons(false)
                            ,
                    ) != OK:
                        push_error("failed to connect shift down callback")
            else:
                @warning_ignore_start("integer_division")
                var row: int = (full_row - 1) / 2
                @warning_ignore_restore("integer_division")

                if full_col == 0:
                    if posmod(full_row, 2) == 1:
                        btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, "right", tex_right)
                        _shift_buttons.append(btn)
                        if btn.connect(
                            "pressed",
                            func () -> void:
                                toggle_shift_buttons(true)
                                if _tween != null && _tween.is_running():
                                    _tween.kill()
                                    _sync_board()

                                _game.shift_row(row, 1)
                                _tween = create_tween()

                                @warning_ignore_start("return_value_discarded")
                                for idx: int in range(_game.width):
                                    var root: Control = _field_roots[Vector2i(idx, row)]
                                    var distance: float = root.get_global_rect().size.x * 2
                                    _tween.tween_property(root, "global_position:x", root.global_position.x + distance, SLIDE_TIME)
                                    if idx == 0:
                                        _tween.set_parallel()
                                @warning_ignore_restore("return_value_discarded")

                                await get_tree().create_timer(SLIDE_TIME * 1.1).timeout
                                _sync_board()
                                toggle_shift_buttons(false)
                                ,
                        ) != OK:
                            push_error("failed to connect shift right callback")
                    else:
                        _playing_field_container_lower.add_child(HackingGameUIBuilder.get_spacer(outer_spacer_color))
                elif full_col == columns - 1:
                    if posmod(full_row, 2) == 1:
                        btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, "left", tex_left)
                        _shift_buttons.append(btn)
                        if btn.connect(
                            "pressed",
                            func () -> void:
                                toggle_shift_buttons(true)
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
                                toggle_shift_buttons(false)
                                ,
                        ) != OK:
                            push_error("failed to connect shift left callback")
                    else:
                        _playing_field_container_lower.add_child(HackingGameUIBuilder.get_spacer(outer_spacer_color))
                else:
                    var is_below_word: bool = posmod(full_col, 2) == 1 && posmod(full_row, 2) == 1
                    _playing_field_container_lower.add_child(
                        HackingGameUIBuilder.get_texture_spacer(
                            Color.TRANSPARENT if is_below_word else inner_spacer_color,
                            func (t_rect: TextureRect) -> void:
                                lower_field[Vector2i(full_col, full_row)] = t_rect
                                t_rect.texture = background_tex
                                if !is_below_word:
                                    pass
                                ,
                        )
                    )

func _setup_field(columns: int) -> void:
    for full_col: int in range(columns):
        _playing_field_container.add_child(HackingGameUIBuilder.get_empty_container())

    for row: int in range(_game.height):

        for col: int in range(_game.width):
            _playing_field_container.add_child(HackingGameUIBuilder.get_empty_container())
            _create_and_add_word_tile(row, col)

        _playing_field_container.add_child(HackingGameUIBuilder.get_empty_container())

        for full_col: int in range(columns):
            _playing_field_container.add_child(HackingGameUIBuilder.get_empty_container())

    _sync_board()

func _create_and_add_word_tile(row: int, col: int) -> void:
    var coords: Vector2i = Vector2i(col, row)
    HackingGameUIBuilder.add_word_ui_to_container(
        _playing_field_container,
        _game.get_word(coords),
        func (label: Label, bg: TextureRect, container: Control) -> void:
            _field_labels[coords] = label
            _field_backgrounds[coords] = bg
            _field_roots[coords] = container

            container.mouse_filter = Control.MOUSE_FILTER_PASS

            if container.connect(
                "mouse_entered",
                func () -> void:
                    _on_hover_enter(coords)
                    ,
            ) != OK:
                push_error("Word at %s could not connect mouse enter" % coords)

            if container.connect(
                "mouse_exited",
                func () -> void:
                    _on_hover_exit(coords)
                    ,
            ) != OK:
                push_error("Word at %s could not connect mouse exit" % coords)
    )

var _hovering: bool
var _hover_coordinates: Vector2i
var _marked_targets: Array[Vector2i]

func _on_hover_enter(coords: Vector2i) -> void:
    _hovering = true
    _hover_coordinates = coords

    if _bombing:
        _marked_targets = _game.get_potential_bomb_target(coords)
        for target: Vector2i in _marked_targets:
            _field_labels[target].add_theme_color_override("font_color", target_text_color)

func _on_hover_exit(coords: Vector2i) -> void:
    if coords == _hover_coordinates:
        _hovering = false
        if _bombing:
            for target: Vector2i in _marked_targets:
                var discovered: bool = _game.is_discovered_present(target)
                var not_present: bool = _game.is_discovered_not_present(target)
                _field_labels[target].add_theme_color_override("font_color", _get_word_text_color(discovered, not_present))


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
    _game.hack()
    _sync_board()

func _on_deploy_bomb_pressed() -> void:
    if _bombing:
        _cancel_bombing()
    else:
        _ready_bombing()
var _bombing: bool

func _cancel_bombing() -> void:
    _bombing = false
    _deploy_bomb_button.text = DEPLOY_BOMB_TEXT
    toggle_word_controls(false)
    toggle_shift_buttons(false)
    sync_inventory_actions()
    _handle_attempts_updated(_game.attempts_remaining)

func _ready_bombing() -> void:
    _bombing = true
    _deploy_bomb_button.text = CANCEL_BOMB_TEXT
    toggle_shift_buttons(true)
    toggle_word_controls(true)
    _worming.disabled = true
    _attempt_button.disabled = true
