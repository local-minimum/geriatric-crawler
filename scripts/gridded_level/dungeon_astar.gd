extends AStar3D
class_name DungeonAStar

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
var _side_lookup: Dictionary[int, GridAnchor]
var _lookup: Dictionary[Node3D, int]
var _door_connections: Dictionary[GridDoor, Array]
var _emergency_moves: Dictionary[int, Array]

var _id: int = 0

# TODO: Connect to door states
# TODO: Connect to passing through illusory??
# TODO: Connect to dynamic adding an anchor
# TODO: Windows that may be crossed by some? It could be that a window is always open and blocks entry from all anchor sides
# TODO: Ramps/Stairs  that are similar to teleporters
# TODO: Teleporters

func initialize_graph(
    level: GridLevel,
    transportation_mode: TransportationMode,
) -> void:
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
                                connect_points(_lookup[from], _lookup[to])

                        # Land
                        GridNode.NodeSideState.SOLID:
                            if transportation_mode.can_walk(CardinalDirections.CardinalDirection.DOWN):
                                var anchor: GridAnchor = from.get_grid_anchor(CardinalDirections.CardinalDirection.DOWN)
                                if anchor != null:
                                    _add_anchor(anchor)
                                    connect_points(_lookup[from], _lookup[anchor])
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
                                                connect_points(_lookup[from], _lookup[anchor_to])
                                                _add_emergency_mode(from, anchor_to)

                                            GridNode.NodeSideState.DOOR:
                                                var door: GridDoor = from.get_door(direction)
                                                if door != null:
                                                    _add_anchor(anchor_to)

                                                    if door.lock_state == GridDoor.LockState.OPEN:
                                                        connect_points(_lookup[from], _lookup[anchor_to])
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
                                        connect_points(_lookup[from], _lookup[to])

                # Flying modes
                else:
                    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                        # TODO: Lift-off diagonals?
                        var to: GridNode = from.neighbour(direction)

                        match from.has_side(direction):
                            # Fly to neighbouring node
                            GridNode.NodeSideState.NONE:
                                _add_grid_node(to)
                                connect_points(_lookup[from], _lookup[to])

                            # Land
                            GridNode.NodeSideState.SOLID:
                                if transportation_mode.can_walk(direction):
                                    var anchor: GridAnchor = from.get_grid_anchor(direction)
                                    if anchor != null:
                                        _add_anchor(anchor)
                                        connect_points(_lookup[from], _lookup[anchor])

                            # Fly through doors
                            GridNode.NodeSideState.DOOR:
                                _add_grid_node(to)
                                if _evaluate_and_add_door(from.get_door(direction), CardinalDirections.CardinalDirection.NONE, from, to):
                                    connect_points(_lookup[from], _lookup[to])

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
                            connect_points(_lookup[from_anchor], _lookup[from])

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
                                                    connect_points(_lookup[from_anchor], _lookup[to_anchor])
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    connect_points(_lookup[from_anchor], _lookup[to])
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                connect_points(_lookup[from_anchor], _lookup[to])

                                        GridNode.NodeSideState.NONE:
                                            # Check and do outer corner walk
                                            if transportation_mode.can_walk(side):
                                                var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                                if transportation_mode.can_walk(new_anchor_direction):
                                                    if final != null:
                                                        var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                                        match to.has_side(new_anchor_direction):
                                                            GridNode.NodeSideState.SOLID:
                                                                if final_anchor != null:
                                                                    _add_anchor(final_anchor)
                                                                    connect_points(_lookup[from_anchor], _lookup[final_anchor])
                                                            GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                                if _can_jump(transportation_mode, direction):
                                                                    _add_grid_node(to)
                                                                    connect_points(_lookup[from_anchor], _lookup[to])
                                                    elif _can_jump(transportation_mode, direction):
                                                        _add_grid_node(to)
                                                        connect_points(_lookup[from_anchor], _lookup[to])

                                                # If we cannot walk the outer corner target surface we need to jump
                                                # We need to allow jumping even if final doesn't exist if the entity can fly
                                                # Also down might not be in the direction of side...
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    connect_points(_lookup[from_anchor], _lookup[to])


                                            # This shouldn't really happen if we were anchored to that side before but...
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                connect_points(_lookup[from_anchor], _lookup[to])

                                        GridNode.NodeSideState.DOOR:
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
                                                    connect_points(_lookup[from_anchor], _lookup[to])
                                            # We really don't care that "down" is a door, if we can fly we can fly
                                            elif transportation_mode.has_flag(TransportationMode.FLYING):
                                                connect_points(_lookup[from_anchor], _lookup[to])

                            GridNode.NodeSideState.SOLID:
                                var anchor: GridAnchor = from.get_grid_anchor(direction)
                                if anchor != null && transportation_mode.can_walk(direction):
                                    _add_anchor(anchor)
                                    connect_points(_lookup[from_anchor], _lookup[anchor])

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
                                                        connect_points(_lookup[from_anchor], _lookup[to_anchor])
                                                elif _can_jump(transportation_mode, direction) :
                                                    _add_grid_node(to)
                                                    if _evaluate_and_add_door(door, side, from_anchor, to):
                                                        connect_points(_lookup[from_anchor], _lookup[to])
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to])

                                        GridNode.NodeSideState.NONE:
                                            # Check and do outer corner walk
                                            if transportation_mode.can_walk(side):
                                                var new_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.pitch_down(direction, side)[1]

                                                if transportation_mode.can_walk(new_anchor_direction):
                                                    if final != null:
                                                        var final_anchor: GridAnchor = final.get_grid_anchor(new_anchor_direction)

                                                        match to.has_side(new_anchor_direction):
                                                            GridNode.NodeSideState.SOLID:
                                                                if final_anchor != null:
                                                                    _add_anchor(final_anchor)
                                                                    if _evaluate_and_add_door(door, side, from_anchor, final_anchor):
                                                                        connect_points(_lookup[from_anchor], _lookup[final_anchor])
                                                                    continue
                                                            GridNode.NodeSideState.DOOR, GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                                                                if _can_jump(transportation_mode, direction):
                                                                    _add_grid_node(to)
                                                                    if _evaluate_and_add_door(door, side, from_anchor, to):
                                                                        connect_points(_lookup[from_anchor], _lookup[to])

                                                    elif _can_jump(transportation_mode, direction):
                                                        _add_grid_node(to)
                                                        if _evaluate_and_add_door(door, side, from_anchor, to):
                                                            connect_points(_lookup[from_anchor], _lookup[to])

                                                # If we cannot walk the outer corner target surface we need to jump
                                                # We need to allow jumping even if final doesn't exist if the entity can fly
                                                # Also down might not be in the direction of side...
                                                elif _can_jump(transportation_mode, direction):
                                                    _add_grid_node(to)
                                                    if _evaluate_and_add_door(door, side, from_anchor, to):
                                                        connect_points(_lookup[from_anchor], _lookup[to])

                                            # This shouldn't really happen if we were anchored to that side before but...
                                            elif _can_jump(transportation_mode, direction):
                                                _add_grid_node(to)
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to])

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
                                                        connect_points(_lookup[from_anchor], _lookup[to])
                                            # We really don't care that "down" is a door, if we can fly we can fly
                                            elif transportation_mode.has_flag(TransportationMode.FLYING):
                                                if _evaluate_and_add_door(door, side, from_anchor, to):
                                                    connect_points(_lookup[from_anchor], _lookup[to])


        if Time.get_ticks_msec() - t0 > 500:
            # TODO: Turn into coroutine a bit smarter
            await from.get_tree().create_timer(0.02).timeout
            t0 = Time.get_ticks_msec()

    ready = true

# TODO: Check if we've used faulty fall in direction
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
    _side_lookup[_id] = anchor
    _lookup[anchor] = _id
    _id += 1
