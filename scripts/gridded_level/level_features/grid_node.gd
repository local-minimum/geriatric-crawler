extends Node3D
class_name GridNode

@export
var coordinates: Vector3i

@export
var entry_requires_anchor: bool = true

var level: GridLevel

var _anchors: Dictionary[CardinalDirections.CardinalDirection, GridAnchor] = {}

func _ready() -> void:
    if level == null:
        level = GridLevel.find_level_parent(self)

func get_level() -> GridLevel:
    if level == null:
        level = GridLevel.find_level_parent(self)

    return level
#region Events
var _events: Array[GridEvent]
var _events_inited: bool = false

func _init_events() -> void:
    if _events_inited:
        return

    for event: GridEvent in find_children("", "GridEvent"):
        _events.append(event)

func _entry_blocking_events(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    wanted_anchor: CardinalDirections.CardinalDirection,
) -> bool:
    _init_events()
    return _events.any(
        func (evt: GridEvent) -> bool:
            return evt.blocks_entry_translation(
                entity,
                from,
                move_direction,
                wanted_anchor,
            )
    )

func _exit_blocking_events(move_direction: CardinalDirections.CardinalDirection) -> bool:
    _init_events()
    return _events.any(
        func (evt: GridEvent) -> bool:
            return evt.blocks_exit_translation(move_direction)
    )

func any_event_blocks_anchorage(_entity: GridEntity, side: CardinalDirections.CardinalDirection) -> bool:
    return _events.any(
        func (evt: GridEvent) -> bool:
            return evt.side_blocked(side)
    )

func triggering_events(
    entity: GridEntity,
    from_node: GridNode,
    from_side: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> Array[GridEvent]:
    return _events.filter(
        func (evt: GridEvent) -> bool:
            return evt.should_trigger(
                entity,
                from_node,
                from_side,
                to_side,
            )
    )
#endregion Events

#region Anchor
var _anchords_inited: bool

func _init_anchors() -> void:
    if _anchords_inited: return

    for side: GridNodeSide in find_children("", "GridNodeSide"):
        GridNodeSide.set_direction_from_rotation(side)

        if side.anchor == null:
            continue

        if _anchors.has(side.direction):
            if _anchors[side.direction] != side.anchor:
                push_warning(
                    "Node %s has duplicate anchors in the %s direction, skipping %s (for %s)" % [
                        name,
                        CardinalDirections.name(side.direction),
                        side,
                        _anchors[side.direction]],
                )
            continue

        _anchors[side.direction] = side.anchor

    for dir: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        if _anchors.has(dir):
            continue

        var n: GridNode = neighbour(dir)

        if n == null:
            continue

        for n_side: GridNodeSide in n.find_children("", "GridNodeSide"):
            if n_side.negative_anchor == null:
                continue

            if n_side.negative_anchor.direction == dir:
                _anchors[dir] = n_side.negative_anchor

    _anchords_inited = true

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

func get_grid_anchor(direction: CardinalDirections.CardinalDirection) -> GridAnchor:
    if _anchors.has(direction):
        return _anchors[direction]

    _init_anchors()

    if _anchors.has(direction):
        return _anchors[direction]

    return null

## Returns global position of node center
func get_center_pos() -> Vector3:
    return global_position + Vector3.UP * level.node_size * 0.5
#endregion Anchor

#region Navigation
## Gives the neighbour in a direction, disregarding walls and obstructions
func neighbour(direction: CardinalDirections.CardinalDirection) -> GridNode:
    var _level: GridLevel = get_level()
    if _level == null:
        push_error("Node at %s not part of a level" % coordinates)
        return null

    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates, direction)

    if _level.has_grid_node(neighbour_coords):
        return _level.get_grid_node(neighbour_coords)

    return null

func may_enter(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    anchor_direction: CardinalDirections.CardinalDirection,
    ignore_require_anchor: bool = false,
) -> bool:
    if _entry_blocking_events(entity, from, move_direction, anchor_direction):
        print_debug("Cannot enter moving %s because of events" % CardinalDirections.name(move_direction))
        return false

    var entry_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(move_direction)
    var entry_anchor: GridAnchor = get_grid_anchor(entry_direction)

    if entry_requires_anchor && !ignore_require_anchor && !(entity.falling() && move_direction == CardinalDirections.CardinalDirection.DOWN):
        var down_anchor: GridAnchor = get_grid_anchor(anchor_direction)
        if down_anchor == null || !down_anchor.can_anchor(entity):
            if down_anchor == null:
                print_debug("Refused entry anchor in %s missing" % CardinalDirections.name(move_direction))
            else:
                print_debug("Refused entry, %s can't be anchored to" % entry_anchor.name)
            return false

    if entry_anchor != null && !entry_anchor.pass_through_on_refuse:
        print_debug("Cannot enter %s becuase it has an anchor %s of %s blocking (%s)" % [
            name, entry_anchor.name, entry_anchor.get_parent().name, CardinalDirections.name(entry_direction)])
        return false

    return true

func may_exit(entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    if _exit_blocking_events(move_direction):
        print_debug("Cannot exit %s moving %s because of events" % [name, CardinalDirections.name(move_direction)])
        return false

    var anchor: GridAnchor = get_grid_anchor(move_direction)

    if anchor == null:
        return true

    print_debug("%s is at %s" % [entity.name, entity.coordinates()])

    if anchor.can_anchor(entity):
        print_debug("Cannot exit %s from %s because we could anchor on %s" % [CardinalDirections.name(move_direction), name, anchor.name])
        return false

    if anchor.pass_through_on_refuse:
        return true

    print_debug("Cannot exit %s from %s because anchor %s" % [CardinalDirections.name(move_direction), name, anchor.name])
    return false

func may_transit(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return may_enter(entity, from, move_direction, entity.down, true) && may_exit(entity, exit_direction)

static func find_node_parent(current: Node, inclusive: bool = true) ->  GridNode:
    if inclusive && current is GridNode:
        return current as GridNode

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridNode:
        return parent as GridNode

    return find_node_parent(parent, false)
#endregion Navigation
