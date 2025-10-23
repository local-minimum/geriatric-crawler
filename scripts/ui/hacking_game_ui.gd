extends CanvasLayer
class_name HackingGameUI

const _HACKING_TUTORIAL_KEY: String = "hacking"
const _HACKING_TUTORIAL_BOMB_KEY: String = "hacking.bomb"
const _HACKING_TUTORIAL_CORRECT_PLACE_KEY: String = "hacking.correct"
const _HACKING_TUTORIAL_WRONG_PLACE_KEY: String = "hacking.wrong"
const _HACKING_TUTORIAL_DESTROYED_PLACE_KEY: String = "hacking.destroyed"
const _HACKING_TUTORIAL_INCLUEDED_KEY: String = "hacking.included"
const _HACKING_TUTORIAL_EXCLUDED_KEY: String = "hacking.excluded"

@export var _game: HackingGame

@export var _hacking_area: Control

@export var _controls_area: Control

@export var _attempts_label: Label

@export var _attempts_counter: Label

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

@export var most_recent_attempt_label: Label

@export var most_recent_attempt: Container

@export var intro_tutorial: Array[String]
@export var bombing_tutorial: Array[String]
@export var worming_tutorial: Array[String]
@export var correct_tutorial: Array[String]
@export var wrong_place_tutorial: Array[String]
@export var destroyed_tutorial: Array[String]
@export var included_tutorial: Array[String]
@export var excluded_tutorial: Array[String]


const DEPLOY_BOMB_TEXT: String = "Deploy Bomb"
const CANCEL_BOMB_TEXT: String = "Abort Bomb Deployment"

var _inv: Inventory.InventorySubscriber

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()

    if __SignalBus.on_update_handedness.connect(_handle_handedness) != OK:
        push_error("Could not connect handedness change")

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

    _handle_handedness(AccessibilitySettings.handedness)

    _bombs_label.text = GCLootableManager.translate(GCLootableManager.ITEM_HACKING_BOMB, 999)
    _worms_label.text = GCLootableManager.translate(GCLootableManager.ITEM_HACKING_WORM, 999)

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
            check_board_tutorials()


    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _on_hover_exit(_hover_coordinates)
            _game.bomb_coords(_marked_targets)
            _cancel_bombing()
            sync_inventory_actions()
            check_board_tutorials()

func is_game_coords(coords: Vector2i) -> bool:
    return posmod(coords.x, 2) == 1 && posmod(coords.y, 2) == 1

func translate_to_game_coords(coords: Vector2i) -> Vector2i:
    @warning_ignore_start("integer_division")
    return Vector2i(coords.x / 2, coords.y / 2)
    @warning_ignore_restore("integer_division")

func _handle_handedness(hand: AccessibilitySettings.Handedness) -> void:
    if hand == AccessibilitySettings.Handedness.RIGHT:
        _controls_area.move_to_front()
    else:
        _hacking_area.move_to_front()

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
    await get_tree().create_timer(0.8).timeout

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
    _attempts_counter.text = "%02d" % attempts

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

    var progress: int = _game.settings.tutorial.get_tutorial_progress(_HACKING_TUTORIAL_KEY)
    if progress == 0:
        tutorial_idx = 0
        _game.tutoral_ui.reset_tutorial()
        active_tutorial = intro_tutorial
        on_complete_tutorial.clear()
        on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_KEY, 1))
        show_current_tutorial()

var tutorial_idx: int

var active_tutorial: Array[String]
var fallback_tutorial_targets: Array[Array]

class OnCompleteTutorial:
    var key: String
    var step: int
    var callback: Variant

    @warning_ignore_start("shadowed_variable")
    func _init(key: String, step: int, callback: Variant = null) -> void:
        self.key = key
        self.step = step
        self.callback = callback
    @warning_ignore_restore("shadowed_variable")

var on_complete_tutorial: Array[OnCompleteTutorial]

func show_current_tutorial() -> void:
    _game.tutoral_ui.show_tutorial(
        tr(active_tutorial[tutorial_idx]),
        null if tutorial_idx == 0 else (_show_previous_tutorial as Variant),
        _show_next_tutorial,
        _get_intro_current_targets(),
    )

func _get_intro_current_targets() -> Array[Control]:
    if active_tutorial == intro_tutorial:
        match tutorial_idx:
            0:
                return [most_recent_attempt_label, most_recent_attempt]
            1:
                return [_attempts_counter, _attempts_label]
            2:
                return [_bombs_label, _bombs_counter, _worms_label, _worms_counter, _deploy_bomb_button, _worming._deploy_worm_button]
            3:
                return [_playing_field_container]
            4:
                _sync_board()
                var example: Array[Control]
                for col: int in range(1, _game.get_passphrase_length() + 1):
                    var coords: Vector2i = Vector2i(col, 1)
                    if _field_roots.has(coords):
                        example.append(_field_roots[coords])
                return example
            5:
                return [_shift_buttons[3]]
            6:
                return [_attempt_button]

    elif active_tutorial == bombing_tutorial:
        match  tutorial_idx:
            0,1,2:
                return [_field_roots[_field_roots.keys()[0]]]
            3:
                return [_shift_buttons[3]]
            4:
                return [_deploy_bomb_button]

    elif active_tutorial == worming_tutorial:
        match  tutorial_idx:
            0, 7:
                return [_worming.worm_head_texture_rect]
            1:
                return [_worming._worming_countdown]
            2:
                return [_worming._deploy_worm_button]
            3:
                return [_shift_buttons[3]]
            4:
                return [_worming._worming_navigation_container]
            5, 6:
                return [_field_roots[_field_roots.keys()[0]]]
            8:
                var lowest: Vector2i
                var highest: Vector2i
                var first: bool = true
                for coords: Vector2i in _field_roots:
                    if first:
                        lowest = coords
                        highest = coords
                        first = false
                    else:
                        if coords.y <= lowest.y && coords.x <= lowest.x:
                            lowest = coords
                        if coords.y >= highest.y && coords.x >= highest.x:
                            highest = coords

                return [_field_roots[lowest],_field_roots[highest]]

    elif fallback_tutorial_targets.size() > tutorial_idx:
        return fallback_tutorial_targets[tutorial_idx]
    return []

