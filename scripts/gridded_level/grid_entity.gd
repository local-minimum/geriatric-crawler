extends Node3D
class_name GridEntity

var node: GridNode

@export
var look_direction: CardinalDirections.CardinalDirection

@export
var down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

func _ready() -> void:
    node = _find_node_parent(self)
    orient()

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

func attempt_move(move_direction: CardinalDirections.CardinalDirection) -> bool:
    if node == null:
        push_error("Player %s not inside dungeon")
        return false

    if node.may_exit(self, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour != null && neighbour.may_enter(self, move_direction):
            position = neighbour.position
            node = neighbour

            return true
    return false

func attempt_rotate(clockwise: bool) -> bool:
    if clockwise:
        look_direction = CardinalDirections.yaw_cw(look_direction, down)
    else:
        look_direction = CardinalDirections.yaw_ccw(look_direction, down)
    orient()
    return true

func orient() -> void:
    look_at(
        position + Vector3(CardinalDirections.direction_to_vector(look_direction)),
        CardinalDirections.direction_to_vector(CardinalDirections.invert(down)))
