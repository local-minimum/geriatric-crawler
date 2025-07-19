class_name QuaternionUtils

static func look_rotation(forward: Vector3, up: Vector3) -> Quaternion:
    return Transform3D.IDENTITY.looking_at(forward, up).basis.get_rotation_quaternion()

static func look_rotation_from_vectors(directions: Array[CardinalDirections.CardinalDirection]) -> Quaternion:
    return Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vector(directions[0])),
        Vector3(CardinalDirections.direction_to_vector(CardinalDirections.invert(directions[1]))),
    ).basis.get_rotation_quaternion()

static func create_tween_rotation_method(node: Node3D, global_space: bool = true) -> Callable:
    if global_space:
        return func (value: Quaternion) -> void:
            node.global_rotation = value.get_euler()

    return func (value: Quaternion) -> void:
        node.rotation = value.get_euler()
