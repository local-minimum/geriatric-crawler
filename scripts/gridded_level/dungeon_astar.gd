extends AStar3D
class_name DungeonAStar

## Custom Astar that doesn't really care much about the coordinates, only does its things from recorded stuff
##
## Pathing doesn't walk or fly through illusory walls ever but can fall through it

var ready: bool:
    get(): return ready

func _compute_cost(from_id: int, to_id: int) -> float:
    if _emergency_moves.has(from_id):
        return 3.0 if _emergency_moves[from_id].has(to_id) else 1.0
    return 1.0

func _estimate_cost(_from_id: int, _end_id: int) -> float:
    return 1.0

const ASTAR_ID: String = "astar_id"

var _node_lookup: Dictionary[int, GridNode]
var _anchor_lookup: Dictionary[int, GridAnchor]
var _lookup: Dictionary[Node3D, int]
var _door_connections: Dictionary[GridDoor, Array]
var _emergency_moves: Dictionary[int, Array]
var _transportation_mode: TransportationMode

var _id: int = 0

# TODO: emergency rescue fall moves doesn't include hitting a 1x1 tower and then push to side because side nodes will not have a down
# TODO: Update crawler code to respect falling in transportaion mode
# TODO: Connect to dynamic adding an anchor
# TODO: Windows that may be crossed by some? It could be that a window is always open and blocks entry from all anchor sides
# TODO: Ramps/Stairs  that are similar to teleporters
# TODO: Teleporters

