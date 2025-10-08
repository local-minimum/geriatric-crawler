@tool
extends Control
class_name GLDNewNode

signal on_change_text(text: String)

@export var _node_field: LineEdit
@export var _add_button: Button
@export var _nothing_selected_text: String = "[No Node Selected]"

var _node: Node
var _callback: Callable
var _called: bool
var _text_mode: bool

var editable: bool:
    get():
        return _node_field.editable
    set(value):
        _node_field.editable = value

func _ready():
    _node_field.editable = false

func set_node(node: Node, callback: Callable) -> void:
    _callback = callback
    _node = node
    _node_field.text = node.name if node != null else _nothing_selected_text
    _add_button.disabled = node == null
    _called = false
    _text_mode = false

func set_text_callback(callback: Callable) -> void:
    _callback = callback
    _node = null
    _add_button.disabled = false
    _called = false
    _text_mode = true

func _on_add_node_pressed() -> void:
    if !_called:
        if _text_mode:
            _callback.call(_node_field.text)
            _called = true
            _node_field.text = ""
        elif _node != null:
            _callback.call(_node)
            _called = true

func _on_new_node_field_focus_exited() -> void:
    _on_new_node_field_text_submitted(_node_field.text)

func _on_new_node_field_text_submitted(new_text:String) -> void:
    if editable:
        on_change_text.emit(new_text)
