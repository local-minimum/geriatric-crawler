extends Node3D
class_name GridLevel

@export
var nodeSize: Vector3 = Vector3(3, 3, 3)

@export
var nodeSpacing: Vector3 = Vector3.ZERO

var _nodes: Dictionary[Vector3i, GridNode] = {}

func _ready() -> void:
    _sync_nodes()

    if _nodes.size() == 0:
        push_warning("Level %s is empty" % name)

func get_grid_node(coordinates: Vector3i) -> GridNode:
    if _nodes.has(coordinates):
        return _nodes[coordinates]

    push_warning("No node at %s" % coordinates)
    print_stack()

    return null

func has_grid_node(coordinates: Vector3i) -> bool:
    return _nodes.has(coordinates)

func _sync_nodes() -> void:
    _nodes.clear()

    for node: Node in find_children("*", "GridNode"):
        if node is GridNode:
            sync_node(node as GridNode)

func remove_node(node: GridNode) -> bool:
    if _nodes.has(node.coordinates):
        if _nodes[node.coordinates] == node:
            return _nodes.erase(node.coordinates)
        return false
    return false

func _node_anchor_position(coordinates: Vector3i) -> Vector3:
    var pos: Vector3 = Vector3(coordinates)
    return position + (nodeSize + nodeSpacing) * pos

func sync_node(node: GridNode) -> void:
    _nodes[node.coordinates] = node

    node.position = _node_anchor_position(node.coordinates)
