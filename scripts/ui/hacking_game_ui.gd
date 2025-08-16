extends CanvasLayer
class_name HackingGameUI

@export var _game: HackingGame

@export var _attempts_label: Label

@export var _attempt_button: Button

@export var _bombs_label: Label

@export var _bombs_counter: Label

@export var _deploy_bomb_button: Button

@export var _worms_label: Label

@export var _worms_counter: Label

@export var _deploy_worm_button: Button

@export var _worming_navigation_container: Control

@export var _worming_countdown: Label

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

@export var worm_head_tex: Texture

@export var worm_head_dead_tex: Texture

@export var worm_straight_tex: Texture

@export var worm_angled_tex: Texture

@export var worm_tail_tex: Texture

const DEPLOY_BOMB_TEXT: String = "Deploy Bomb"
const CANCEL_BOMB_TEXT: String = "Abort Bomb Deployment"
const DEPLOY_WORM_TEXT: String = "Deploy Worm"
const CANCEL_WORM_TEXT: String = "Recall Worm"

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
            _sync_inventory_actions()

    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _on_hover_exit(_hover_coordinates)
            _game.bomb_coords(_marked_targets)
            _cancel_bombing()
            _sync_inventory_actions()

const WORM_TICK_FREQ: int = 500
const WORM_SPEEDUP: int = 10
const WORM_MAX_SPEED: int = 80
var worm_ticks: int

func _process(_delta: float) -> void:
    if _worm_moving && Time.get_ticks_msec() > _worm_next_tick:
        var new_head: Vector2i = _worm[0] + _worming_direction
        if !_lower_field_backgrounds.has(new_head) || _worm.has(new_head):
            _kill_worm()
            return

        _move_worm_head(new_head)
        worm_ticks += 1
        _worm_next_tick = Time.get_ticks_msec() + _calculate_worm_speed()

func _calculate_worm_speed() -> int:
    return maxi(WORM_MAX_SPEED, WORM_TICK_FREQ - worm_ticks * WORM_SPEEDUP)

func _is_game_coords(coords: Vector2i) -> bool:
    return posmod(coords.x, 2) == 1 && posmod(coords.y, 2) == 1

func _translate_to_game_coords(coords: Vector2i) -> Vector2i:
    @warning_ignore_start("integer_division")
    return Vector2i(coords.x / 2, coords.y / 2)
    @warning_ignore_restore("integer_division")

func _move_worm_head(coords: Vector2i) -> void:
    _worm.push_front(coords)

    if _is_game_coords(coords):
        var eating: int = _game.worm_consume(_translate_to_game_coords(coords))
        if eating < 0:
            _kill_worm()
            return
        elif eating > 0:
            _worm_size += eating


    while _worm.size() > _worm_size:
        var t_rect: TextureRect = _lower_field_backgrounds[_worm[_worm.size() - 1]]
        t_rect.texture = background_tex
        t_rect.rotation_degrees = 0
        _worm.pop_back()

    _draw_worm()

func _kill_worm() -> void:
    _worm_moving = false
    _worming = false
    _worming_navigation_container.hide()

    for size: int in range(_worm.size(), 0, -1):
        if size > 0:
            var t_rect: TextureRect = _lower_field_backgrounds[_worm[size - 1]]
            t_rect.texture = background_tex
            t_rect.rotation_degrees = 0

        _worm.pop_back()
        _draw_worm()

        await get_tree().create_timer(_calculate_worm_speed() * 0.001).timeout

    _cancel_worm()
    print_debug("Worm dead")

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
    _deploy_worm_button.disabled = true


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

    _clear_container(most_recent_attempt)
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
        _add_word_ui_to_container(
            root,
            "??" if !in_attempt else attempt[idx],
            func (_label: Label, bg: TextureRect, _root: Control) -> void:
                bg.texture = _status_to_texture(HackingGame.WordStatus.DEFAULT if !in_attempt else statuses[idx])
        )

func _handle_attempts_updated(attempts: int) -> void:
    print_debug("Got new attempts %s" % attempts)
    _attempts_label.text = "%02d" % attempts

    var out_of_attempts: bool = attempts <= 0

    _attempt_button.disabled = out_of_attempts

    if out_of_attempts:
        _deploy_worm_button.disabled = true
        _deploy_bomb_button.disabled = true
        toggle_shift_buttons(true)

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
var _lower_field_backgrounds: Dictionary[Vector2i, TextureRect]

var _tween: Tween

