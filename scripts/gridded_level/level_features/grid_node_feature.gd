extends Node3D
class_name GridNodeFeature

var _node: GridNode
var _anchor: GridAnchor

func _ready() -> void:
    if _node == null:
        _node = _find_node_parent(self)

func get_grid_node() -> GridNode:
    if _anchor != null:
        return _anchor.get_grid_node()
    return _node

func set_grid_node(node: GridNode, deferred: bool = false) -> void:
    if _anchor != null:
        _anchor = null
    _node = node
    _parent_to_node(deferred)

func get_grid_anchor() -> GridAnchor:
    return _anchor

func set_grid_anchor(anchor: GridAnchor, deferred: bool = false) -> void:
    _anchor = anchor
    _node = _anchor.get_grid_node()
    _parent_to_anchor(deferred)

func _parent_to_node(deferred: bool = false) -> void:
    if _node == null:
        return

    var parent: Node = self.get_parent()
    if _node != parent:
        # print_debug("%s has parent %s but wants node %s" % [name, parent, _node])
        if deferred:
            reparent.call_deferred(_node, true)
        else:
            reparent(_node, true)

func _parent_to_anchor(deferred: bool = false) -> void:
    if _anchor == null:
        return

    var parent: Node = self.get_parent()
    if _anchor != parent:
        # print_debug("%s has parent %s but wants anchor %s" % [name, parent, _anchor])
        if deferred:
            reparent.call_deferred(_anchor, true)
        else:
            reparent(_anchor, true)

func _find_node_parent(current: Node) ->  GridNode:
    var parent: Node = current.get_parent()

    if parent == null:
        push_warning("Entity %s not a child of a GridNode" % name)
        return null

    if parent is GridNode:
        return parent as GridNode

    return _find_node_parent(parent)

func coordnates() -> Vector3i:
    if _node == null:
        push_error("Entity %s isn't at a node, accessing its coordinates makes no sense" % name)
        print_stack()
        return Vector3i.ZERO

    return _node.coordinates
