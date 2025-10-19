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

const ALL_DIRECTIONS_AND_NONE: Array[CardinalDirection] = [
    CardinalDirection.NONE,
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

#region Creation

static func from_string(direction: String) -> CardinalDirection:
    match direction.strip_edges().to_upper():
        "N", "NORTH":
            return CardinalDirection.NORTH
        "S", "SOUTH":
            return CardinalDirection.SOUTH
        "U", "UP", "ZENITH", "Z":
            return CardinalDirection.UP
        "D", "DOWN", "NADIR":
            return CardinalDirection.DOWN
        "W", "WEST":
            return CardinalDirection.WEST
        "E", "EAST":
            return CardinalDirection.EAST
        _:
            return CardinalDirection.NONE

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

static func principal_direction(vector: Vector3) -> CardinalDirection:
    var avec: Vector3 = vector.abs()
    if avec.x == avec.y && avec.y == avec.z:
        match randi_range(0, 2):
            0:
                return CardinalDirection.EAST if vector.x > 0 else CardinalDirection.WEST
            1:
                return CardinalDirection.UP if vector.y > 0 else CardinalDirection.DOWN
            2:
                return CardinalDirection.NORTH if vector.z > 0 else CardinalDirection.SOUTH
    elif avec.x > avec.y:
        if avec.x > avec.z || randf() >= 0.5:
            return CardinalDirection.EAST if vector.x > 0 else CardinalDirection.WEST
        return CardinalDirection.NORTH if vector.z > 0 else CardinalDirection.SOUTH
    elif avec.y > avec.z:
        return CardinalDirection.UP if vector.y > 0 else CardinalDirection.DOWN

    return CardinalDirection.NORTH if vector.z > 0 else CardinalDirection.SOUTH

static func node_planar_rotation_to_direction(node: Node3D) -> CardinalDirection:
    var y_rotation: int = roundi(node.global_rotation_degrees.y / 90) * 90
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

#endregion Creation

#region Checks

static func is_parallell(direction: CardinalDirection, other: CardinalDirection) -> bool:
    return direction == other || direction == invert(other)

static func is_planar_cardinal(direction: CardinalDirection) -> bool:
    return ALL_PLANAR_DIRECTIONS.has(direction)

#endregion Checks

#region Modifying Directions

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
        push_error("Attempting to yaw %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    var v_direction: Vector3i = direction_to_vectori(look_direction)
    var v_up: Vector3i = direction_to_vectori(invert(down))
    var result: Vector3i = VectorUtils.rotate_ccw(v_direction, v_up)
    return [vector_to_direction(result), down]

static func yaw_cw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to yaw %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    var v_direction: Vector3i = direction_to_vectori(look_direction)
    var v_up: Vector3i = direction_to_vectori(invert(down))
    var result: Vector3i = VectorUtils.rotate_cw(v_direction, v_up)
    return [vector_to_direction(result), down]

static func pitch_up(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to pitch %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    return [invert(down), look_direction]

static func pitch_down(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to pitch %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    return [down, invert(look_direction)]

static func roll_ccw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to bank %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    var v_direction_as_up: Vector3i = direction_to_vectori(look_direction)
    var v_down: Vector3i = direction_to_vectori(down)
    var result: Vector3i = VectorUtils.rotate_ccw(v_down, v_direction_as_up)
    return [look_direction, vector_to_direction(result)]

static func roll_cw(look_direction: CardinalDirection, down: CardinalDirection) -> Array[CardinalDirection]:
    if is_parallell(look_direction, down):
        push_error("Attempting to bank %s with %s as down" % [name(look_direction), name(down)])
        print_stack()
        return [look_direction, down]

    var v_direction_as_up: Vector3i = direction_to_vectori(look_direction)
    var v_down: Vector3i = direction_to_vectori(down)
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
        # print_debug("Moving %s is a counter-clockwise yaw from look direction" % name(move_direction))
        return roll_ccw(look_direction, down)
    elif move_direction == yaw_cw(look_direction, down)[0]:
        # print_debug("Moving %s is a clockwise yaw from look direction" % name(move_direction))
        return roll_cw(look_direction, down)
    else:
        push_error("movement %s is not inner corner movement when %s is down" % [name(move_direction), down])
        print_stack()
        return [look_direction, down]

static func calculate_outer_corner(
    move_direction: CardinalDirection,
    look_direction: CardinalDirection,
    down: CardinalDirection,
) -> Array[CardinalDirection]:
    if move_direction == look_direction:
        return pitch_down(look_direction, down)
    elif move_direction == invert(look_direction):
        return pitch_up(look_direction, down)
    elif move_direction == yaw_ccw(look_direction, down)[0]:
        # print_debug("Moving %s is a counter-clockwise yaw from look direction" % name(move_direction))
        return roll_cw(look_direction, down)
    elif move_direction == yaw_cw(look_direction, down)[0]:
        # print_debug("Moving %s is a clockwise yaw from look direction" % name(move_direction))
        return roll_ccw(look_direction, down)
    else:
        push_error("movement %s is not inner corner movement when %s is down" % [name(move_direction), down])
        print_stack()
        return [look_direction, down]

static func orthogonals(direction: CardinalDirection) -> Array[CardinalDirection]:
    var ortho: Array[CardinalDirection]
    var inverted: CardinalDirection = invert(direction)

    for other: CardinalDirection in ALL_DIRECTIONS:
        if other == direction || other == inverted:
            continue
        ortho.append(other)

    return ortho

static func orthogonal_axis(first: CardinalDirection, second: CardinalDirection) -> CardinalDirection:
    var first_inverse: CardinalDirection = invert(first)
    if first_inverse == second:
        push_error("%s and %s are parallel" % [name(first), name(second)])
        print_stack()
        return CardinalDirection.NONE

    if first == CardinalDirection.UP || first == CardinalDirection.DOWN:
        match second:
            CardinalDirection.WEST: return CardinalDirection.SOUTH
            CardinalDirection.EAST: return CardinalDirection.SOUTH
            CardinalDirection.NORTH: return CardinalDirection.EAST
            CardinalDirection.SOUTH: return CardinalDirection.EAST
    elif first == CardinalDirection.NORTH || first == CardinalDirection.SOUTH:
        match second:
            CardinalDirection.WEST: return CardinalDirection.UP
            CardinalDirection.EAST: return CardinalDirection.UP
            CardinalDirection.UP: return CardinalDirection.EAST
            CardinalDirection.DOWN: return CardinalDirection.EAST
    elif first == CardinalDirection.WEST || first == CardinalDirection.EAST:
        match second:
            CardinalDirection.NORTH: return CardinalDirection.UP
            CardinalDirection.SOUTH: return CardinalDirection.UP
            CardinalDirection.UP: return CardinalDirection.SOUTH
            CardinalDirection.DOWN: return CardinalDirection.SOUTH

    push_error("%s and %s are not orthogonal" % [name(first), name(second)])
    print_stack()
    return CardinalDirection.NONE

#endregion Modifying Directions

#region To Other

static func direction_to_vectori(direction: CardinalDirection) -> Vector3i:
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

static func direction_to_vector(direction: CardinalDirection) -> Vector3:
    match direction:
        CardinalDirection.NONE: return Vector3.ZERO
        CardinalDirection.NORTH: return Vector3.FORWARD
        CardinalDirection.SOUTH: return Vector3.BACK
        CardinalDirection.WEST: return Vector3.LEFT
        CardinalDirection.EAST: return Vector3.RIGHT
        CardinalDirection.UP: return Vector3.UP
        CardinalDirection.DOWN: return Vector3.DOWN
        _:
            push_error("Invalid direction: %s" % direction)
            print_stack()
            return Vector3.ZERO

static func direction_to_ortho_plane(direction: CardinalDirection) -> Vector3i:
    match direction:
        CardinalDirection.NONE: return Vector3i.ZERO
        CardinalDirection.NORTH: return Vector3i(1, 1, 0)
        CardinalDirection.SOUTH: return Vector3i(1, 1, 0)
        CardinalDirection.WEST: return Vector3i(0, 1, 1)
        CardinalDirection.EAST: return Vector3i(0, 1, 1)
        CardinalDirection.UP: return Vector3i(1, 0, 1)
        CardinalDirection.DOWN: return Vector3i(1, 0, 1)
        _:
            push_error("Invalid direction: %s" % direction)
            print_stack()
            return Vector3i.ZERO

static func direction_to_axis(direction: CardinalDirection) -> Vector3:
    match  direction:
        CardinalDirection.NONE: return Vector3.ZERO
        CardinalDirection.UP: return Vector3.UP
        CardinalDirection.DOWN: return Vector3.UP
        CardinalDirection.WEST: return Vector3.LEFT
        CardinalDirection.EAST: return Vector3.LEFT
        CardinalDirection.NORTH: return Vector3.BACK
        CardinalDirection.SOUTH: return Vector3.BACK
        _:
            push_error("Invalid direction: %" % direction)
            print_stack()
            return Vector3.ZERO

static func direction_to_axis_parameter_name(direction: CardinalDirection) -> String:
    match  direction:
        CardinalDirection.UP: return "y"
        CardinalDirection.DOWN: return "y"
        CardinalDirection.WEST: return "x"
        CardinalDirection.EAST: return "x"
        CardinalDirection.NORTH: return "z"
        CardinalDirection.SOUTH: return "z"
        _:
            push_error("Invalid direction: %" % direction)
            print_stack()
            return ""

## Assuming north side is the identity rotation
static func direction_to_planar_rotation(direction: CardinalDirection) -> Quaternion:
    match direction:
        CardinalDirection.NORTH: return Quaternion.IDENTITY
        CardinalDirection.WEST: return Quaternion.from_euler(Vector3(0, PI * 0.5, 0))
        CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(0, PI, 0))
        CardinalDirection.EAST: return Quaternion.from_euler(Vector3(0, PI * -0.5, 0))
        _:
            push_error(
                "Illegal calculation, %s isn't a planar cardinal direction" % direction
            )
            print_stack()
            return Quaternion.IDENTITY

## Assuming north side is the identity rotation
static func direction_to_any_rotation(direction: CardinalDirection) -> Quaternion:
    match direction:
        CardinalDirection.NORTH: return Quaternion.IDENTITY
        CardinalDirection.WEST: return Quaternion.from_euler(Vector3(0, PI * 0.5, 0))
        CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(0, PI, 0))
        CardinalDirection.EAST: return Quaternion.from_euler(Vector3(0, PI * -0.5, 0))
        CardinalDirection.DOWN: return Quaternion.from_euler(Vector3(PI * -0.5, 0, 0))
        CardinalDirection.UP: return Quaternion.from_euler(Vector3(PI * 0.5, 0, 0))
        _:
            push_error(
                "Illegal calculation, %s isn't a planar cardinal direction" % direction
            )
            print_stack()
            return Quaternion.IDENTITY

static func direction_to_rotation(up: CardinalDirection, forward: CardinalDirection) -> Quaternion:
    match up:
        CardinalDirection.UP:
            match forward:
                CardinalDirection.NORTH: return Quaternion.IDENTITY
                CardinalDirection.WEST: return Quaternion.from_euler(Vector3(0, PI * 0.5, 0))
                CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(0, PI, 0))
                CardinalDirection.EAST: return Quaternion.from_euler(Vector3(0, PI * -0.5, 0))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        CardinalDirection.DOWN:
            match forward:
                CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(PI, 0, 0))
                CardinalDirection.EAST: return Quaternion.from_euler(Vector3(PI, PI * 0.5, 0))
                CardinalDirection.NORTH: return Quaternion.from_euler(Vector3(PI, PI, 0))
                CardinalDirection.WEST: return Quaternion.from_euler(Vector3(PI, PI * -0.5, 0))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        CardinalDirection.NORTH:
            match forward:
                CardinalDirection.DOWN: return Quaternion.from_euler(Vector3(-PI * 0.5, 0, 0))
                CardinalDirection.WEST: return Quaternion.from_euler(Vector3(0, PI * 0.5, PI * -0.5))
                CardinalDirection.UP: return Quaternion.from_euler(Vector3(PI * 0.5, PI, 0))
                CardinalDirection.EAST: return Quaternion.from_euler(Vector3(0, PI * -0.5, PI * 0.5))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        CardinalDirection.SOUTH:
            match forward:
                CardinalDirection.UP: return Quaternion.from_euler(Vector3(PI * 0.5, 0, 0))
                CardinalDirection.EAST: return Quaternion.from_euler(Vector3(PI, PI * 0.5, PI * 0.5))
                CardinalDirection.DOWN: return Quaternion.from_euler(Vector3(PI * -0.5, PI, 0))
                CardinalDirection.WEST: return Quaternion.from_euler(Vector3(0, PI * 0.5, PI * 0.5 ))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        CardinalDirection.WEST:
            match forward:
                CardinalDirection.DOWN: return Quaternion.from_euler(Vector3(PI * -0.5, PI * 0.5, 0))
                CardinalDirection.NORTH: return Quaternion.from_euler(Vector3(0, 0, PI * 0.5))
                CardinalDirection.UP: return Quaternion.from_euler(Vector3(PI * 0.5, PI * -0.5, 0))
                CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(0, PI, PI * -0.5))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        CardinalDirection.EAST:
            match forward:
                CardinalDirection.DOWN: return Quaternion.from_euler(Vector3(PI * -0.5, PI * -0.5, 0))
                CardinalDirection.NORTH: return Quaternion.from_euler(Vector3(0, 0, PI * -0.5))
                CardinalDirection.UP: return Quaternion.from_euler(Vector3(PI * 0.5, PI * 0.5, 0))
                CardinalDirection.SOUTH: return Quaternion.from_euler(Vector3(0, PI, PI * 0.5))
                _:
                    push_error(
                        "Illegal calculation, %s isn't orthogonal to %s cardinal direction" % [CardinalDirections.name(forward), CardinalDirections.name(up)]
                    )
                    print_stack()
                    return Quaternion.IDENTITY
        _:

            return Quaternion.IDENTITY
