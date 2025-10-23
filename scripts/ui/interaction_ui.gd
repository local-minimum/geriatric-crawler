extends Control
class_name InteractionUI

@export var _color: Color = Color.AZURE
@export var _line_width: float = 2
@export var _font: Font
@export var _font_size: int = 22
@export var _gap_padding: int = 2
@export_range(-2, 2) var _hint_y_offset: float = 0.3
@export var _text_hint_x_offset: int = 5
@export var _auto_end: bool = true
@export_range(1, 10) var _max_interactables: int = 5

var _interactables: Array[Interactable]
var _interacting: bool
var _requested: bool
var _moving: bool
var _active: Dictionary[String, Interactable]
var _cinematic: bool
var _mode: BindingHints.InputMode = BindingHints.InputMode.KEYBOARD_AND_MOUSE

func _enter_tree() -> void:
    if __SignalBus.on_allow_interactions.connect(_handle_allow_interaction) != OK:
        push_error("Failed to connect allow interactions")

    if __SignalBus.on_disallow_interactions.connect(_handle_disallow_interaction) != OK:
        push_error("Failed to connect disallow interactions")

    if __SignalBus.on_move_start.connect(_handle_move_start) != OK:
        push_error("Failed to connect move start")

    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

    if __SignalBus.on_cinematic.connect(_handle_cinematic) != OK:
        push_error("Failed to connect cinematic")

    if __SignalBus.on_update_input_mode.connect(_handle_update_input_mode) != OK:
        push_error("Failed to connect update input mode")

func _ready() -> void:
    _mode = (__BindingHints as BindingHints).mode

func _handle_update_input_mode(mode: BindingHints.InputMode) -> void:
    _mode = mode
    queue_redraw()

func _handle_cinematic(entity: GridEntity, cinematic: bool) -> void:
    if entity is not GridPlayerCore:
        return

    _cinematic = cinematic
    if _interacting:
        _interacting = false
        queue_redraw()


func _handle_allow_interaction(interactable: Interactable) -> void:
    if !_interactables.has(interactable):
        _interactables.append(interactable)

        if _interacting:
            queue_redraw()

func _handle_disallow_interaction(interactable: Interactable) -> void:
    _interactables.erase(interactable)

    if _interacting:
        queue_redraw()

func _handle_move_start(entity: GridEntity, _from: Vector3i, _translation_direction: CardinalDirections.CardinalDirection) -> void:
    if entity is not GridPlayerCore:
        return

    var was_interacting: bool = _interacting
    _moving = true
    _interacting = false
    _requested = false

    if was_interacting:
        queue_redraw()

func _handle_move_end(entity: GridEntity) -> void:
    if entity is not GridPlayerCore:
        return

    _moving = false
    _interacting = _requested
    _requested = false

    if _interacting:
        queue_redraw()

func _draw() -> void:
    _active.clear()

    if !_interacting:
        return

    var idx: int = 1
    for interactable: Interactable in _calculate_within_reach():
        if idx > _max_interactables:
            push_warning("Cannot show interactable %s because exceeding limit of %s at a time" % [interactable, _max_interactables])
            continue

        var id_key: String = _get_key_id(idx)
        _active[id_key] = interactable

        _draw_interactable_ui(id_key, interactable)

        idx += 1

func _get_key_id(idx: int) -> String: return "hot_key_%s" % idx

func _draw_interactable_ui(key: String, interactable: Interactable) -> void:
    var rect: Rect2 = _get_viewport_rect_with_3d_camera(interactable)
    var hint: Variant = __BindingHints.get_hint(key)

    var gap_size: int = 1
    var hint_text: String = ""
    if hint is String:
        hint_text = hint
        gap_size = hint_text.length()

    print_debug("[Interaction UI] %s -> %s rect %s" % [key, hint, rect])

    var top_left: Vector2 = get_global_transform().affine_inverse().basis_xform(rect.position)
    var lower_right: Vector2 = get_global_transform().affine_inverse().basis_xform(rect.end)
    var top_right: Vector2 = Vector2(lower_right.x, top_left.y)
    var lower_left: Vector2 = Vector2(top_left.x, lower_right.y)

    var top_gap_start: Vector2 = top_left + Vector2.RIGHT * _font_size * 0.5
    var top_gap_end: Vector2 = top_gap_start + Vector2.RIGHT * (_font_size * gap_size + 2 * _gap_padding)
    top_gap_end.x = minf(top_right.x, top_gap_end.x)


    draw_polyline(
        [
            top_gap_end,
            top_right,
            lower_right,
            lower_left,
            top_left,
            top_gap_start,
        ],
        _color,
        _line_width,
    )

    var text_start: Vector2 = top_gap_start + Vector2.RIGHT * _gap_padding + Vector2.UP * _font_size * _hint_y_offset

    if hint_text.is_empty() && hint is Texture2D:
        var tex: Texture2D = hint
        var r: Rect2 = Rect2(text_start + _font_size * Vector2.UP, Vector2(_font_size, _font_size))
        draw_texture_rect(
            tex,
            r,
            false,
            _color
        )
    else:
        text_start.x += _text_hint_x_offset
        draw_string(
            _font,
            text_start,
            hint_text if !hint_text.is_empty() else key,
            HORIZONTAL_ALIGNMENT_CENTER,
            -1,
            _font_size,
            _color,
        )

func _get_viewport_rect_with_3d_camera(interactable: Interactable) -> Rect2:
    var camera3d: Camera3D = get_viewport().get_camera_3d()

    var box: AABB = interactable.bounding_box()
    var min_pos: Vector2
    var max_pos: Vector2

    for idx: int in range(8):
        var corner_global: Vector3 = box.get_endpoint(idx)
        var pos: Vector2 = camera3d.unproject_position(corner_global)
        # print_debug("[Interaction UI] Corner %s -> %s" % [corner_global, pos])

        if idx == 0:
            min_pos = pos
            max_pos = pos
        else:
            min_pos.x = min(pos.x, min_pos.x)
            min_pos.y = min(pos.y, min_pos.y)
            max_pos.x = max(pos.x, max_pos.x)
            max_pos.y = max(pos.y, max_pos.y)

    var r_size: Vector2 = max_pos - min_pos
    return Rect2(min_pos, r_size)

func _calculate_within_reach() -> Array[Interactable]:
    return _interactables.filter(
        func (interactable: Interactable) -> bool:
            return  interactable.is_interactable && interactable.player_is_in_range()
    )

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("crawl_search"):
        if _moving:
            _requested = true
        else:
            _interacting = !_interacting
            queue_redraw()

    elif _interacting:
        for idx: int in range(1, _max_interactables + 1):
            var key: String = _get_key_id(idx)
            if event.is_action_pressed(key):
                _activate_hotkey_interaction(idx)
                break

func _activate_hotkey_interaction(idx: int) -> void:
    var interactable: Interactable = _active.get(_get_key_id(idx), null)
    if interactable != null:
        if interactable.check_allow_interact():
            interactable.execute_interation()

            if _auto_end:
                _interacting = false
                queue_redraw()
