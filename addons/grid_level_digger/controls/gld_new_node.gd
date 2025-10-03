@tool
extends Control
class_name GLDNewNode

@export var _node_field: LineEdit
@export var _add_button: Button
@export var _nothing_selected_text: String = "[No Node Selected]"

var _node: Node
var _callback: Callable
var _called: bool

func _ready():
    _node_field.editable = false

func set_node(node: Node, callback: Callable) -> void:
    _callback = callback
    _node = node
    _node_field.text = node.name if node != null else _nothing_selected_text
    _add_button.disabled = node == null
    _called = false

func _on_add_node_pressed() -> void:
    if _node != null && !_called:
        _callback.call(_node)
        _called = true
