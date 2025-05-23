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

func direction_to_vector(direction: CardinalDirection) -> Vector3i:
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
