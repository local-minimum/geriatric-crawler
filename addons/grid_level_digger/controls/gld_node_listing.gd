@tool
extends Control
class_name GLDNodeListing

@export var _node_field: LineEdit
@export var _move_up_button: Button
@export var _move_down_button: Button
@export var _remove_button: Button
@export var _empty_text: String = "[EMPTY]"

var _node: Node
var _remove: Variant
var _move_up: Variant
var _move_down: Variant

func _ready() -> void:
    _node_field.editable = false

func set_node(node: Node, remove: Variant = null, move_up: Variant = null, move_down: Variant = null, allow_remove: bool = true, allow_up: bool = true, allow_down: bool = true) -> void:
    _node = node
    _move_up = move_up
    _move_down = move_down
    _remove = remove

    _node_field.text = node.name if node != null else _empty_text
    _move_up_button.disabled = node == null || move_up == null || !allow_up
    _move_down_button.disabled = node == null || move_down == null || !allow_down
    _remove_button.disabled = node == null || remove == null || !allow_remove

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