static func angle_around_axis(direction: CardinalDirection, down: CardinalDirection) -> float:
    match down:
        CardinalDirection.DOWN:
            match direction:
                CardinalDirection.NORTH: return 180
                CardinalDirection.WEST: return 90
                CardinalDirection.SOUTH: return 0
                CardinalDirection.EAST: return 270
        CardinalDirection.UP:
            match direction:
                CardinalDirection.NORTH: return 180
                CardinalDirection.WEST: return 270
                CardinalDirection.SOUTH: return 0
                CardinalDirection.EAST: return 90
        CardinalDirection.WEST:
            match direction:
                CardinalDirection.UP: return 0
                CardinalDirection.SOUTH: return 90
                CardinalDirection.DOWN: return 180
                CardinalDirection.NORTH: return 270
        CardinalDirection.EAST:
            match direction:
                CardinalDirection.UP: return 180
                CardinalDirection.SOUTH: return 270
                CardinalDirection.DOWN: return 0
                CardinalDirection.NORTH: return 90
        CardinalDirection.NORTH:
            match direction:
                CardinalDirection.UP: return 0
                CardinalDirection.WEST: return 90
                CardinalDirection.DOWN: return 180
                CardinalDirection.EAST: return 270
        CardinalDirection.SOUTH:
            match direction:
                CardinalDirection.UP: return 180
                CardinalDirection.WEST: return 270
                CardinalDirection.DOWN: return 0
                CardinalDirection.EAST: return 90

    push_error("Invalid direction %s with %s as down" % [direction, down])
    print_stack()
    return 0

