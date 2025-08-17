extends Node
class_name HackingGameWorm

@export var game_ui: HackingGameUI

@export var _game: HackingGame

@export var _worming_navigation_container: Control

@export var worm_head_tex: Texture

@export var worm_head_dead_tex: Texture

@export var worm_straight_tex: Texture

@export var worm_angled_tex: Texture

@export var worm_tail_tex: Texture

@export var _deploy_worm_button: Button

@export var _worming_countdown: Label

const WORM_TICK_FREQ: int = 500
const WORM_SPEEDUP: int = 10
const WORM_MAX_SPEED: int = 80
const DEPLOY_WORM_TEXT: String = "Deploy Worm"
const CANCEL_WORM_TEXT: String = "Recall Worm"

var _worming: bool
var _worm_moving: bool
var _worm_next_tick: int
var _worm_size: int = 1
var _worming_direction: Vector2i
var _worm: Array[Vector2i]
var worm_ticks: int

var disabled: bool:
    set(value):
        disabled = value
        _deploy_worm_button.disabled = value

static func _delta_to_degrees(delta: Vector2i) -> float:
    match delta:
        Vector2i.LEFT: return 0
        Vector2i.UP: return 90
        Vector2i.RIGHT: return 180
        Vector2i.DOWN: return -90
        _:
            push_warning("Unexpected delta of %s" % delta)
            return 0

func _process(_delta: float) -> void:
    if _worm_moving && Time.get_ticks_msec() > _worm_next_tick:
        var new_head: Vector2i = _worm[0] + _worming_direction
        if !game_ui.lower_field.has(new_head) || _worm.has(new_head):
            _kill_worm()
            return

        _move_worm_head(new_head)
        worm_ticks += 1
        _worm_next_tick = Time.get_ticks_msec() + _calculate_worm_speed()

func _input(event: InputEvent) -> void:
    if event.is_echo() || !_worm_moving:
        return

    if event.is_action_pressed("crawl_forward"):
        _on_worm_up_pressed()

    elif event.is_action_pressed("crawl_backward"):
        _on_worm_down_pressed()

    elif event.is_action_pressed("crawl_strafe_left"):
        _on_worm_left_pressed()

    elif event.is_action_pressed("crawl_strafe_right"):
        _on_worm_right_pressed()

func reset_phase() -> void:
    _worming_navigation_container.hide()
    _worming_countdown.hide()

func reset_deploy_button_text() -> void:
    _deploy_worm_button.text = DEPLOY_WORM_TEXT

func _calculate_worm_speed() -> int:
    return maxi(WORM_MAX_SPEED, WORM_TICK_FREQ - worm_ticks * WORM_SPEEDUP)

func _move_worm_head(coords: Vector2i) -> void:
    _worm.push_front(coords)

    if game_ui.is_game_coords(coords):
        var eating: int = _game.worm_consume(game_ui.translate_to_game_coords(coords))
        if eating < 0:
            _kill_worm()
            return
        elif eating > 0:
            _worm_size += eating


    while _worm.size() > _worm_size:
        var t_rect: TextureRect = game_ui.lower_field[_worm[_worm.size() - 1]]
        t_rect.texture = game_ui.background_tex
        t_rect.rotation_degrees = 0
        _worm.pop_back()

    _draw_worm()

func _kill_worm() -> void:
    _worm_moving = false
    _worming = false
    _worming_navigation_container.hide()

    for size: int in range(_worm.size(), 0, -1):
        if size > 0:
            var t_rect: TextureRect = game_ui.lower_field[_worm[size - 1]]
            t_rect.texture = game_ui.background_tex
            t_rect.rotation_degrees = 0
            pass

        _worm.pop_back()
        _draw_worm()

        await get_tree().create_timer(_calculate_worm_speed() * 0.001).timeout

    _cancel_worm()
    print_debug("Worm dead")

func _draw_worm() -> void:
    var s: int = _worm.size()
    var prev_coords: Vector2i = Vector2i.ZERO
    for idx: int in range(s):
        var coords: Vector2i = _worm[idx]
        var d1: Vector2i = prev_coords - coords
        var next_coords: Vector2i = _worm[idx + 1] if idx + 1 < s else coords - d1
        var d2: Vector2i = coords - next_coords

        if !game_ui.lower_field.has(coords):
            print_debug("%s not in %s" % [coords, game_ui.lower_field.keys()])
            continue

        var t_rect: TextureRect = game_ui.lower_field[coords]
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

func _on_deploy_worm_pressed() -> void:
    if _worming:
        _cancel_worm()
    else:
        _ready_worm()

func _clear_drawn_worm() -> void:
    for coords: Vector2i in _worm:
        if game_ui.lower_field.has(coords):
            var t_rect: TextureRect = game_ui.lower_field[coords]
            t_rect.texture = null
            t_rect.rotation_degrees = 0
            t_rect.flip_h = false

func _cancel_worm() -> void:
    _worming = false
    game_ui.toggle_shift_buttons(false)
    _deploy_worm_button.text = DEPLOY_WORM_TEXT
    _worming_navigation_container.hide()
    _worming_countdown.hide()

    game_ui.sync_inventory_actions()
    game_ui.reset_phase()

    _clear_drawn_worm()
    _worm.clear()

func _ready_worm() -> void:
    _worm_moving = false
    _worming = true
    game_ui.toggle_shift_buttons(true)
    game_ui.set_worm_phase()
    _deploy_worm_button.text = CANCEL_WORM_TEXT
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