func initialize_graph(
    level: GridLevel,
    transportation_mode: TransportationMode,
) -> void:
    _transportation_mode = transportation_mode

    var t0: int = Time.get_ticks_msec()

    for from: GridNode in level.nodes():
        _add_grid_node(from)

        for side: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS_AND_NONE:
            if side == CardinalDirections.CardinalDirection.NONE:
                # Falling modes
                if !transportation_mode.has_flag(TransportationMode.FLYING):
                    if !transportation_mode.has_flag(TransportationMode.FALLING):
                        continue

                    match from.has_side(CardinalDirections.CardinalDirection.DOWN):
                        # Free air
                        GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                            var to: GridNode = from.neighbour(CardinalDirections.CardinalDirection.DOWN)
                            if to != null:
                                _add_grid_node(to)
                                connect_points(_lookup[from], _lookup[to], false)

                        # Land
                        GridNode.NodeSideState.SOLID:
                            if transportation_mode.can_walk(CardinalDirections.CardinalDirection.DOWN):
                                var anchor: GridAnchor = from.get_grid_anchor(CardinalDirections.CardinalDirection.DOWN)
                                if anchor != null:
                                    _add_anchor(anchor)
                                    connect_points(_lookup[from], _lookup[anchor], false)
                                else:
                                    # Land to the side
                                    for direction: CardinalDirections.CardinalDirection in CardinalDirections.orthogonals(side):
                                        var to: GridNode = from.neighbour(direction)
                                        if to == null:
                                            continue

                                        var anchor_to: GridAnchor = to.get_grid_anchor(CardinalDirections.CardinalDirection.DOWN)
                                        if anchor_to == null:
                                            continue

                                        match from.has_side(direction):
                                            GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                _add_anchor(anchor_to)
                                                connect_points(_lookup[from], _lookup[anchor_to], false)
                                                _add_emergency_mode(from, anchor_to)

                                            GridNode.NodeSideState.DOOR:
                                                var door: GridDoor = from.get_door(direction)
                                                if door != null:
                                                    _add_anchor(anchor_to)

                                                    if door.lock_state == GridDoor.LockState.OPEN:
                                                        connect_points(_lookup[from], _lookup[anchor_to], false)
                                                        _add_emergency_mode(from, anchor_to)

                                                    _add_door_connection(door, from, anchor_to)

                        # Fall through door
                        GridNode.NodeSideState.DOOR:
                            var door: GridDoor = from.get_door(side)
                            if door != null:
                                var to: GridNode = from.neighbour(CardinalDirections.CardinalDirection.DOWN)
                                if to != null:
                                    _add_grid_node(to)

                                    if _evaluate_and_add_door(door, CardinalDirections.CardinalDirection.NONE, from, to):
                                        connect_points(_lookup[from], _lookup[to], false)

                # Flying modes
                else:
                    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                        # TODO: Lift-off diagonals?
                        var to: GridNode = from.neighbour(direction)

                        match from.has_side(direction):
                            # Fly to neighbouring node
                            GridNode.NodeSideState.NONE:
                                _add_grid_node(to)
                                connect_points(_lookup[from], _lookup[to], false)

                            # Land
                            GridNode.NodeSideState.SOLID:
                                if transportation_mode.can_walk(direction):
                                    var anchor: GridAnchor = from.get_grid_anchor(direction)
                                    if anchor != null:
                                        _add_anchor(anchor)
                                        connect_points(_lookup[from], _lookup[anchor], false)

                            # Fly through doors
                            GridNode.NodeSideState.DOOR:
                                _add_grid_node(to)
                                if _evaluate_and_add_door(from.get_door(direction), CardinalDirections.CardinalDirection.NONE, from, to):
                                    connect_points(_lookup[from], _lookup[to], false)

            else:
                var from_anchor: GridAnchor = from.get_grid_anchor(side)
                if from_anchor == null:
                    continue

                _add_anchor(from_anchor)

                for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                    if direction == side:
                        continue

                    # Start flying or jump into node center
                    elif direction == CardinalDirections.invert(side):
                        if _can_jump(transportation_mode, direction):
                            connect_points(_lookup[from_anchor], _lookup[from], false)

                    # Walk along the current side in some direction
                    else:
                        match from.has_side(direction):
                            # Transition to another node
                            GridNode.NodeSideState.NONE:
                                var to: GridNode = from.neighbour(direction)
                                if to != null:
                                    var to_anchor: GridAnchor = to.get_grid_anchor(side)
                                    var final: GridNode = to.neighbour(side)

                                    match to.has_side(side):
                                        GridNode.NodeSideState.SOLID:
                                            # Normal walk along the side
                                            if to_anchor != null:
                                                # We presumably were on this side already but lets double check
                                                if transportation_mode.can_walk(side):
                                                    _add_anchor(to_anchor)
                                                    connect_points(_lookup[from_anchor], _lookup[to_anchor], false)
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                connect_points(_lookup[from_anchor], _lookup[to], false)

                                        GridNode.NodeSideState.NONE:
                                            # Check and do outer corner walk
                                            if transportation_mode.can_walk(side):
                                                var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                                if transportation_mode.can_walk(new_anchor_direction):
                                                    if final != null:
                                                        var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                                        match final.has_side(new_anchor_direction):
                                                            GridNode.NodeSideState.SOLID:
                                                                if final_anchor != null:
                                                                    _add_anchor(final_anchor)
                                                                    connect_points(_lookup[from_anchor], _lookup[final_anchor], false)
                                                                elif _can_jump(transportation_mode, direction):
                                                                    _add_grid_node(to)
                                                                    connect_points(_lookup[from_anchor], _lookup[to], false)
                                                            GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                                if _can_jump(transportation_mode, direction):
                                                                    _add_grid_node(to)
                                                                    connect_points(_lookup[from_anchor], _lookup[to], false)
                                                    elif _can_jump(transportation_mode, direction):
                                                        _add_grid_node(to)
                                                        connect_points(_lookup[from_anchor], _lookup[to], false)

                                                # If we cannot walk the outer corner target surface we need to jump
                                                # We need to allow jumping even if final doesn't exist if the entity can fly
                                                # Also down might not be in the direction of side...
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)


                                            # This shouldn't really happen if we were anchored to that side before but...
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                connect_points(_lookup[from_anchor], _lookup[to], false)

                                        GridNode.NodeSideState.DOOR:
                                            # TODO: This doesn't cover outer corner through door!

                                            _add_grid_node(final)
                                            # This is a bit special... Imagine we are on the floor and there's a door in the floor in front of us
                                            # We are not allowed to jump out into the air above it, unless the door is open and allows us to fall through it
                                            # But this only adds the connection to jumping out above it. The falling bit is another connection
                                            if side == CardinalDirections.CardinalDirection.DOWN && transportation_mode.has_flag(TransportationMode.FALLING):
                                                if _evaluate_and_add_door(
                                                    to.get_door(side),
                                                    CardinalDirections.CardinalDirection.NONE,
                                                    from_anchor,
                                                    to,
                                                ):
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)
                                            # We really don't care that "down" is a door, if we can fly we can fly
                                            elif transportation_mode.has_flag(TransportationMode.FLYING):
                                                connect_points(_lookup[from_anchor], _lookup[to], false)

                            GridNode.NodeSideState.SOLID:
                                var anchor: GridAnchor = from.get_grid_anchor(direction)
                                if anchor != null && transportation_mode.can_walk(direction):
                                    _add_anchor(anchor)
                                    connect_points(_lookup[from_anchor], _lookup[anchor], false)

                            GridNode.NodeSideState.DOOR:
                                var door: GridDoor = from.get_door(direction)
                                var to: GridNode = from.neighbour(direction)
                                if to != null:
                                    var to_anchor: GridAnchor = to.get_grid_anchor(side)
                                    var final: GridNode = to.neighbour(side)

                                    match to.has_side(side):
                                        GridNode.NodeSideState.SOLID:
                                            # Normal walk along the side
                                            if to_anchor != null:
                                                # We presumably were on this side already but lets double check
                                                if transportation_mode.can_walk(side):
                                                    _add_anchor(to_anchor)
                                                    if _evaluate_and_add_door(door, side, from_anchor, to_anchor):
                                                        connect_points(_lookup[from_anchor], _lookup[to_anchor], false)
                                                elif _can_jump(transportation_mode, direction) :
                                                    _add_grid_node(to)
                                                    if _evaluate_and_add_door(door, side, from_anchor, to):
                                                        connect_points(_lookup[from_anchor], _lookup[to], false)
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)

                                        GridNode.NodeSideState.NONE:
                                            # Check and do outer corner walk
                                            if transportation_mode.can_walk(side):
                                                var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                                if transportation_mode.can_walk(new_anchor_direction) && final != null:
                                                    var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                                    match to.has_side(new_anchor_direction):
                                                        GridNode.NodeSideState.SOLID:
                                                            if final_anchor != null:
                                                                _add_anchor(final_anchor)
                                                                if _evaluate_and_add_door(door, side, from_anchor, final_anchor):
                                                                    connect_points(_lookup[from_anchor], _lookup[final_anchor], false)
                                                                continue
                                                            elif _can_jump(transportation_mode, direction):
                                                                _add_grid_node(to)
                                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                                    connect_points(_lookup[from_anchor], _lookup[to], false)
                                                        GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                            if _can_jump(transportation_mode, direction):
                                                                _add_grid_node(to)
                                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                                    connect_points(_lookup[from_anchor], _lookup[to], false)

                                                # If we cannot walk the outer corner target surface we need to jump
                                                # We need to allow jumping even if final doesn't exist if the entity can fly
                                                # Also down might not be in the direction of side...
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    if _evaluate_and_add_door(door, side, from_anchor, to):
                                                        connect_points(_lookup[from_anchor], _lookup[to], false)

                                            # This shouldn't really happen if we were anchored to that side before but...
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)

                                        GridNode.NodeSideState.DOOR:
                                            _add_grid_node(to)

                                            # This is a bit special... Imagine we are on the floor and there's a door in the floor in front of us
                                            # We are not allowed to jump out into the air above it, unless the door is open and allows us to fall through it
                                            # But this only adds the connection to jumping out above it. The falling bit is another connection
                                            if side == CardinalDirections.CardinalDirection.DOWN && transportation_mode.has_flag(TransportationMode.FALLING):
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    if _evaluate_and_add_door(
                                                        to.get_door(side),
                                                        CardinalDirections.CardinalDirection.NONE,
                                                        from_anchor,
                                                        to,
                                                    ):
                                                        connect_points(_lookup[from_anchor], _lookup[to], false)
                                            # We really don't care that "down" is a door, if we can fly we can fly
                                            elif transportation_mode.has_flag(TransportationMode.FLYING):
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to], false)


        if Time.get_ticks_msec() - t0 > 500:
            # TODO: Turn into coroutine a bit smarter
            await from.get_tree().create_timer(0.02).timeout
            t0 = Time.get_ticks_msec()

    if !__SignalBus.on_door_state_chaged.is_connected(_handle_door_state_change) && __SignalBus.on_door_state_chaged.connect(_handle_door_state_change) != OK:
        push_error("Failed to connect door lock state change")

    if !__SignalBus.on_add_anchor.is_connected(_handle_add_anchor) && __SignalBus.on_add_anchor.connect(_handle_add_anchor) != OK:
        push_error("Failed to connect add anchor (to node)")

    ready = true

