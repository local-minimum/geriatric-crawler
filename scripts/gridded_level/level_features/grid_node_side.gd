extends Node3D
class_name GridNodeSide

@export
var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export
var infer_direction_from_rotation: bool

@export
var anchor: GridAnchor

@export
var negative_anchor: GridAnchor

func is_two_sided() -> bool:
    return negative_anchor != null

func _ready() -> void:
    set_direction_from_rotation(self)

static func find_node_side_parent(current: Node, inclusive: bool = true) -> GridNodeSide:
    if inclusive && current is GridNodeSide:
        return current as GridNodeSide

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridNodeSide:
        return parent as GridNodeSide

    return find_node_side_parent(parent, false)

static func set_direction_from_rotation(node_side: GridNodeSide) -> void:
    if !node_side.infer_direction_from_rotation:
        return

    node_side.direction = CardinalDirections.node_planar_rotation_to_direction(node_side)

    if node_side.anchor != null:
        node_side.anchor.direction = node_side.anchor.direction

    if node_side.negative_anchor != null:
        node_side.negative_anchor.direction = CardinalDirections.invert(node_side.direction)
