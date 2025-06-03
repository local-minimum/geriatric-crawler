extends Node3D
class_name GridNode

@export
var coordinates: Vector3i

@export
var entry_requires_anchor: bool

var level: GridLevel

var _anchors_inited: bool = false
var _anchors: Dictionary[CardinalDirections.CardinalDirection, GridAnchor] = {}

func _ready() -> void:
    if level == null:
        level = GridLevel.find_level_parent(self)

    if !_anchors_inited:
        _init_anchors()

func get_level() -> GridLevel:
    if level == null:
        level = GridLevel.find_level_parent(self)

    return level

#
# Anchors
#

func _init_anchors() -> void:
    for side: GridNodeSide in find_children("", "GridNodeSide"):
        if side.anchor == null:
            continue

        if _anchors.has(side.direction):
            push_warning(
                "Node %s has duplicate anchors in the %s direction, skipping %s" % [name, side.direction, side],
            )
            continue

        _anchors[side.direction] = side.anchor

    for dir: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        if _anchors.has(dir):
            continue

        var n: GridNode = neighbour(dir)

        if n == null:
            continue

        var inverse: CardinalDirections.CardinalDirection = CardinalDirections.invert(dir)
        for n_side: GridNodeSide in n.find_children("", "GridNodeSide"):
            if n_side.direction != inverse:
                continue

            if n_side.negative_anchor != null:
                _anchors[dir] = n_side.negative_anchor

    _anchors_inited = true


func remove_anchor(anchor: GridAnchor) -> bool:
    if !_anchors.has(anchor.direction):
        push_warning("Node %s has no anchor in the %s direction" % [name, anchor.direction])
        return false

    if _anchors[anchor.direction] == anchor:
        return _anchors.erase(anchor.direction)

    push_warning(
        "Node %s has another anchor %s in the %s direction" % [name, _anchors[anchor.direction], anchor.direction],
    )

    return false

func add_anchor(anchor: GridAnchor) -> bool:
    if !_anchors_inited:
        _init_anchors()

    if _anchors.has(anchor.direction):
        push_warning(
            "Node %s already has an anchor %s in the %s direction - ignoring" % [name, _anchors[anchor.direction], anchor.direction],
        )

        return _anchors[anchor.direction] == anchor

    var success: bool = _anchors.set(anchor.direction, anchor)
    if (success):
        anchor.reparent(self, true)

    return success

func get_anchor(direction: CardinalDirections.CardinalDirection) -> GridAnchor:
    if !_anchors_inited:
        _init_anchors()

    if _anchors.has(direction):
        return _anchors[direction]
    return null

func get_center_pos() -> Vector3:
    return global_position + Vector3.UP * level.node_size * 0.5

#
# Navigation
#

func neighbour(direction: CardinalDirections.CardinalDirection) -> GridNode:
    if level == null:
        push_error("Node at %s not part of a level" % coordinates)
        return null

    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates, direction)

    if level.has_grid_node(neighbour_coords):
        return level.get_grid_node(neighbour_coords)

    return null

func may_enter(entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    var anchor: GridAnchor = get_anchor(CardinalDirections.invert(move_direction))

    if entry_requires_anchor:
        var down_anchor: GridAnchor = get_anchor(entity.down)
        if down_anchor == null || !down_anchor.can_anchor(entity):
            return false

    return anchor == null || anchor.pass_through_reverse

func may_exit(entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    var anchor: GridAnchor = get_anchor(move_direction)

    if anchor == null:
        return true

    if anchor.can_anchor(entity):
        return false

    return anchor.pass_through_on_refuse

func may_transit(
    entity: GridEntity,
    move_direction: CardinalDirections.CardinalDirection,
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return may_enter(entity, move_direction) && may_exit(entity, exit_direction)

static func find_node_parent(current: Node, inclusive: bool = true) ->  GridNode:
    if inclusive && current is GridNode:
        return current as GridNode

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridNode:
        return parent as GridNode

    return find_node_parent(parent, false)
