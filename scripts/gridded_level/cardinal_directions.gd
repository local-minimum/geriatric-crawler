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

static func yaw_ccw(direction: CardinalDirection, down: CardinalDirection) -> CardinalDirection:
    if is_parallell(direction, down):
        push_error("Attempting to yaw %s with %s as down" % [direction, down])
        print_stack()
        return direction

    var v_direction: Vector3i = direction_to_vector(direction)
    var v_up: Vector3i = direction_to_vector(invert(down))
    var result: Vector3i = VectorUtils.rotate_ccw(v_direction, v_up)
    return vector_to_direction(result)

static func yaw_cw(direction: CardinalDirection, down: CardinalDirection) -> CardinalDirection:
    if is_parallell(direction, down):
        push_error("Attempting to yaw %s with %s as down" % [direction, down])
        print_stack()
        return direction

    var v_direction: Vector3i = direction_to_vector(direction)
    var v_up: Vector3i = direction_to_vector(invert(down))
    var result: Vector3i = VectorUtils.rotate_cw(v_direction, v_up)
    return vector_to_direction(result)

#
# To vectors
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

#
# Operating on other objects
#

static func translate(coordinates: Vector3i, direction: CardinalDirection) -> Vector3i:
    return coordinates + direction_to_vector(direction)
