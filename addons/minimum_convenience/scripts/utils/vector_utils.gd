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

static func chebychev_distance2f(a: Vector2, b: Vector2) -> float:
    return max(abs(a.x - b.x), abs(a.y - b.y))

static func inv_chebychev_distance2f(a: Vector2, b: Vector2) -> float:
    return min(abs(a.x - b.x), abs(a.y - b.y))

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

static func flip_sign_first_non_null(a: Vector3i) -> Vector3i:
    if a.x != 0:
        return Vector3i(-a.x, a.y, a.z)
    elif a.y != 0:
        return Vector3i(a.x, -a.y, a.z)

    return Vector3i(a.x, a.y, -a.z)

static func all_coordinates_within(start: Vector3i, size: Vector3i) -> Array[Vector3i]:
    var res: Array[Vector3i]

    for x: int in range(start.x, start.x + size.x):
        for y: int in range(start.y, start.y + size.y):
            for z: int in range(start.z, start.z + size.z):
                res.append(Vector3i(x, y, z))

    return res

static func all_surrounding_coordinates(start: Vector3i, size: Vector3i, corners_and_edges: bool = false) -> Array[Vector3i]:
    var res: Array[Vector3i]
    var max_x: int = start.x + size.x - 1
    var max_y: int = start.y + size.y - 1
    var max_z: int = start.z + size.z - 1

    for x: int in range(start.x, max_x + 1):
        for y: int in range(start.y, max_y + 1):
            for z: int in range(start.z, max_z + 1):
                if x == start.x:
                    res.append(Vector3i(x - 1, y, z))

                    if y == start.y:
                        res.append(Vector3i(x - 1, y - 1, z))
                    if y == max_y:
                        res.append(Vector3i(x - 1, y + 1, z))

                    if z == start.z:
                        res.append(Vector3i(x - 1, y, z - 1))
                    if z == max_z:
                        res.append(Vector3i(x - 1, y, z + 1))

                if x == max_x:
                    res.append(Vector3i(x + 1, y, z))

                    if y == start.y:
                        res.append(Vector3i(x + 1, y - 1, z))
                    if y == max_y:
                        res.append(Vector3i(x + 1, y + 1, z))

                    if z == start.z:
                        res.append(Vector3i(x + 1, y, z - 1))
                    if z == max_z:
                        res.append(Vector3i(x + 1, y, z + 1))

                if y == start.y:
                    res.append(Vector3i(x, y - 1, z))

                    if z == start.z:
                        res.append(Vector3i(x, y - 1, z - 1))
                    if z == max_z:
                        res.append(Vector3i(x, y - 1, z + 1))

                if y == max_y:
                    res.append(Vector3i(x, y + 1, z))

                    if z == start.z:
                        res.append(Vector3i(x, y + 1, z - 1))
                    if z == max_z:
                        res.append(Vector3i(x, y + 1, z + 1))

                if z == start.z:
                    res.append(Vector3i(x, y, z - 1))
                if z == max_z:
                    res.append(Vector3i(x, y, z + 1))

    if corners_and_edges:
        res.append(Vector3i(start.x - 1, start.y - 1, start.z - 1))
        res.append(Vector3i(start.x - 1, start.y - 1, max_z + 1))
        res.append(Vector3i(start.x - 1, max_y + 1, start.z - 1))
        res.append(Vector3i(start.x - 1, max_y + 1, max_z + 1))
        res.append(Vector3i(max_x + 1, start.y - 1, start.z - 1))
        res.append(Vector3i(max_x + 1, start.y - 1, max_z + 1))
        res.append(Vector3i(max_x + 1, max_y + 1, start.z - 1))
        res.append(Vector3i(max_x + 1, max_y + 1, max_z + 1))

    return res
