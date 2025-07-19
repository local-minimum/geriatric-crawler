extends GridEvent
class_name GridRamp

@export
var climbing_requirement: int = 0

@export
var up_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.UP

## If entity is wallwalking we need to trigger event on inverse upper exit direction walls
@export
var upper_exit_direction: CardinalDirections.CardinalDirection

@export
var lower_exit_direction: CardinalDirections.CardinalDirection

@export
var lower_overshoot: float = 0.2

func manages_triggering_translation() -> bool:
    return true

@export
var animation_duration: float = 1

@export_range(0, 1)
var lower_duration_fraction: float = 0.1

var ramp_duration_fraction: float:
    get():
        return 1.0 - lower_duration_fraction - ramp_upper_duration_fraction

@export_range(0, 1)
var ramp_upper_duration_fraction: float = 0.15

@export_range(0, 1)
var pivot_duration_fraction: float = 0.05

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    # TODO: Support inner corner wedges
    super.trigger(entity, movement)
    entity.cinematic = true
    entity.end_movement(movement, false)
    entity.clear_queue()
    # TODO: Implement the walk!
    # TODO: Callback entity.end_movement(movement)
    var down: CardinalDirections.CardinalDirection = CardinalDirections.invert(up_direction)
    var down_anchor: GridAnchor = get_grid_node().get_grid_anchor(down)
    # TODO: It would be nice to not assume so much about the
    var lower_point: Vector3 = down_anchor.get_edge_position(lower_exit_direction) + get_level().node_size * CardinalDirections.direction_to_look_vector(lower_exit_direction)
    var upper_point: Vector3 = down_anchor.get_edge_position(upper_exit_direction) + get_level().node_size * CardinalDirections.direction_to_look_vector(up_direction)

    var exit_anchor: GridAnchor

    var translations: Tween = create_tween()
    var rotations: Tween = translations.parallel()

    var update_rotation: Callable = func (value: Quaternion) -> void:
        entity.global_rotation = value.get_euler()

    var rotation_pause: Callable = func (_value: float) -> void:
        pass

    print_debug("Entity at %s entering ramp at %s (%s is expected lower)" % [
        entity.coordinates(),
        coordinates(),
        CardinalDirections.translate(coordinates(), lower_exit_direction),
    ])
    if entity.coordinates() == coordinates() && entity.get_grid_anchor_direction() == CardinalDirections.CardinalDirection.NONE:
        print_debug("Landing")
    elif entity.coordinates() == CardinalDirections.translate(coordinates(), lower_exit_direction):
        print_debug("Going up")
        # Going up
        var upper_exit_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, upper_exit_direction)
        var lower_entry_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, CardinalDirections.invert(lower_exit_direction))

        var ramp_look_direction: Vector3 = (upper_point - lower_point).normalized()
        var ramp_plane_ortho: Vector3 = CardinalDirections.direction_to_look_vector(CardinalDirections.yaw_ccw(upper_exit_direction, down)[0])

        var ramp_normal_direction: Vector3 = ramp_look_direction.cross(ramp_plane_ortho)
        if ramp_normal_direction.dot(CardinalDirections.direction_to_look_vector(up_direction)) > 0:
            ramp_normal_direction *= -1
        var ramp_rotation: Quaternion = Transform3D.IDENTITY.looking_at(ramp_look_direction, ramp_normal_direction).basis.get_rotation_quaternion()

        var intermediate_coordinates: Vector3i = CardinalDirections.translate(coordinates(), up_direction)
        var exit_node_coordinates: Vector3i = CardinalDirections.translate(intermediate_coordinates, upper_exit_direction)
        var intermediate: GridNode = get_level().get_grid_node(intermediate_coordinates)
        var exit_node: GridNode = get_level().get_grid_node(exit_node_coordinates)
        exit_anchor = exit_node.get_grid_anchor(down)

        # TODO: Handle refuses (transit intermediate, there's no exit, we can't anchor on its down)
        # TODO: Easings and such
        translations.tween_property(entity, "global_position", lower_point, animation_duration * lower_duration_fraction)
        translations.tween_property(entity, "global_position", upper_point, animation_duration * ramp_duration_fraction)
        translations.tween_property(entity, "global_position", exit_anchor.global_position, animation_duration * ramp_upper_duration_fraction)

        rotations.tween_method(
            update_rotation,
            entity.global_transform.basis.get_rotation_quaternion(),
            lower_entry_rotation,
            animation_duration * (lower_duration_fraction - 0.5 * pivot_duration_fraction),
        )
        rotations.tween_method(
            update_rotation,
            lower_entry_rotation,
            ramp_rotation,
            animation_duration * pivot_duration_fraction
        )
        rotations.tween_method(rotation_pause, 0.0, 1.0, animation_duration * (ramp_duration_fraction - pivot_duration_fraction))
        rotations.tween_method(
            update_rotation,
            ramp_rotation,
            upper_exit_rotation,
            animation_duration * pivot_duration_fraction
        )
    else:
        # Going down
        print_debug("Going down")

    translations.finished.connect(
        func () -> void:
            entity.set_grid_anchor(exit_anchor)
            entity.sync_position()

            entity.look_direction = upper_exit_direction
            entity.down = down
            entity.orient()

            entity.remove_concurrent_movement_block()
            entity.cinematic = false
    )

    translations.play()

func blocks_entry_translation(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if super.blocks_entry_translation(entity, from, move_direction, to_side):
        return true

    if entity is GridPlayer:
        var player: GridPlayer = entity
        if player.robot.get_skill_level(RobotAbility.SKILL_CLIMBING) < climbing_requirement:
            print_debug("Entry to ramp blocked by too low climbing-skill")
            return true

    var expected_from: Vector3i = CardinalDirections.translate(
        CardinalDirections.translate(coordinates(), up_direction),
        upper_exit_direction,
    )

    if expected_from == from.coordinates:
        var elevation: int = CardinalDirections.vectori_axis_value(
            CardinalDirections.translate(coordinates(), up_direction),
            up_direction,
        )

        if elevation != CardinalDirections.vectori_axis_value(from.coordinates, up_direction):
            print_debug("Walking in to ramp %s" % CardinalDirections.name(upper_exit_direction))
            return true

        print_debug("Entering ramp properly from %s" % CardinalDirections.name(upper_exit_direction))
        return false

    print_debug("Not entering ramp at %s from %s was %s" % [coordinates(), expected_from, from.coordinates])
    return false
