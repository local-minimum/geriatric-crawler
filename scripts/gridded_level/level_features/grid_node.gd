extends Node3D
class_name GridNode

@export var coordinates: Vector3i

@export var entry_requires_anchor: bool = true

var level: GridLevel

var _anchors: Dictionary[CardinalDirections.CardinalDirection, GridAnchor] = {}
var _sides: Dictionary[CardinalDirections.CardinalDirection, GridNodeSide] = {}
var _doors: Dictionary[CardinalDirections.CardinalDirection, GridDoor] = {}

func _ready() -> void:
    if level == null:
        level = GridLevel.find_level_parent(self)

func get_level() -> GridLevel:
    if level == null:
        level = GridLevel.find_level_parent(self)

    return level

var _doors_inited: bool
func _init_doors() -> void:
    if _doors_inited:
        return

    _doors_inited = true
    _doors.clear()
    for door: GridDoor in find_children("", "GridDoor"):
        _doors[door.get_side()] = door

    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        if _doors.has(direction):
            continue

        var n: GridNode = neighbour(direction)
        if n == null:
            continue
        n._init_doors()

        var ndoor: GridDoor = n.get_door(CardinalDirections.invert(direction))
        if ndoor != null:
            _doors[direction] = ndoor


func get_door(direction: CardinalDirections.CardinalDirection) -> GridDoor:
    _init_doors()
    return _doors.get(direction)

var _teleporter_inited: bool
var _teleporters: Dictionary[CardinalDirections.CardinalDirection, GridTeleporter]
func get_active_teleporter(
    direction: CardinalDirections.CardinalDirection,
    for_player: bool = true,
    omit_by_direction: bool = false,
    omit_if_active_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NONE,
) -> GridTeleporter:
    if !_teleporter_inited:
        _teleporter_inited = true
        for teleporter: GridTeleporter in find_children("", "GridTeleporter"):
            _teleporters[teleporter.anchor_direction] = teleporter

    var _valid_check: Callable = func (tele: GridTeleporter) -> bool:
        if !tele.can_teleport || !tele.active_for_side(direction) || omit_by_direction && tele.active_for_side(omit_if_active_direction):
            return false

        if for_player:
            return tele.teleports_player
        return tele.teleports_non_players

    if _teleporters.has(direction):
        var teleport: GridTeleporter = _teleporters.get(direction)
        if _valid_check.call(teleport):
            return teleport

    var alternatives: Array = _teleporters.values()
    var idx: int = alternatives.find_custom(_valid_check)
    if idx < 0:
        return null
    return alternatives[idx]

var _ramps_inited: bool
var _ramps: Dictionary[CardinalDirections.CardinalDirection, GridRamp]
func get_ramp(direction: CardinalDirections.CardinalDirection) -> GridRamp:
    if !_ramps_inited:
        _ramps_inited = true
        for ramp: GridRamp in find_children("", "GridRamp"):
            _ramps[CardinalDirections.invert(ramp.up_direction)] = ramp
            _ramps[ramp.upper_exit_direction] = ramp

    return _ramps.get(direction)

enum NodeSideState { NONE, SOLID, ILLUSORY, DOOR }
func has_side(direction: CardinalDirections.CardinalDirection) -> NodeSideState:
    _init_sides_and_anchors()
    _init_doors()

    if _doors.has(direction):
        return NodeSideState.DOOR

    if _sides.has(direction):
        # print_debug("Node %s has side %s" % [coordinates, CardinalDirections.name(direction)])
        return NodeSideState.ILLUSORY if _sides[direction].illosory else NodeSideState.SOLID

    var neighbour_node: GridNode = neighbour(direction)
    if neighbour_node == null:
        return NodeSideState.NONE

    var inverted: CardinalDirections.CardinalDirection = CardinalDirections.invert(direction)
    if neighbour_node._sides.has(inverted):
        # print_debug("Node %s has side %s from neighbour %s" % [coordinates, CardinalDirections.name(direction), neighbour_node])
        return NodeSideState.ILLUSORY if neighbour_node._sides[inverted].illosory else NodeSideState.SOLID

    return NodeSideState.NONE

func _is_illusory_side(direction: CardinalDirections.CardinalDirection) -> bool:
    return _sides.has(direction) && _sides[direction].illosory

func illusory_sides() -> Array[GridNodeSide]:
    _init_sides_and_anchors()
    return _sides.values().filter(func (side: GridNodeSide) -> bool: return side.illosory)

#region Events
var _events: Array[GridEvent]
var _events_inited: bool = false

func _init_events() -> void:
    if _events_inited:
        return

    for event: GridEvent in find_children("", "GridEvent"):
        _events.append(event)


func add_grid_event(event: GridEvent) -> void:
    if _events.has(event):
        return
    _events.append(event)

func remove_grid_event(event: GridEvent) -> void:
    _events.erase(event)

