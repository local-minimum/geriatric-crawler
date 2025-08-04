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

static func primary_direction(v: Vector3i) -> Vector3i:
    var abs_x: int = abs(v.x)
    var abs_y: int = abs(v.y)
    var abs_z: int = abs(v.z)

    if abs_x > abs_z && abs_x > abs_y:
        return Vector3i(signi(v.x), 0, 0)

    if abs_y > abs_z:
        return Vector3i(0, signi(v.y), 0)

    return Vector3i(0, 0, signi(v.z))

static func all_dimensions_smaller(a: Vector3, b: Vector3) -> bool:
    return a.x < b.x && a.y < b.y && a.z < b.z

static func is_negative_cardinal_axis(a: Vector3) -> bool:
    return a.x < 0 || a.y < 0 || a.z < 0