static func name(direction: CardinalDirection, localized: bool = false) -> String:
    if localized:
        return __GlobalGameState.tr("CARDINAL_%s" % CardinalDirection.find_key(direction))
    return CardinalDirection.find_key(direction)

#region To Other

#region Operate on Other

static func translate(coordinates: Vector3i, direction: CardinalDirection, repeats: int = 1) -> Vector3i:
    return coordinates + direction_to_vectori(direction) * repeats

static func scale_axis(vector: Vector3, axis: CardinalDirection, scale: float) -> Vector3:
    match axis:
        CardinalDirection.UP: return Vector3(vector.x, vector.y * scale, vector.z)
        CardinalDirection.DOWN: return Vector3(vector.x, vector.y * scale, vector.z)
        CardinalDirection.NORTH: return Vector3(vector.x, vector.y, vector.z * scale)
        CardinalDirection.SOUTH: return Vector3(vector.x, vector.y, vector.z * scale)
        CardinalDirection.WEST: return Vector3(vector.x * scale, vector.y, vector.z)
        CardinalDirection.EAST: return Vector3(vector.x * scale, vector.y, vector.z)
        _: return vector

## Scales the vector when sign of component equals direction
static func scale_aligned_direction(vector: Vector3, direction: CardinalDirection, scale: float) -> Vector3:
    match direction:
        CardinalDirection.UP:
            if vector.y > 0:
                return Vector3(vector.x, vector.y * scale, vector.z)
            return vector
        CardinalDirection.DOWN:
            if vector.y < 0:
                return Vector3(vector.x, vector.y * scale, vector.z)
            return vector
        CardinalDirection.NORTH:
            if vector.z < 0:
                return Vector3(vector.x, vector.y, vector.z * scale)
            return vector
        CardinalDirection.SOUTH:
            if vector.z > 0:
                return Vector3(vector.x, vector.y, vector.z * scale)
            return vector
        CardinalDirection.WEST:
            if vector.x < 0:
                return Vector3(vector.x * scale, vector.y, vector.z)
            return vector
        CardinalDirection.EAST:
            if vector.x > 0:
                return Vector3(vector.x * scale, vector.y, vector.z)
            return vector
        _: return vector


static func vectori_axis_value(coordinates: Vector3i, direction: CardinalDirection) -> int:
    match direction:
        CardinalDirection.UP: return coordinates.y
        CardinalDirection.DOWN: return coordinates.y
        CardinalDirection.NORTH: return coordinates.z
        CardinalDirection.SOUTH: return coordinates.z
        CardinalDirection.WEST: return coordinates.x
        CardinalDirection.EAST: return coordinates.x
        _: return 0

static func vector_axis_value(coordinates: Vector3, direction: CardinalDirection) -> float:
    match direction:
        CardinalDirection.UP: return coordinates.y
        CardinalDirection.DOWN: return coordinates.y
        CardinalDirection.NORTH: return coordinates.z
        CardinalDirection.SOUTH: return coordinates.z
        CardinalDirection.WEST: return coordinates.x
        CardinalDirection.EAST: return coordinates.x
        _: return 0
#endregion Operate on Other
