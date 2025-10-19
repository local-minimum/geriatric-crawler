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

func initialize(
    level: GridLevel,
    transportation_mode: TransportationMode,
) -> void:
    for from: GridNode in level.nodes():
        _add_grid_node(from)

        for side: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS_AND_NONE:
            if side == CardinalDirections.CardinalDirection.NONE:
                if !transportation_mode.has_flag(TransportationMode.FLYING):
                    # Falling behaviour
                    match from.has_side(CardinalDirections.CardinalDirection.DOWN):
                        # Free air
                        GridNode.NodeSideState.NONE, GridNode.NodeSideState.ILLUSORY:
                            var to: GridNode = from.neighbour(CardinalDirections.CardinalDirection.DOWN)
                            if to != null:
                                _add_grid_node(to)
                                connect_points(_lookup[from], _lookup[to])

                        # Land
                        GridNode.NodeSideState.SOLID:
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

                                    if door.lock_state == GridDoor.LockState.OPEN:
                                        if to != null:
                                            connect_points(_lookup[from], _lookup[to])

                                    _add_door_connection(door, from, to)

                else:
                    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                        match from.has_side(direction):
                            # Transition to neighbouring node
                            GridNode.NodeSideState.NONE:
                                var to: GridNode = from.neighbour(direction)
                                _add_grid_node(to)
                                connect_points(_lookup[from], _lookup[to])

                            # Land
                            GridNode.NodeSideState.SOLID:
                                var anchor: GridAnchor = from.get_grid_anchor(direction)
                                if anchor != null:
                                    match anchor.direction:
                                        CardinalDirections.CardinalDirection.DOWN:
                                            if transportation_mode.has_flag(TransportationMode.WALKING):
                                                _add_anchor(anchor)
                                                connect_points(_lookup[from], _lookup[anchor])
                                        CardinalDirections.CardinalDirection.UP:
                                            if transportation_mode.has_flag(TransportationMode.CEILING_WALKING):
                                                _add_anchor(anchor)
                                                connect_points(_lookup[from], _lookup[anchor])
                                        CardinalDirections.CardinalDirection.NONE:
                                            pass
                                        _:
                                            if transportation_mode.has_flag(TransportationMode.WALL_WALKING):
                                                _add_anchor(anchor)
                                                connect_points(_lookup[from], _lookup[anchor])

                            # Fly through doors
                            GridNode.NodeSideState.DOOR:
                                var door: GridDoor = from.get_door(direction)
                                if door != null:
                                    var to: GridNode = from.neighbour(direction)
                                    _add_grid_node(to)
                                    if door.lock_state == GridDoor.LockState.OPEN:
                                        connect_points(_lookup[from], _lookup[to])

                                    _add_door_connection(door, from, to)
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
                        if direction != CardinalDirections.CardinalDirection.UP || transportation_mode.has_flag(TransportationMode.FLYING):
                            connect_points(_lookup[from_anchor], _lookup[from])

                    # Walk along the current side in some direction
                    else:
                        match from.has_side(direction):
                            GridNode.NodeSideState.NONE:
                                # TODO: Are we jumping there or just walking
                                # TODO: Handle outer corners
                                var to: GridNode = from.neighbour(direction)
                                if to != null:
                                    var to_anchor: GridAnchor = to.get_grid_anchor(side)
                                    # Normal walk along the side
                                    if to_anchor != null:
                                        _add_anchor(to_anchor)
                                        connect_points(_lookup[from_anchor], _lookup[to_anchor])
                                    else:
                                        pass

                            GridNode.NodeSideState.SOLID:
                                var anchor: GridAnchor = from.get_grid_anchor(direction)
                                if anchor != null:
                                    # TODO: Inner corner walk
                                    pass

                            # TODO: Doors


    ready = true

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
