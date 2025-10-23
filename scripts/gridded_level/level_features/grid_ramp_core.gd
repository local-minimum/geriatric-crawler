extends GridEvent
class_name GridRampCore

@export var up_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.UP

## If entity is wallwalking we need to trigger event on inverse upper exit direction walls
@export var upper_exit_direction: CardinalDirections.CardinalDirection

@export var lower_exit_direction: CardinalDirections.CardinalDirection

@export var lower_overshoot: float = 0.2

func manages_triggering_translation() -> bool:
    return true

@export var animation_duration: float = 1

@export_range(0, 1) var lower_duration_fraction: float = 0.1

var ramp_duration_fraction: float:
    get():
        return 1.0 - lower_duration_fraction - ramp_upper_duration_fraction

@export_range(0, 1) var ramp_upper_duration_fraction: float = 0.15

@export_range(0, 1) var pivot_duration_fraction: float = 0.05

enum AnimationMode { Ramp, Stairs }

@export var animation_mode: AnimationMode = AnimationMode.Ramp

@export var stair_steps: int = 7

@export var shift_points_on_stairs: float = 0.1

var _transporting_entities: Array[GridEntity]

var translations: Tween
var rotations: Tween

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    # TODO: Support inner corner wedges
    if _transporting_entities.has(entity):
        return

    _transporting_entities.append(entity)
    super.trigger(entity, movement)
    entity.cinematic = true
    entity.end_movement(movement, false)
    entity.clear_queue()
    var down: CardinalDirections.CardinalDirection = CardinalDirections.invert(up_direction)
    var down_anchor: GridAnchor = get_grid_node().get_grid_anchor(down)
    var lower_point: Vector3 = down_anchor.get_edge_position(lower_exit_direction) + get_level().node_size * CardinalDirections.direction_to_vector(lower_exit_direction) * lower_overshoot
    var upper_point: Vector3 = down_anchor.get_edge_position(upper_exit_direction) + get_level().node_size * CardinalDirections.direction_to_vector(up_direction)
    if animation_mode == AnimationMode.Stairs:
        var offset: Vector3 = get_level().node_size * CardinalDirections.direction_to_vector(lower_exit_direction) * shift_points_on_stairs
        lower_point += offset
        upper_point += offset

    var exit_anchor: GridAnchor

    if translations != null:
        translations.kill()
    translations = get_tree().create_tween()

    if rotations != null:
        rotations.kill()
    rotations = get_tree().create_tween()

    var update_rotation: Callable = QuaternionUtils.create_tween_rotation_method(entity)

    var rotation_pause: Callable = func (_value: float) -> void:
        pass

    var ramp_look_going_up_direction: Vector3 = (upper_point - lower_point).normalized()
    var ramp_plane_ortho: Vector3 = CardinalDirections.direction_to_vector(CardinalDirections.yaw_ccw(upper_exit_direction, down)[0])

    var ramp_normal_direction: Vector3 = ramp_look_going_up_direction.cross(ramp_plane_ortho)
    if ramp_normal_direction.dot(CardinalDirections.direction_to_vector(up_direction)) < 0:
        ramp_normal_direction *= -1

    var exit_direction: CardinalDirections.CardinalDirection = lower_exit_direction

    print_debug("[Grid Ramp] Entity at %s entering ramp at %s (%s is expected lower)" % [
        entity.coordinates(),
        coordinates(),
        CardinalDirections.translate(coordinates(), lower_exit_direction),
    ])
    if entity.coordinates() == coordinates() && entity.get_grid_anchor_direction() == CardinalDirections.CardinalDirection.NONE:
        print_debug("Landing")

        var upper_entry_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, CardinalDirections.invert(upper_exit_direction))
        var lower_exit_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, lower_exit_direction)
        var ramp_rotation: Quaternion = QuaternionUtils.look_rotation(ramp_look_going_up_direction * -1, ramp_normal_direction)

        var exit_node_coordinates: Vector3i = CardinalDirections.translate(coordinates(), lower_exit_direction)
        var exit_node: GridNode = get_level().get_grid_node(exit_node_coordinates)
        exit_anchor = exit_node.get_grid_anchor(down) if exit_node != null else null

        var mid_point: Vector3 = lerp(upper_point, lower_point, 0.5)

        # Handle reasons to refuse
        if (
            exit_anchor == null
            || exit_node == null
            || !get_grid_node().may_exit(entity, up_direction)
            || !exit_node.may_enter(entity, get_grid_node(), upper_exit_direction, down)
        ):
            _animate_refuse(entity, lower_point, animation_duration * lower_duration_fraction)
            rotations.kill()
            return

        # Easings and such
        @warning_ignore_start("return_value_discarded")
        translations.tween_property(entity, "global_position", mid_point, animation_duration * lower_duration_fraction)
        if animation_mode == AnimationMode.Ramp:
            translations.tween_property(entity, "global_position", lower_point, animation_duration * ramp_duration_fraction)
        else:
            var upaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(up_direction)
            var directionaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(lower_exit_direction)
            @warning_ignore_start("integer_division")
            var steps: int = stair_steps / 2
            @warning_ignore_restore("integer_division")
            var step_duration: float = animation_duration * ramp_duration_fraction / steps
            for idx: int in range(steps):
                var target: Vector3 = lerp(mid_point, lower_point, (1.0 + idx) / steps)
                translations.tween_property(entity, "global_position:%s" % upaxis_name, CardinalDirections.vector_axis_value(target, up_direction), step_duration).set_trans(Tween.TRANS_BACK)
                translations.parallel().tween_property(entity, "global_position:%s" % directionaxis_name, CardinalDirections.vector_axis_value(target, lower_exit_direction), step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

        translations.tween_property(entity, "global_position", exit_anchor.global_position, animation_duration * ramp_upper_duration_fraction)

        rotations.tween_method(
            update_rotation,
            entity.global_transform.basis.get_rotation_quaternion(),
            upper_entry_rotation,
            animation_duration * (lower_duration_fraction - 0.5 * pivot_duration_fraction),
        )

        if animation_mode == AnimationMode.Ramp:
            rotations.tween_method(
                update_rotation,
                lower_exit_rotation,
                ramp_rotation,
                animation_duration * pivot_duration_fraction
            )
            rotations.tween_method(rotation_pause, 0.0, 1.0, animation_duration * (ramp_duration_fraction - pivot_duration_fraction))
            rotations.tween_method(
                update_rotation,
                ramp_rotation,
                lower_exit_direction,
                animation_duration * pivot_duration_fraction
            )

        @warning_ignore_restore("return_value_discarded")
    elif entity.coordinates() == CardinalDirections.translate(coordinates(), lower_exit_direction):
        print_debug("Going up")

        var upper_exit_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, upper_exit_direction)
        var lower_entry_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, CardinalDirections.invert(lower_exit_direction))
        var ramp_rotation: Quaternion = QuaternionUtils.look_rotation(ramp_look_going_up_direction, ramp_normal_direction)

        var intermediate_coordinates: Vector3i = CardinalDirections.translate(coordinates(), up_direction)
        var exit_node_coordinates: Vector3i = CardinalDirections.translate(intermediate_coordinates, upper_exit_direction)
        var intermediate: GridNode = get_level().get_grid_node(intermediate_coordinates)
        var exit_node: GridNode = get_level().get_grid_node(exit_node_coordinates)
        exit_anchor = exit_node.get_grid_anchor(down) if exit_node != null else null

        # Handle reasons to refuse
        if (
            exit_anchor == null
            || exit_node == null
            || !get_grid_node().may_exit(entity, up_direction)
            || !exit_node.may_enter(entity, get_grid_node(), upper_exit_direction, down)
            || intermediate != null && !intermediate.may_transit(entity, get_grid_node(), up_direction, upper_exit_direction)
        ):
            _animate_refuse(entity, lower_point, animation_duration * lower_duration_fraction)
            rotations.kill()
            return

        # Easings and such
        @warning_ignore_start("return_value_discarded")
        translations.tween_property(entity, "global_position", lower_point, animation_duration * lower_duration_fraction)
        if animation_mode == AnimationMode.Ramp:
            translations.tween_property(entity, "global_position", upper_point, animation_duration * ramp_duration_fraction)
        else:
            var upaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(up_direction)
            var directionaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(upper_exit_direction)
            var step_duration: float = animation_duration * ramp_duration_fraction / stair_steps
            for idx: int in range(stair_steps):
                var target: Vector3 = lerp(lower_point, upper_point, (1.0 + idx) / stair_steps)
                translations.tween_property(entity, "global_position:%s" % upaxis_name, CardinalDirections.vector_axis_value(target, up_direction), step_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
                translations.parallel().tween_property(entity, "global_position:%s" % directionaxis_name, CardinalDirections.vector_axis_value(target, upper_exit_direction), step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        translations.tween_property(entity, "global_position", exit_anchor.global_position, animation_duration * ramp_upper_duration_fraction)

        rotations.tween_method(
            update_rotation,
            entity.global_transform.basis.get_rotation_quaternion(),
            lower_entry_rotation,
            animation_duration * (lower_duration_fraction - 0.5 * pivot_duration_fraction),
        )

        if animation_mode == AnimationMode.Ramp:
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
        @warning_ignore_restore("return_value_discarded")

        exit_direction = upper_exit_direction
    else:
        print_debug("Going down")

        var upper_entry_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, CardinalDirections.invert(upper_exit_direction))
        var lower_exit_rotation: Quaternion = CardinalDirections.direction_to_rotation(up_direction, lower_exit_direction)
        var ramp_rotation: Quaternion = QuaternionUtils.look_rotation(ramp_look_going_up_direction * -1, ramp_normal_direction)

        var exit_node_coordinates: Vector3i = CardinalDirections.translate(coordinates(), lower_exit_direction)
        var exit_node: GridNode = get_level().get_grid_node(exit_node_coordinates)
        exit_anchor = exit_node.get_grid_anchor(down) if exit_node != null else null

        # Handle reasons to refuse
        if (
            exit_anchor == null
            || exit_node == null
            || !get_grid_node().may_exit(entity, up_direction)
            || !exit_node.may_enter(entity, get_grid_node(), lower_exit_direction, down)
        ):
            _animate_refuse(entity, lower_point, animation_duration * lower_duration_fraction)
            rotations.kill()
            return

        # Easings and such
        @warning_ignore_start("return_value_discarded")
        translations.tween_property(entity, "global_position", upper_point, animation_duration * ramp_upper_duration_fraction)
        if animation_mode == AnimationMode.Ramp:
            translations.tween_property(entity, "global_position", lower_point, animation_duration * ramp_duration_fraction * 0.5)
        else:
            var upaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(up_direction)
            var directionaxis_name: String = CardinalDirections.direction_to_axis_parameter_name(lower_exit_direction)
            var step_duration: float = animation_duration * ramp_duration_fraction / stair_steps
            for idx: int in range(stair_steps):
                var target: Vector3 = lerp(upper_point, lower_point, (1.0 + idx) / stair_steps)
                translations.tween_property(entity, "global_position:%s" % upaxis_name, CardinalDirections.vector_axis_value(target, up_direction), step_duration).set_trans(Tween.TRANS_BACK)
                translations.parallel().tween_property(entity, "global_position:%s" % directionaxis_name, CardinalDirections.vector_axis_value(target, lower_exit_direction), step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        translations.tween_property(entity, "global_position", exit_anchor.global_position, animation_duration * lower_duration_fraction)

        rotations.tween_method(
            update_rotation,
            entity.global_transform.basis.get_rotation_quaternion(),
            upper_entry_rotation,
            animation_duration * (lower_duration_fraction - 0.5 * pivot_duration_fraction),
        )
        if animation_mode == AnimationMode.Ramp:
            rotations.tween_method(
                update_rotation,
                upper_entry_rotation,
                ramp_rotation,
                animation_duration * pivot_duration_fraction
            )
            rotations.tween_method(rotation_pause, 0.0, 1.0, animation_duration * (ramp_duration_fraction - pivot_duration_fraction) * 0.5)
            rotations.tween_method(
                update_rotation,
                ramp_rotation,
                lower_exit_rotation,
                animation_duration * pivot_duration_fraction
            )
        @warning_ignore_restore("return_value_discarded")

    @warning_ignore_start("return_value_discarded")
    translations.finished.connect(
        func () -> void:
            entity.set_grid_anchor(exit_anchor)
            entity.sync_position()

            entity.look_direction = exit_direction
            entity.down = down
            entity.orient()

            entity.remove_concurrent_movement_block()
            entity.cinematic = false

            _transporting_entities.erase(entity)
            entity.end_movement(movement, false, true)
    )
    @warning_ignore_restore("return_value_discarded")

    translations.play()

func _animate_refuse(entity: GridEntity, refuse_point: Vector3, step_duration: float) -> void:
    @warning_ignore_start("return_value_discarded")
    translations.tween_property(entity, "global_position", refuse_point, step_duration)
    translations.tween_property(entity, "global_position", entity.global_position, step_duration)
    translations.finished.connect(
        func () -> void:
            entity.orient()

            _transporting_entities.erase(entity)

            entity.remove_concurrent_movement_block()
            entity.cinematic = false
    )
    @warning_ignore_restore("return_value_discarded")

    translations.play()

func blocks_entry_translation(
    entity: GridEntity,
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
    silent: bool = false,
) -> bool:
    if super.blocks_entry_translation(entity, from, move_direction, to_side):
        return true

    if !_can_climb(entity, silent):
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
            if !silent:
                print_debug("Walking in to ramp %s" % CardinalDirections.name(upper_exit_direction))
            return true

        if !silent:
            print_debug("Entering ramp properly from %s" % CardinalDirections.name(upper_exit_direction))
        return false

    if !silent:
        print_debug("Not entering ramp at %s from %s was %s" % [coordinates(), expected_from, from.coordinates])
    return false

func _can_climb(_entity: GridEntity, _silent: bool) -> bool:
    return true
