extends Node3D
class_name GridNode

@export
var coordinates: Vector3i

var level: GridLevel

func _ready() -> void:
    level = _find_level_parent(self)

func _find_level_parent(node: Node) -> GridLevel:
    var parent: Node = node.get_parent()

    if parent == null:
        push_warning("Node at %s not a child of a GridLevel" % coordinates)
        return null

    if parent is GridLevel:
        return parent as GridLevel

    return _find_level_parent(parent)

func may_enter(_entity: GridEntity, _move_direction: CardinalDirections.CardinalDirection) -> bool:
    return true

func may_exit(_entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    if (move_direction == CardinalDirections.CardinalDirection.DOWN):
        return false
    return true

func neighbour(direction: CardinalDirections.CardinalDirection) -> GridNode:
    if level == null:
        push_error("Node at %s not part of a level" % coordinates)
        return null

    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates, direction)

    if level.has_grid_node(neighbour_coords):
        return level.get_grid_node(neighbour_coords)

    return null
