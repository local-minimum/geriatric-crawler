extends Node3D
class_name GridEntity

var node: GridNode

func _ready() -> void:
    node = _find_node_parent(self)

func _find_node_parent(current: Node) ->  GridNode:
    var parent: Node = current.get_parent()

    if parent == null:
        push_warning("Entity %s not a child of a GridNode" % name)
        return null

    if parent is GridNode:
        return parent as GridNode

    return _find_node_parent(parent)

func coordnates() -> Vector3i:
    if node == null:
        push_error("Entity %s isn't at a node, accessing its coordinates makes no sense" % name)
        print_stack()
        return Vector3i.ZERO

    return node.coordinates