const SLIDE_TIME: float = 0.3

func show_game() -> void:
    # Actual columns, one empty column inbetween each and then shifting buttons at the edges
    var columns: int = _game.width + _game.width - 1 + 2
    var rows: int = _game.height +  _game.height - 1 + 2

    _playing_field_outer_container.ratio = columns as float / rows as float
    _playing_field_container.columns = columns
    _playing_field_container_lower.columns = columns
    _worming_navigation_container.hide()
    _worming_countdown.hide()

    _clear_container(_playing_field_container_lower)
    _clear_container(_playing_field_container)
    _clear_container(most_recent_attempt)
    _clear_container(attempt_history)

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
    _sync_inventory_actions()

    show()

func _sync_inventory_actions() -> void:
    var inventory: Inventory = Inventory.active_inventory
    var bombs: int = roundi(inventory.get_item_count(HackingGame.ITEM_HACKING_BOMB))
    var worms: int = roundi(inventory.get_item_count(HackingGame.ITEM_HACKING_WORM))

    _bombs_counter.text = "%03d" % bombs
    _deploy_bomb_button.text = DEPLOY_BOMB_TEXT
    _deploy_bomb_button.disabled = bombs == 0

    _worms_counter.text = "%03d" % worms
    _deploy_worm_button.text = DEPLOY_WORM_TEXT
    _deploy_worm_button.disabled = worms == 0

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
                    var is_below_word: bool = posmod(full_col, 2) == 1 && posmod(full_row, 2) == 1
                    _playing_field_container_lower.add_child(
                        _get_texture_spacer(
                            Color.TRANSPARENT if is_below_word else inner_spacer_color,
                            func (t_rect: TextureRect) -> void:
                                _lower_field_backgrounds[Vector2i(full_col, full_row)] = t_rect
                                t_rect.texture = background_tex
                                if !is_below_word:
                                    pass
                                ,
                        )
                    )

func _setup_field(columns: int) -> void:
    for full_col: int in range(columns):
        _playing_field_container.add_child(_get_empty_container())

    for row: int in range(_game.height):

        for col: int in range(_game.width):
            _playing_field_container.add_child(_get_empty_container())
            _create_and_add_word_tile(row, col)

        _playing_field_container.add_child(_get_empty_container())

        for full_col: int in range(columns):
            _playing_field_container.add_child(_get_empty_container())

    _sync_board()

