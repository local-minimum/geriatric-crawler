@tool
extends Control
class_name GLDNodeListing

signal on_change_text(text: String)

@export var _node_field: LineEdit
@export var _move_up_button: Button
@export var _move_down_button: Button
@export var _remove_button: Button
@export var _empty_text: String = "[EMPTY]"

var _remove: Variant
var _move_up: Variant
var _move_down: Variant

var editable: bool:
    get():
        return _node_field.editable
    set(value):
        _node_field.editable = value

func _ready() -> void:
    _node_field.editable = false

func set_node(node: Node, remove: Variant = null, move_up: Variant = null, move_down: Variant = null, allow_remove: bool = true, allow_up: bool = true, allow_down: bool = true) -> void:
    _move_up = move_up
    _move_down = move_down
    _remove = remove

    _node_field.text = node.name if node != null else _empty_text
    _move_up_button.disabled = node == null || move_up == null || !allow_up
    _move_down_button.disabled = node == null || move_down == null || !allow_down
    _remove_button.disabled = node == null || remove == null || !allow_remove

func set_text(text: String, remove: Variant = null, move_up: Variant = null, move_down: Variant = null, allow_remove: bool = true, allow_up: bool = true, allow_down: bool = true) -> void:
    _move_up = move_up
    _move_down = move_down
    _remove = remove

    _node_field.text = text
    _move_up_button.disabled = move_up == null || !allow_up
    _move_down_button.disabled = move_down == null || !allow_down
    _remove_button.disabled = remove == null || !allow_remove

func _on_remove_pressed() -> void:
    if _remove is Callable:
        var callback: Callable = _remove
        callback.call()

func _on_move_down_pressed() -> void:
    if _move_down is Callable:
        var callback: Callable = _move_down
        callback.call()

func _on_move_up_pressed() -> void:
    if _move_up is Callable:
        var callback: Callable = _move_up
        callback.call()

func _on_node_field_focus_exited() -> void:
    _on_node_field_text_submitted(_node_field.text)

func _on_node_field_text_submitted(new_text:String) -> void:
    if editable:
        on_change_text.emit(new_text)
