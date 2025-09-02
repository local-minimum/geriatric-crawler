extends Node
class_name SceneSwapperSentinel

@export var _save_system: SaveSystem

@export var _check_nodes: Array[Node]
@export var _check_properties: Array[String]

var _check: bool

func _enter_tree() -> void:
    _check = true

func _process(_delta: float) -> void:
    if !_check:
        return

    if check():
        __SignalBus.on_scene_transition_new_scene_ready.emit()
        _check = false

func check() -> bool:
    if _save_system != null && _save_system != SaveSystem.instance:
        return false

    for idx: int in range(mini(_check_nodes.size(), _check_properties.size())):
        if !evaluate(_check_nodes[idx], _check_properties[idx]):
            return false

    return true

@warning_ignore_start("unsafe_cast")
func evaluate(node: Node, property: String) -> bool:
    var param: Variant = node.get(property)
    if param is Callable:
        param = (param as Callable).call()

    if param is bool:
        return param
    elif param is int || param is float:
        @warning_ignore_start("unsafe_call_argument")
        return bool(param)
        @warning_ignore_restore("unsafe_call_argument")
    elif param is String:
        return (param as String).is_empty()
    elif param is Dictionary:
        return (param as Dictionary).is_empty()
    elif param is Array:
        return (param as Array).is_empty()

    return param != null
@warning_ignore_restore("unsafe_cast")
