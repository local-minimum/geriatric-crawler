class_name QuaternionUtils

static func look_rotation(forward: Vector3, up: Vector3) -> Quaternion:
    return Transform3D.IDENTITY.looking_at(forward, up).basis.get_rotation_quaternion()

static func look_rotation_from_vectors(directions: Array[CardinalDirections.CardinalDirection]) -> Quaternion:
    return Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vectori(directions[0])),
        Vector3(CardinalDirections.direction_to_vectori(CardinalDirections.invert(directions[1]))),
    ).basis.get_rotation_quaternion()

static func create_tween_rotation_method(node: Node3D, global_space: bool = true) -> Callable:
    if global_space:
        return func (value: Quaternion) -> void:
            node.global_rotation = value.get_euler()

    return func (value: Quaternion) -> void:
        node.rotation = value.get_euler()

static func create_tween_lookat_method(node: Node3D, target: Node3D, up: Vector3 = Vector3.UP) -> Callable:
    var start_rotation: Quaternion = node.global_basis.get_rotation_quaternion()

    return func (progress: float) -> void:
        var look_at: Quaternion = Basis.looking_at(target.global_position - node.global_position, up).get_rotation_quaternion()
        var rot: Quaternion = lerp(start_rotation, look_at, progress)
        node.global_rotation = rot.get_euler()
