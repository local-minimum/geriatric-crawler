class_name CardinalDirections

enum CardinalDirection {
    NONE,
    NORTH,
    SOUTH,
    WEST,
    EAST,
    UP,
    DOWN
}

const ALL_DIRECTIONS: Array[CardinalDirection] = [
    CardinalDirection.NORTH,
    CardinalDirection.SOUTH,
    CardinalDirection.WEST,
    CardinalDirection.EAST,
    CardinalDirection.UP,
    CardinalDirection.DOWN,
]

const ALL_PLANAR_DIRECTIONS: Array[CardinalDirection] = [
    CardinalDirection.NORTH,
    CardinalDirection.SOUTH,
    CardinalDirection.WEST,
    CardinalDirection.EAST,
]

#
# Creation
#

static func vector_to_direction(vector: Vector3i) -> CardinalDirection:
    match vector:
        Vector3i.FORWARD: return CardinalDirection.NORTH
        Vector3i.BACK: return CardinalDirection.SOUTH
        Vector3i.LEFT: return CardinalDirection.WEST
        Vector3i.RIGHT: return CardinalDirection.EAST
        Vector3i.UP: return CardinalDirection.UP
        Vector3i.DOWN: return CardinalDirection.DOWN
        Vector3i.ZERO: return CardinalDirection.NONE
        _:
            push_error("Vector %s is not a cardinal vector" % vector)
            print_stack()
            return CardinalDirection.NONE

static func node_planar_rotation_to_direction(node: Node3D) -> CardinalDirection:
    var y_rotation: int = roundi(node.rotation_degrees.y / 90) * 90
    y_rotation = posmod(y_rotation, 360)
    match y_rotation:
        0: return CardinalDirection.NORTH
        90: return CardinalDirection.WEST
        180: return CardinalDirection.SOUTH
        270: return CardinalDirection.EAST
        _:
            push_error(
                "Illegal calculation, the y-rotation %s isn't a cardinal direction (node %s's rotation %s)" % [y_rotation, node, node.rotation_degrees]
            )
            print_stack()
            return CardinalDirection.NONE

#
# Checks
#

static func is_parallell(direction: CardinalDirection, other: CardinalDirection) -> bool:
    return direction == other || direction == invert(other)

static func is_planar_cardinal(direction: CardinalDirection) -> bool:
    return ALL_PLANAR_DIRECTIONS.has(direction)

#
# Modifying a direction
#

static func invert(direction: CardinalDirection) -> CardinalDirection:
    match direction:
        CardinalDirection.NONE: return CardinalDirection.NONE
        CardinalDirection.NORTH: return CardinalDirection.SOUTH
        CardinalDirection.SOUTH: return CardinalDirection.NORTH
        CardinalDirection.WEST: return CardinalDirection.EAST
        CardinalDirection.EAST: return CardinalDirection.WEST
        CardinalDirection.UP: return CardinalDirection.DOWN
        CardinalDirection.DOWN: return CardinalDirection.UP
        _:
            push_error("Invalid direction: %s" % direction)
            print_stack()
            return CardinalDirection.NONE

static func yaw_ccw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to yaw %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    var v_direction: Vector3i = direction_to_vector(look_direction)
    var v_up: Vector3i = direction_to_vector(invert(down))
    var result: Vector3i = VectorUtils.rotate_ccw(v_direction, v_up)
    return [vector_to_direction(result), down]

static func yaw_cw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to yaw %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    var v_direction: Vector3i = direction_to_vector(look_direction)
    var v_up: Vector3i = direction_to_vector(invert(down))
    var result: Vector3i = VectorUtils.rotate_cw(v_direction, v_up)
    return [vector_to_direction(result), down]

static func pitch_up(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to pitch %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    return [invert(down), look_direction]

static func pitch_down(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to pitch %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    return [down, invert(look_direction)]

static func roll_ccw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to bank %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    var v_direction_as_up: Vector3i = direction_to_vector(look_direction)
    var v_down: Vector3i = direction_to_vector(down)
    var result: Vector3i = VectorUtils.rotate_ccw(v_down, v_direction_as_up)
    return [look_direction, vector_to_direction(result)]

static func roll_cw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to bank %s with %s as down" % [look_direction, down])
        print_stack()
        return [look_direction, down]

    var v_direction_as_up: Vector3i = direction_to_vector(look_direction)
    var v_down: Vector3i = direction_to_vector(down)
    var result: Vector3i = VectorUtils.rotate_cw(v_down, v_direction_as_up)
    return [look_direction, vector_to_direction(result)]

static func calculate_innner_corner(
    move_direction: CardinalDirection,
    look_direction: CardinalDirection,
    down: CardinalDirection,
) -> Array[CardinalDirection]:
    if move_direction == look_direction:
        return pitch_up(look_direction, down)
    elif move_direction == invert(look_direction):
        return pitch_down(look_direction, down)
    elif move_direction == yaw_ccw(look_direction, down)[0]:
        print_debug("Moving %s is a counter-clockwise yaw from look direction" % move_direction)
        return roll_ccw(look_direction, down)
    elif move_direction == yaw_cw(look_direction, down)[0]:
        print_debug("Moving %s is a clockwise yaw from look direction" % move_direction)
        return roll_cw(look_direction, down)
    else:
        push_error("movement %s is not inner corner movement when %s is down" % [move_direction, down])
        print_stack()
        return [look_direction, down]

#
# To other objects
#

static func direction_to_vector(direction: CardinalDirection) -> Vector3i:
    match direction:
        CardinalDirection.NONE: return Vector3i.ZERO
        CardinalDirection.NORTH: return Vector3i.FORWARD
        CardinalDirection.SOUTH: return Vector3i.BACK
        CardinalDirection.WEST: return Vector3i.LEFT
        CardinalDirection.EAST: return Vector3i.RIGHT
        CardinalDirection.UP: return Vector3i.UP
        CardinalDirection.DOWN: return Vector3i.DOWN
        _:
            push_error("Invalid direction: %s" % direction)
            print_stack()
            return Vector3i.ZERO

static func name(direction: CardinalDirection) -> String:
    return CardinalDirection.find_key(direction)

#
# Operating on other objects
#

static func translate(coordinates: Vector3i, direction: CardinalDirection) -> Vector3i:
    return coordinates + direction_to_vector(direction)
