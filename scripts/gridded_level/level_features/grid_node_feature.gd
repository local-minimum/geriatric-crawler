extends Node3D
class_name GridNodeFeature

signal on_change_node(feature: GridNodeFeature)
signal on_change_anchor(feature: GridNodeFeature)

var _node: GridNode
var _anchor: GridAnchor

var _inited: bool

func _ready() -> void:
    _init_feature()

func _init_feature() -> void:
    if _inited:
        return

    _node = GridNode.find_node_parent(self)
    _inited = true

func get_level() -> GridLevel:
    _init_feature()

    if _node != null:
        return _node.get_level()
    return null

func get_grid_node() -> GridNode:
    _init_feature()

    if _anchor != null:
        return _anchor.get_grid_node()

    return _node

func set_grid_node(node: GridNode, _deferred: bool = false) -> void:
    if _anchor != null:
        _anchor = null
    _node = node

    print_debug("Entity %s is now at %s in the air" % [name, coordinates()])

    if !_inited:
        _inited = true

    on_change_anchor.emit(self)
    on_change_node.emit(self)

func get_grid_anchor() -> GridAnchor:
    _init_feature()
    return _anchor

func set_grid_anchor(anchor: GridAnchor, _deferred: bool = false) -> void:
    _anchor = anchor
    _node = _anchor.get_grid_node()

    print_debug("Entity %s is now at %s %s" % [name, coordinates(), CardinalDirections.name(_anchor.direction)])

    if !_inited:
        _inited = true

    on_change_anchor.emit(self)
    on_change_node.emit(self)

func coordinates() -> Vector3i:
    if _node == null:
        push_error("Entity %s isn't at a node, accessing its coordinates makes no sense" % name)
        print_stack()
        return Vector3i.ZERO

    return _node.coordinates