func _show_previous_tutorial() -> void:
    tutorial_idx = maxi(0, tutorial_idx - 1)
    show_current_tutorial()

func _show_next_tutorial() -> void:
    tutorial_idx += 1
    if tutorial_idx < active_tutorial.size():
        show_current_tutorial()
    else:
        for on_complete: OnCompleteTutorial in on_complete_tutorial:
            _game.settings.tutorial.set_tutorial_progress(on_complete.key, on_complete.step)
            if on_complete.callback is Callable:
                @warning_ignore_start("unsafe_cast")
                (on_complete.callback as Callable).call()
                @warning_ignore_restore("unsafe_cast")

        on_complete_tutorial.clear()

func sync_inventory_actions() -> void:
    var bombs: int = roundi(_inv.inventory.get_item_count(GCLootableManager.ITEM_HACKING_BOMB))
    var worms: int = roundi(_inv.inventory.get_item_count(GCLootableManager.ITEM_HACKING_WORM))

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
    var down_text: String = tr("CARDINAL_DOWN")
    var up_text: String = tr("CARDINAL_UP")
    var left_text: String = tr("LEFT")
    var right_text: String = tr("RIGHT")

    for full_row: int in range(rows):
        for full_col: int in range(columns):
            if full_row == 0:
                if posmod(full_col, 2) == 0:
                    _playing_field_container_lower.add_child(HackingGameUIBuilder.get_spacer(outer_spacer_color))

                else:
                    btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, down_text, tex_down)
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
                    btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, up_text, tex_up)
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
                        btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, right_text, tex_right)
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
                        btn = HackingGameUIBuilder.get_shift_button(_playing_field_container_lower, left_text, tex_left)
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
    check_board_tutorials()

func check_board_tutorials() -> void:
    await get_tree().create_timer(0.5).timeout
    active_tutorial = []
    fallback_tutorial_targets = []

    var tutorial_settings: TutorialSettings = _game.settings.tutorial
    if tutorial_settings.get_tutorial_progress(_HACKING_TUTORIAL_CORRECT_PLACE_KEY) == 0 && _game.has_any(HackingGame.WordStatus.CORRECT):
        active_tutorial.append_array(correct_tutorial)
        var correct_targets: Array[Control] = [_field_roots.get(_game.get_first(HackingGame.WordStatus.CORRECT), null)]
        var attempts_targets: Array[Control] = [most_recent_attempt, attempt_history]

        fallback_tutorial_targets.append_array([
            correct_targets,
            correct_targets,
            attempts_targets,
        ])

        on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_CORRECT_PLACE_KEY, 1))

    if tutorial_settings.get_tutorial_progress(_HACKING_TUTORIAL_WRONG_PLACE_KEY) == 0 && _game.has_any(HackingGame.WordStatus.WRONG_POSITION):
        active_tutorial.append_array(wrong_place_tutorial)
        var incorrect_targets: Array[Control] = [_field_roots.get(_game.get_first(HackingGame.WordStatus.WRONG_POSITION), null)]

        fallback_tutorial_targets.append_array([
            incorrect_targets,
        ])

        on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_WRONG_PLACE_KEY, 1))

    if tutorial_settings.get_tutorial_progress(_HACKING_TUTORIAL_DESTROYED_PLACE_KEY) == 0 && _game.has_any(HackingGame.WordStatus.DESTROYED):
        active_tutorial.append_array(destroyed_tutorial)
        var destroyed_targets: Array[Control] = [_field_roots.get(_game.get_first(HackingGame.WordStatus.DESTROYED), null)]

        fallback_tutorial_targets.append_array([
            destroyed_targets,
        ])

        on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_DESTROYED_PLACE_KEY, 1))

    if tutorial_settings.get_tutorial_progress(_HACKING_TUTORIAL_INCLUEDED_KEY) == 0:
        var ctrl: Control = _field_roots.get(_game.get_first_known_inluded())
        if ctrl != null:
            active_tutorial.append_array(included_tutorial)
            var targets: Array[Control] = [ctrl]
            fallback_tutorial_targets.append(targets)
            on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_INCLUEDED_KEY, 1))

    if tutorial_settings.get_tutorial_progress(_HACKING_TUTORIAL_EXCLUDED_KEY) == 0:
        var ctrl: Control = _field_roots.get(_game.get_first_known_not_inluded())
        if ctrl != null:
            active_tutorial.append_array(excluded_tutorial)
            var targets: Array[Control] = [ctrl]
            fallback_tutorial_targets.append(targets)
            on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_EXCLUDED_KEY, 1))

    if !active_tutorial.is_empty():
        tutorial_idx = 0
        show_current_tutorial()

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
    var tutorial: int = _game.settings.tutorial.get_tutorial_progress(_HACKING_TUTORIAL_BOMB_KEY)
    if tutorial == 0:
        active_tutorial = bombing_tutorial
        on_complete_tutorial.clear()
        on_complete_tutorial.append(OnCompleteTutorial.new(_HACKING_TUTORIAL_BOMB_KEY, 1))
        tutorial_idx = 0
        show_current_tutorial()

    _deploy_bomb_button.text = CANCEL_BOMB_TEXT
    toggle_shift_buttons(true)
    toggle_word_controls(true)
    _worming.disabled = true
    _attempt_button.disabled = true

    _bombing = true
