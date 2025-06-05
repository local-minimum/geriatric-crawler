extends Node3D
class_name GridNodeFeature

var _node: GridNode
var _anchor: GridAnchor

var _inited: bool

# TODO: Negative anchors dont find the right node!
# TODO: I don't think anchors should be grid node features!
func _ready() -> void:
    if _node == null:
        _node = GridNode.find_node_parent(self)
        if _node != null:
            _inited = true


func get_grid_node() -> GridNode:
    if _anchor != null:
        return _anchor.get_grid_node()

    if !_inited && _node == null:
        _node = GridNode.find_node_parent(self)
        if _node == null:
            push_error("%s doesn't have a node as parent" % self)
        _inited = true

    return _node

func set_grid_node(node: GridNode, _deferred: bool = false) -> void:
    if _anchor != null:
        _anchor = null
    _node = node

    print_debug("Entity %s is now at %s in the air" % [name, coordinates()])

    if !_inited:
        _inited = true

func get_grid_anchor() -> GridAnchor:
    return _anchor

func set_grid_anchor(anchor: GridAnchor, _deferred: bool = false) -> void:
    _anchor = anchor
    _node = _anchor.get_grid_node()

    print_debug("Entity %s is now at %s %s" % [name, coordinates(), CardinalDirections.name(_anchor.direction)])

    if !_inited:
        _inited = true

func coordinates() -> Vector3i:
    if _node == null:
        push_error("Entity %s isn't at a node, accessing its coordinates makes no sense" % name)
        print_stack()
        return Vector3i.ZERO

    return _node.coordinates
