extends Node3D
class_name GridNodeSide

@export var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export var infer_direction_from_rotation: bool = true

@export var anchor: GridAnchor

@export var negative_anchor: GridAnchor

@export var illosory: bool

func is_two_sided() -> bool:
    return negative_anchor != null

func _ready() -> void:
    set_direction_from_rotation(self)

var _parent_node: GridNode
var _inverse_parent_node: GridNode

func get_side_parent_grid_node() -> GridNode:
    if _parent_node == null:
        _parent_node = GridNode.find_node_parent(self, false)
    return _parent_node

func _get_inverse_parent_node() -> GridNode:
    var parent_node: GridNode = get_side_parent_grid_node()
    if parent_node == null:
        push_warning("%s doesn't have a node parent" % name)
        print_tree()
        return null

    _inverse_parent_node = parent_node.neighbour(direction)

    return _inverse_parent_node

func get_grid_node(value: GridAnchor) -> GridNode:
    if value == anchor:
        return get_side_parent_grid_node()
    elif value == negative_anchor && negative_anchor != null:
        return _get_inverse_parent_node()

    push_error("%s of %s is not an anchor of %s" % [value.name, value.get_parent().name, name])
    print_stack()
    return null

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
    if !node_side.infer_direction_from_rotation || !CardinalDirections.is_planar_cardinal(node_side.direction):
        return

    node_side.direction = CardinalDirections.node_planar_rotation_to_direction(node_side)

    if node_side.anchor != null:
        node_side.anchor.direction = node_side.direction

    if node_side.negative_anchor != null:
        node_side.negative_anchor.direction = CardinalDirections.invert(node_side.direction)

static func get_node_side(node: GridNode, side_direction: CardinalDirections.CardinalDirection) -> GridNodeSide:
    if node == null:
        push_warning("Calling to get a node side of null element")
        print_stack()
        return null

    for side: GridNodeSide in node.find_children("", "GridNodeSide"):
        if side.direction == side_direction:
            return side

    return null
