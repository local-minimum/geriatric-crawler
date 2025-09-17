extends Node3D
class_name Interactable

@export var _collission_shape: CollisionShape3D

var is_interactable: bool = true:
    set(value):
        is_interactable = value
        if value:
            __SignalBus.on_allow_interactions.emit(self)
        else:
            __SignalBus.on_disallow_interactions.emit(self)

var _hovered: bool
var _showing_cursor_hand: bool

func _exit_tree() -> void:
    is_interactable = false

func player_is_in_range() -> bool:
    return _in_range(_collission_shape.global_position)

func bounding_box() -> AABB:
    var size: Vector3 = Vector3.ONE

    if _collission_shape.shape is BoxShape3D:
        var box: BoxShape3D = _collission_shape.shape
        size = basis * box.size

    elif _collission_shape.shape is SphereShape3D:
        var sphere: SphereShape3D = _collission_shape.shape
        size = basis * (sphere.radius * Vector3i.ONE)
    else:
        push_warning("Collision shape %s type not handled" % _collission_shape.shape)

    return AABB(_collission_shape.global_position - size * 0.5, size)

func _in_range(_event_position: Vector3) -> bool:
    return true

func check_allow_interact() -> bool:
    return true

func execute_interation() -> void:
    pass

func _on_static_body_3d_input_event(
    _camera: Node,
    event: InputEvent,
    event_position: Vector3,
    _normal: Vector3,
    _shape_idx: int,
) -> void:
    if !is_interactable:
        return

    if _in_range(event_position):
        if !_showing_cursor_hand:
            Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
            _showing_cursor_hand = true
    else:
        if _showing_cursor_hand:
            Input.set_default_cursor_shape(Input.CURSOR_ARROW)
            _showing_cursor_hand = false

        return

    if event is InputEventMouseButton && !event.is_echo():
        var mouse_event: InputEventMouseButton = event

        if mouse_event.pressed && mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if check_allow_interact():
                execute_interation()

func _on_static_body_3d_mouse_entered() -> void:
    _hovered = true
    if is_interactable && _in_range(_collission_shape.global_position):
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
        _showing_cursor_hand = true

func _on_static_body_3d_mouse_exited() -> void:
    _hovered = false
    _showing_cursor_hand = false
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)
