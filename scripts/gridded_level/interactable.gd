extends Node3D
class_name Interactable

@export var _collission_shape: CollisionShape3D

var is_interactable: bool = true
var _hovered: bool
var _showing_cursor_hand: bool

func _in_range(_event_position: Vector3) -> bool:
    return true

func _check_allow_interact() -> bool:
    return true

func _execute_interation() -> void:
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
            if _check_allow_interact():
                _execute_interation()

func _on_static_body_3d_mouse_entered() -> void:
    _hovered = true
    if is_interactable && _in_range(_collission_shape.global_position):
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
        _showing_cursor_hand = true

func _on_static_body_3d_mouse_exited() -> void:
    _hovered = false
    _showing_cursor_hand = false
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)