func _create_and_add_word_tile(row: int, col: int) -> void:
    var coords: Vector2i = Vector2i(col, row)
    _add_word_ui_to_container(
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

func _get_texture_spacer(bg_color: Color, config_texturerect: Callable) -> Control:
    var container: Container = _get_spacer(bg_color)
    var t_rect: TextureRect = TextureRect.new()
    _size_playing_field_item(t_rect)

    config_texturerect.call(t_rect)
    t_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT

    container.add_child(t_rect)
    return container

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

func _on_deploy_bomb_pressed() -> void:
    if _bombing:
        _cancel_bombing()
    else:
        _ready_bombing()

func _on_deploy_worm_pressed() -> void:
    if _worming:
        _cancel_worm()
    else:
        _ready_worm()

var _worming: bool
var _worm_moving: bool
var _worm_next_tick: int
var _worm_size: int = 1
var _worming_direction: Vector2i
var _worm: Array[Vector2i]
var _bombing: bool

func _cancel_bombing() -> void:
    _bombing = false
    _deploy_bomb_button.text = DEPLOY_BOMB_TEXT
    toggle_word_controls(false)
    toggle_shift_buttons(false)
    _sync_inventory_actions()
    _handle_attempts_updated(_game.attempts_remaining)

func _ready_bombing() -> void:
    _bombing = true
    _deploy_bomb_button.text = CANCEL_BOMB_TEXT
    toggle_shift_buttons(true)
    toggle_word_controls(true)
    _deploy_worm_button.disabled = true
    _attempt_button.disabled = true

func _cancel_worm() -> void:
    _worming = false
    toggle_shift_buttons(false)
    _deploy_worm_button.text = DEPLOY_WORM_TEXT
    _worming_navigation_container.hide()
    _worming_countdown.hide()

    _sync_inventory_actions()
    _handle_attempts_updated(_game.attempts_remaining)

    _clear_drawn_worm()
    _worm.clear()

func _ready_worm() -> void:
    _worm_moving = false
    _worming = true
    toggle_shift_buttons(true)
    _deploy_worm_button.text = CANCEL_WORM_TEXT
    _deploy_bomb_button.disabled = true
    _attempt_button.disabled = true
    _worming_navigation_container.show()
    _worming_direction = Vector2i.LEFT
    @warning_ignore_start("integer_division")
    _worm = [
        Vector2i(
            _game.width * 2  - 1,
            _game.height / 2 * 2,
        )
    ]
    @warning_ignore_restore("integer_division")
    _worm_size = 5
    _draw_worm()

    _worming_countdown.show()
    for i: int in range(3, 0, -1):
        _worming_countdown.text = "%s" % i
        await get_tree().create_timer(WORM_TICK_FREQ / 1000.0).timeout

        if !_worming:
            return

    if _game.use_worm():
        _deploy_worm_button.disabled = true
        _worming_countdown.hide()
        worm_ticks = 0
        _worm_moving = true
        _worm_next_tick = Time.get_ticks_msec()
    else:
        _cancel_worm()

func _on_worm_up_pressed() -> void:
    if _worm_moving && _worming_direction != Vector2i.DOWN:
        _worming_direction = Vector2i.UP

func _on_worm_left_pressed() -> void:
    if _worm_moving && _worming_direction != Vector2i.RIGHT:
        _worming_direction = Vector2i.LEFT

func _on_worm_down_pressed() -> void:
    if _worm_moving && _worming_direction != Vector2i.UP:
        _worming_direction = Vector2i.DOWN

func _on_worm_right_pressed() -> void:
    if _worm_moving && _worming_direction != Vector2i.LEFT:
        _worming_direction = Vector2i.RIGHT

func _draw_worm() -> void:
    var s: int = _worm.size()
    var prev_coords: Vector2i = Vector2i.ZERO
    for idx: int in range(s):
        var coords: Vector2i = _worm[idx]
        var d1: Vector2i = prev_coords - coords
        var next_coords: Vector2i = _worm[idx + 1] if idx + 1 < s else coords - d1
        var d2: Vector2i = coords - next_coords

        if !_lower_field_backgrounds.has(coords):
            print_debug("%s not in %s" % [coords, _lower_field_backgrounds.keys()])
            continue

        var t_rect: TextureRect = _lower_field_backgrounds[coords]
        t_rect.pivot_offset = t_rect.size * 0.5
        t_rect.flip_h = false

        if idx == 0:
            t_rect.texture = worm_head_tex if _worming else worm_head_dead_tex
            t_rect.rotation_degrees = _delta_to_degrees(_worming_direction)
        elif idx == s - 1:
            t_rect.texture = worm_tail_tex
            t_rect.rotation_degrees = _delta_to_degrees(d1)
        elif d1 == d2:
            t_rect.texture = worm_straight_tex
            t_rect.rotation_degrees = _delta_to_degrees(d1)
        else:
            t_rect.texture = worm_angled_tex

            if d1 == Vector2i.UP:
                t_rect.rotation_degrees = 0
                if d2 == Vector2i.RIGHT:
                    t_rect.flip_h = true
                else:
                    t_rect.flip_h = false
            elif d1 == Vector2i.RIGHT:
                t_rect.rotation_degrees = 90
                if d2 == Vector2i.DOWN:
                    t_rect.flip_h = true
                else:
                    t_rect.flip_h = false
            elif d1 == Vector2i.DOWN:
                t_rect.rotation_degrees = 180
                if d2 == Vector2i.LEFT:
                    t_rect.flip_h = true
                else:
                    t_rect.flip_h = false
            else:
                t_rect.rotation_degrees = -90
                if d2 == Vector2i.UP:
                    t_rect.flip_h = true
                else:
                    t_rect.flip_h = false

        print_debug("Worm %s is %s is rotated %s" % [idx, coords, t_rect.rotation_degrees])
        prev_coords = coords

func _delta_to_degrees(delta: Vector2i) -> float:
    match delta:
        Vector2i.LEFT: return 0
        Vector2i.UP: return 90
        Vector2i.RIGHT: return 180
        Vector2i.DOWN: return -90
        _:
            push_warning("Unexpected delta of %s" % delta)
            return 0

func _clear_drawn_worm() -> void:
    for coords: Vector2i in _worm:
        if _lower_field_backgrounds.has(coords):
            var t_rect: TextureRect = _lower_field_backgrounds[coords]
            t_rect.texture = null
            t_rect.rotation_degrees = 0
            t_rect.flip_h = false
