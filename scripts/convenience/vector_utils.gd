class_name VectorUtils

static func rotate_cw(direction: Vector3i, up: Vector3i) -> Vector3i:
    if up.y > 0:
        return Vector3i(-direction.z, direction.y, direction.x)
    elif up.y < 0:
        return Vector3i(direction.z, direction.y, -direction.x)
    elif up.x < 0:
        return Vector3i(direction.x, -direction.z, direction.y)
    elif up.x > 0:
        return Vector3i(direction.x, direction.z, -direction.y)
    elif up.z < 0:
        return Vector3i(-direction.y, direction.x, direction.z)
    elif up.z > 0:
        return Vector3i(direction.y, -direction.x, direction.z)

    push_error("Cannot rotate counter-clockwise without an up direction")
    print_stack()
    return direction

static func rotate_ccw(direction: Vector3i, up: Vector3i) -> Vector3i:
    if up.y < 0:
        return Vector3i(-direction.z, direction.y, direction.x)
    elif up.y > 0:
        return Vector3i(direction.z, direction.y, -direction.x)
    elif up.x > 0:
        return Vector3i(direction.x, -direction.z, direction.y)
    elif up.x < 0:
        return Vector3i(direction.x, direction.z, -direction.y)
    elif up.z > 0:
        return Vector3i(-direction.y, direction.x, direction.z)
    elif up.z < 0:
        return Vector3i(direction.y, -direction.x, direction.z)

    push_error("Cannot rotate clockwise without an up direction")
    print_stack()
    return direction

static func manhattan_distance(a: Vector3i, b: Vector3i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y) + absi(a.z - b.z)

static func chebychev_distance(a: Vector3i, b: Vector3i) -> int:
    return maxi(maxi(absi(a.x - b.x), absi(a.y - b.y)), absi(a.z - b.z))