func _handle_door_state_change(door: GridDoor, from: GridDoor.LockState, to: GridDoor.LockState) -> void:
    if !_door_connections.has(door):
        return

    var connections: Array[Array] = _door_connections[door]
    if from != GridDoor.LockState.OPEN && to == GridDoor.LockState.OPEN:
        for connection: Array[int] in connections:
            connect_points(connection[0], connection[1], false)
    elif from == GridDoor.LockState.OPEN && to != GridDoor.LockState.OPEN:
        for connection: Array[int] in connections:
            disconnect_points(connection[0], connection[1])

func _handle_add_anchor(grid_node: GridNode, anchor: GridAnchor) -> void:
    _add_anchor(anchor)

    for side: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS_AND_NONE:
        if side == anchor.direction:
            if !_transportation_mode.can_walk(side):
                # Add emergency falling stuff
                _add_grid_node(grid_node)

                for neighbour_direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_PLANAR_DIRECTIONS:
                    var neighbour: GridNode = grid_node.neighbour(neighbour_direction)
                    if neighbour == null:
                        continue

                    var neighbour_anchor: GridAnchor = neighbour.get_grid_anchor(CardinalDirections.CardinalDirection.DOWN)
                    if neighbour_anchor != null:
                        continue

                    match grid_node.has_side(neighbour_direction):
                        GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                            _add_anchor(neighbour_anchor)
                            if !are_points_connected(_lookup[grid_node], _lookup[neighbour_anchor], false):
                                connect_points(_lookup[grid_node], _lookup[neighbour_anchor], false)
                                _add_emergency_mode(grid_node, neighbour_anchor)

                        GridNode.NodeSideState.DOOR:
                            _add_anchor(neighbour_anchor)
                            if !are_points_connected(_lookup[grid_node], _lookup[neighbour_anchor], false):
                                if _evaluate_and_add_door(grid_node.get_door(neighbour_direction), CardinalDirections.CardinalDirection.NONE, grid_node, neighbour_anchor):
                                    connect_points(_lookup[grid_node], _lookup[neighbour_anchor], false)
                                _add_emergency_mode(grid_node, neighbour_anchor)
                continue

            # Add connections out of new anchor!
            for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                if direction == side:
                    continue

                elif direction == CardinalDirections.invert(side):
                    # Into node center logic
                    if _can_jump(_transportation_mode, direction):
                        _add_grid_node(grid_node)
                        # Only flying entities can land on not down, and non-flying entities cannot jump up
                        # So only flying are bidirectional
                        connect_points(_lookup[anchor], _lookup[grid_node], _transportation_mode.has_flag(TransportationMode.FLYING))

                    # Resqueue falling (separate if because flying could potentially fall)
                    if side == CardinalDirections.CardinalDirection.DOWN && _transportation_mode.has_flag(TransportationMode.FALLING):
                        for neighbour_direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_PLANAR_DIRECTIONS:
                            var neighbour: GridNode = grid_node.neighbour(neighbour_direction)
                            if neighbour == null:
                                continue

                            match neighbour.has_side(CardinalDirections.invert(neighbour_direction)):
                                GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                    _add_grid_node(neighbour)
                                    connect_points(_lookup[neighbour], _lookup[anchor], false)
                                    _add_emergency_mode(neighbour, anchor)

                                GridNode.NodeSideState.DOOR:
                                    _add_grid_node(neighbour)
                                    if _evaluate_and_add_door(
                                        neighbour.get_door(CardinalDirections.invert(neighbour_direction)),
                                        CardinalDirections.CardinalDirection.NONE,
                                        neighbour,
                                        anchor
                                    ):
                                        connect_points(_lookup[neighbour], _lookup[anchor], false)

                                    _add_emergency_mode(neighbour, anchor)

                    continue

                match grid_node.has_side(direction):
                    GridNode.NodeSideState.SOLID:
                        var to_anchor: GridAnchor = grid_node.get_grid_anchor(direction)
                        if _transportation_mode.can_walk(direction) && to_anchor != null:
                            _add_anchor(to_anchor)
                            # Note: This is bidirectional
                            connect_points(_lookup[anchor], _lookup[to_anchor])

                        elif _can_jump(_transportation_mode, direction):
                            _add_grid_node(grid_node)
                            # Only flying entities can land on not down, and non-flying entities cannot jump up
                            # So only flying are bidirectional
                            connect_points(_lookup[anchor], _lookup[grid_node], _transportation_mode.has_flag(TransportationMode.FLYING))

                        elif side == CardinalDirections.CardinalDirection.DOWN && _transportation_mode.has_flag(TransportationMode.FALLING):
                            # Falling entities can land
                            _add_grid_node(grid_node)
                            # This isn't bidirectional because it's only non flying, but falling entities that are landing on this surface
                            connect_points(_lookup[grid_node], _lookup[anchor], false)

                    GridNode.NodeSideState.NONE:
                        var neighbour: GridNode = grid_node.neighbour(direction)
                        if neighbour != null:
                            var final: GridNode = neighbour.neighbour(side)
                            var neighbour_anchor: GridAnchor = neighbour.get_grid_anchor(side)
                            match neighbour.has_side(side):
                                GridNode.NodeSideState.SOLID:
                                    if neighbour_anchor != null && _transportation_mode.can_walk(side):
                                        _add_anchor(neighbour_anchor)
                                        # Should be bidirectional
                                        connect_points(_lookup[anchor], _lookup[neighbour_anchor])
                                    elif _can_jump(_transportation_mode, direction):
                                        connect_points(_lookup[anchor], _lookup[neighbour], false)

                                GridNode.NodeSideState.NONE:
                                    var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                    if _transportation_mode.can_walk(new_anchor_direction) && final != null:
                                            var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                            match final.has_side(new_anchor_direction):
                                                GridNode.NodeSideState.SOLID:
                                                    if final_anchor != null:
                                                        _add_anchor(final_anchor)
                                                        connect_points(_lookup[anchor], _lookup[final_anchor])
                                                    elif _can_jump(_transportation_mode, direction):
                                                        _add_grid_node(neighbour)
                                                        connect_points(_lookup[anchor], _lookup[neighbour], false)
                                                GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                    if _can_jump(_transportation_mode, direction):
                                                        _add_grid_node(neighbour)
                                                        connect_points(_lookup[anchor], _lookup[neighbour], false)
                                    elif _can_jump(_transportation_mode, direction):
                                        _add_grid_node(neighbour)
                                        connect_points(_lookup[anchor], _lookup[neighbour], false)

                                GridNode.NodeSideState.DOOR:
                                    var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                    if _transportation_mode.can_walk(new_anchor_direction) && final != null:
                                        var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                        match final.has_side(new_anchor_direction):
                                            GridNode.NodeSideState.SOLID:
                                                if final_anchor != null:
                                                    _add_anchor(final_anchor)
                                                    if _evaluate_and_add_door(neighbour.get_door(side), side, anchor, final_anchor):
                                                        connect_points(_lookup[anchor], _lookup[final_anchor])
                                                elif _can_jump(_transportation_mode, direction):
                                                    _add_grid_node(neighbour)
                                                    connect_points(_lookup[anchor], _lookup[neighbour], false)
                                            GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                if _can_jump(_transportation_mode, direction):
                                                    _add_grid_node(neighbour)
                                                    connect_points(_lookup[anchor], _lookup[neighbour], false)
                                    elif _can_jump(_transportation_mode, direction):
                                        _add_grid_node(neighbour)
                                        connect_points(_lookup[anchor], _lookup[neighbour], false)


        # Remove previous connections blocked by anchor
        var from_id: int = -1
        var from_anchor: GridAnchor
        if side == CardinalDirections.CardinalDirection.NONE:
            if !_lookup.has(grid_node):
                continue

            from_id = _lookup[grid_node]

        else:
            from_anchor = grid_node.get_grid_anchor(side)
            if from_anchor == null || !_lookup.has(from_anchor):
                continue

            from_id = _lookup[from_anchor]

        for to_id: int in get_point_connections(from_id):
            var to_node: GridNode
            if _node_lookup.has(to_id):
                to_node = _node_lookup[to_id]
            elif _anchor_lookup.has(to_id):
                to_node = _anchor_lookup[to_id].get_grid_node()
            else:
                continue

            if to_node == null:
                continue

            if grid_node.neighbour(anchor.direction) == to_node:
                disconnect_points(from_id, to_id)

                if are_points_connected(to_id, from_id, false):
                    disconnect_points(from_id, to_id)
                    # If we need to add new connections on the negative side, then we do that when it gets an anchor