func _entry_blocking_events(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    wanted_anchor: CardinalDirections.CardinalDirection,
    silent: bool = false,
) -> bool:
    _init_events()
    return _events.any(
        func (evt: GridEvent) -> bool:
            return evt.blocks_entry_translation(
                entity,
                from,
                move_direction,
                wanted_anchor,
                silent,
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
            return evt.anchorage_blocked(side)
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

func _init_sides_and_anchors() -> void:
    if _anchords_inited: return

    for side: GridNodeSide in find_children("", "GridNodeSide"):
        GridNodeSide.set_direction_from_rotation(side)

        _sides[side.direction] = side

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
    _init_sides_and_anchors()

    if _anchors.has(anchor.direction):
        push_warning(
            "Node %s already has an anchor %s in the %s direction - ignoring" % [name, _anchors[anchor.direction], anchor.direction],
        )

        return _anchors[anchor.direction] == anchor

    var old_anchor: GridAnchor = _anchors.get(anchor.direction)
    var success: bool = _anchors.set(anchor.direction, anchor)
    if (success):
        if !_sides.has(anchor.direction):
            var side: GridNodeSide = GridNodeSide.new()
            side.infer_direction_from_rotation = false
            side.anchor = anchor
            side.direction = anchor.direction
            _sides[anchor.direction] = side

            side.add_child(anchor)
            self.add_child(side)
        else:
            if !_sides[anchor.direction].update_anchor(anchor):
                if old_anchor == null:
                    @warning_ignore_start("return_value_discarded")
                    _anchors.erase(anchor.direction)
                    @warning_ignore_restore("return_value_discarded")
                else:
                    _anchors[anchor.direction] = old_anchor
                return false

            self.add_child(anchor)

        __SignalBus.on_add_anchor.emit(self, anchor)

    return success

func get_grid_anchor(direction: CardinalDirections.CardinalDirection) -> GridAnchor:
    if _anchors.has(direction):
        return _anchors[direction]

    _init_sides_and_anchors()

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

    return _level.get_grid_node(neighbour_coords)

func may_enter(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    anchor_direction: CardinalDirections.CardinalDirection,
    ignore_require_anchor: bool = false,
    force_respect_illuory: bool = false,
    silent: bool = false,
) -> bool:
    if _entry_blocking_events(entity, from, move_direction, anchor_direction, silent):
        if !silent:
            print_debug("Cannot enter moving %s because of events" % CardinalDirections.name(move_direction))
        return false

    var entry_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(move_direction)

    # TODO: Regulate if some entity may treat illusory sides as a blocker
    var entry_anchor: GridAnchor = get_grid_anchor(entry_direction) if !_is_illusory_side(entry_direction) || force_respect_illuory else null

    if entry_requires_anchor && !ignore_require_anchor && !(entity.falling() && move_direction == CardinalDirections.CardinalDirection.DOWN):
        var down_anchor: GridAnchor = get_grid_anchor(anchor_direction)
        if down_anchor == null || !down_anchor.can_anchor(entity):
            if !silent && down_anchor == null:
                print_debug("Refused entry anchor in %s missing" % CardinalDirections.name(move_direction))
            elif !silent:
                print_debug("Refused entry, %s can't be anchored to" % entry_anchor.name)
            return false

    if entry_anchor != null && !entry_anchor.pass_through_on_refuse:
        if !silent:
            print_debug("Cannot enter %s becuase it has an anchor %s of %s blocking (%s)" % [
                name, entry_anchor.name, entry_anchor.get_parent().name, CardinalDirections.name(entry_direction)])
        return false

    return true

func may_exit(
    entity: GridEntity,
    move_direction: CardinalDirections.CardinalDirection,
    force_respect_illuory: bool = false,
    silent: bool = false,
) -> bool:
    if _exit_blocking_events(move_direction):
        if !silent:
            print_debug("Cannot exit %s moving %s because of events" % [name, CardinalDirections.name(move_direction)])
        return false

    # TODO: Regulate if some entity may treat illusory sides and blockers
    var anchor: GridAnchor = get_grid_anchor(move_direction) if !_is_illusory_side(move_direction) || force_respect_illuory else null

    if anchor == null:
        return true

    if anchor.can_anchor(entity):
        if !silent:
            print_debug("Cannot exit %s from %s because we could anchor on %s" % [CardinalDirections.name(move_direction), name, anchor.name])
        return false

    if anchor.pass_through_on_refuse:
        return true

    if !silent:
        print_debug("Cannot exit %s from %s because anchor %s" % [CardinalDirections.name(move_direction), name, anchor.name])

    return false

func may_transit(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    exit_direction: CardinalDirections.CardinalDirection,
    silent: bool = false,
) -> bool:
    return may_enter(entity, from, move_direction, entity.down, true, false, silent) && may_exit(entity, exit_direction, false, silent)

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