func _can_jump(transportation_mode: TransportationMode, direction: CardinalDirections.CardinalDirection) -> bool:
    return transportation_mode.has_flag(TransportationMode.FLYING) || transportation_mode.has_flag(TransportationMode.FALLING) && direction != CardinalDirections.CardinalDirection.UP

func _evaluate_and_add_door(door: GridDoor, entry_down: CardinalDirections.CardinalDirection, from: Node3D, to: Node3D) -> bool:
    if door == null:
        return false

    _add_door_connection(door, from, to)

    return door.lock_state == GridDoor.LockState.OPEN && !door.block_traversal_anchor_sides.has(entry_down)


func _add_door_connection(door: GridDoor, from: Node3D, to: Node3D) -> void:
    var connection: Array[int] = [_lookup[from], _lookup[to]]
    if _door_connections.has(door):
        _door_connections[door].append(connection)
    else:
        _door_connections[door] = [connection] as Array[Array]

func _add_emergency_mode(from: Node3D, to: Node3D) -> void:
    if _emergency_moves.has(_lookup[from]):
        _emergency_moves[_lookup[from]].append(_lookup[to])
    else:
        _emergency_moves[_lookup[from]] = [_lookup[to]] as Array[int]

func _add_grid_node(grid_node: GridNode) -> void:
    if grid_node.has_meta(ASTAR_ID):
        return

    add_point(_id, grid_node.coordinates)
    grid_node.set_meta(ASTAR_ID, _id)
    _node_lookup[_id] = grid_node
    _lookup[grid_node] = _id
    _id += 1

func _add_anchor(anchor: GridAnchor) -> void:
    if anchor.has_meta(ASTAR_ID):
        return

    var point: Vector3 = anchor.get_grid_node().coordinates
    point += CardinalDirections.direction_to_vector(anchor.direction) * 0.1
    add_point(_id, point)
    anchor.set_meta(ASTAR_ID, _id)
    _anchor_lookup[_id] = anchor
    _lookup[anchor] = _id
    _id += 1
