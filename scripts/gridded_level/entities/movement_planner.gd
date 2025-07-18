extends Node3D
class_name MovementPlanner

@export
var entity: GridEntity

@export
var translation_time: float = 0.4

@export
var fall_time: float = 0.25

@export
var exotic_translation_time: float = 0.5

@export
var turn_time: float = 0.3

@export
var animation_speed: float = 1.0

@export
var tank_movement: bool

const _UNHANDLED: int = 0
const _HANDLED: int = 1
const _HANDLED_REFUSED: int = 2

func move_entity(
    movement: Movement.MovementType,
    move_direction: CardinalDirections.CardinalDirection,
) -> Tween:
    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_error("Player %s not inside dungeon")
        return null

    var anchor: GridAnchor = entity.get_grid_anchor()
    var tween: Tween = entity.create_tween().set_parallel()

    var was_excotic_walk: bool = entity.transportation_mode.has_any(TransportationMode.EXOTIC_WALKS)

    # We're in the air but moving onto an anchor of the current node
    var handled: int = _handle_landing(movement, tween, node, anchor, move_direction)

    if handled:
        return tween if handled == _HANDLED else null

    handled = _handle_node_transition(movement, tween, node, anchor, move_direction, was_excotic_walk)
    if handled:
        return tween if handled == _HANDLED else null

    handled = _handle_node_inner_corner_transition(movement, tween, node, anchor, move_direction)
    if handled:
        return tween if handled == _HANDLED else null

    tween.kill()
    return null

func rotate_entity(
    movement: Movement.MovementType,
    clockwise: bool,
) -> Tween:
    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_error("Player %s not inside dungeon")
        return null

    var up: CardinalDirections.CardinalDirection = CardinalDirections.invert(entity.down)

    var target_look_direction: CardinalDirections.CardinalDirection
    if clockwise:
        target_look_direction = CardinalDirections.yaw_cw(entity.look_direction, entity.down)[0]
    else:
        target_look_direction = CardinalDirections.yaw_ccw(entity.look_direction, entity.down)[0]

    var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vector(target_look_direction)),
        Vector3(CardinalDirections.direction_to_vector(up)),
        )

    var tween: Tween = entity.create_tween()

    # print_debug("%s/%s scale from start -> %s scale at end" % [
        # entity.transform.basis.get_scale(),
        # entity.global_transform.basis.get_scale(),
        # final_rotation.basis.get_scale()])

    var method_tweener: MethodTweener = tween.tween_method(
        func (value: Basis) -> void:
            entity.global_rotation = value.get_euler(),
        entity.global_basis,
        final_rotation.basis,
        turn_time / animation_speed
    )

    @warning_ignore_start("return_value_discarded")
    if !tank_movement:
         method_tweener.set_trans(Tween.TRANS_SINE)

    tween.connect(
        "finished",
        func () -> void:
            entity.look_direction = target_look_direction
            entity.orient()
            entity.end_movement(movement))
    @warning_ignore_restore("return_value_discarded")

    return tween


func _handle_landing(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> int:
    if anchor == null:
        var land_anchor: GridAnchor = node.get_grid_anchor(move_direction)
        if land_anchor != null && land_anchor.can_anchor(entity):
            var events: Array[GridEvent] = node.triggering_events(
                entity,
                entity.get_grid_node(),
                entity.get_grid_anchor_direction(),
                land_anchor.direction,
            )

            if events.any(func (evt: GridEvent) -> bool: return evt.manages_triggering_translation()):
                tween.kill()
                return _HANDLED_REFUSED

            var prop_tweener: PropertyTweener = tween.tween_property(
                entity,
                "global_position",
                land_anchor.global_position,
                fall_time * 0.5 / animation_speed)

            entity.update_entity_anchorage(node, land_anchor)

            @warning_ignore_start("return_value_discarded")
            if !tank_movement:
                prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

            tween.connect(
                "finished",
                func () -> void:
                    entity.sync_position()
                    entity.end_movement(movement))
            @warning_ignore_restore("return_value_discarded")

            return _HANDLED
    return _UNHANDLED

func _handle_node_transition(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    was_excotic_walk: bool,
) -> int:
    if node.may_exit(entity, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour == null:
            print_debug("No tile in %s direction" % CardinalDirections.name(move_direction))
            return _UNHANDLED

        var handled: int = _handle_outer_corner_transition(movement, tween, anchor, move_direction, neighbour)
        if handled:
            print_debug("Outer corner")
            return handled

        if neighbour.may_enter(entity, move_direction, entity.down):

            var neighbour_anchor: GridAnchor = neighbour.get_grid_anchor(entity.down)

            if was_excotic_walk && !entity.can_jump_off_walls && neighbour_anchor == null:
                return _UNHANDLED

            var events: Array[GridEvent] = neighbour.triggering_events(
                entity,
                entity.get_grid_node(),
                entity.get_grid_anchor_direction(),
                entity.down,
            )

            if events.any(func (evt: GridEvent) -> bool: return evt.manages_triggering_translation()):
                tween.kill()
                return _HANDLED_REFUSED

            if neighbour_anchor != null:
                # Normal movement between two tiles keeping the same down
                entity.update_entity_anchorage(neighbour, neighbour_anchor)

                @warning_ignore_start("return_value_discarded")
                var prop_tweener: PropertyTweener = tween.tween_property(
                    entity,
                    "global_position",
                    neighbour_anchor.global_position,
                    translation_time / animation_speed)

                if !tank_movement:
                    prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

                tween.connect(
                    "finished",
                    func () -> void:
                        entity.sync_position()
                        entity.end_movement(movement))
                @warning_ignore_restore("return_value_discarded")

                print_debug("Normal move no exotics")
                return _HANDLED

            print_debug("%s has no anchor %s" % [neighbour.name, CardinalDirections.name(entity.down)])
            entity.block_concurrent_movement()

            @warning_ignore_start("return_value_discarded")
            tween.tween_property(
                entity,
                "global_position",
                neighbour.get_center_pos(),
                translation_time / animation_speed)

            entity.update_entity_anchorage(neighbour, null)

            if was_excotic_walk:
                var end_look_direction: CardinalDirections.CardinalDirection = entity.look_direction
                if entity.look_direction == CardinalDirections.CardinalDirection.DOWN:
                    end_look_direction = CardinalDirections.pitch_up(entity.look_direction, entity.down)[0]
                elif entity.look_direction == CardinalDirections.CardinalDirection.UP:
                    end_look_direction = CardinalDirections.pitch_down(entity.look_direction, entity.down)[0]
                var end_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

                var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
                    Vector3(CardinalDirections.direction_to_vector(end_look_direction)),
                    Vector3(CardinalDirections.direction_to_vector(CardinalDirections.CardinalDirection.UP)))

                events = neighbour.triggering_events(
                    entity,
                    entity.get_grid_node(),
                    entity.get_grid_anchor_direction(),
                    end_down,
                )

                if events.any(func (evt: GridEvent) -> bool: return evt.manages_triggering_translation()):
                    tween.kill()
                    return _HANDLED_REFUSED

                tween.tween_method(
                    func (value: Basis) -> void:
                        entity.global_rotation = value.get_euler(),
                    entity.global_basis,
                    final_rotation.basis,
                    translation_time / animation_speed)

                tween.connect(
                    "finished",
                    func () -> void:
                        entity.sync_position()
                        entity.look_direction = end_look_direction
                        entity.down = end_down
                        entity.orient()
                        entity.remove_concurrent_movement_block()
                        entity.end_movement(movement))

                print_debug("exotic jump-off")
                return _HANDLED

            tween.connect(
                "finished",
                func () -> void:
                    entity.sync_position()
                    entity.remove_concurrent_movement_block()
                    entity.end_movement(movement))
            @warning_ignore_restore("return_value_discarded")

            print_debug("normal jump-off")
            return _HANDLED

    print_debug("not allowed to exit")
    return _UNHANDLED

func _handle_outer_corner_transition(
    movement: Movement.MovementType,
    tween: Tween,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    neighbour: GridNode,
) -> int:
    if anchor == null || !neighbour.may_transit(entity, move_direction, entity.down):
        # if anchor == null:
            # print_debug("Anchor is null")
        # else:
            # print_debug("We may not transit %s entering %s exiting %s" % [neighbour.name, move_direction, entity.down])
        return _UNHANDLED

    var updated_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.calculate_outer_corner(
        move_direction, entity.look_direction, entity.down)

    var target: GridNode = neighbour.neighbour(entity.down)
    if target == null || !target.may_enter(entity, entity.down, updated_directions[1]):
        # if target == null:
            # print_debug("Target is null")
        # else:
            # print_debug("We may not enter %s from %s" % [target.name, entity.down])
        return _UNHANDLED


    var target_anchor: GridAnchor = target.get_grid_anchor(updated_directions[1])

    if target_anchor == null || !target_anchor.can_anchor(entity):
        # if target_anchor == null:
            # print_debug("%s doesn't have an anchor %s" % [target.name, updated_directions[1]])
        # else:
            # print_debug("%s of %s doesn't alow us to anchor" % [target_anchor.name, target.name])
        return _UNHANDLED

    var events: Array[GridEvent] = target.triggering_events(
        entity,
        entity.get_grid_node(),
        entity.get_grid_anchor_direction(),
        target_anchor.direction,
    )

    if events.any(func (evt: GridEvent) -> bool: return evt.manages_triggering_translation()):
        tween.kill()
        return _HANDLED_REFUSED

    _handle_corner(
        movement,
        tween,
        entity.get_grid_node(),
        anchor,
        target_anchor,
        move_direction,
        CardinalDirections.invert(entity.down),
        updated_directions
    )
    return _HANDLED


func _handle_node_inner_corner_transition(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> int:
    var target_anchor: GridAnchor = node.get_grid_anchor(move_direction)

    if target_anchor == null || anchor == null || !target_anchor.can_anchor(entity):
        return _UNHANDLED

    var events: Array[GridEvent] = node.triggering_events(
        entity,
        entity.get_grid_node(),
        entity.get_grid_anchor_direction(),
        target_anchor.direction,
    )

    if events.any(func (evt: GridEvent) -> bool: return evt.manages_triggering_translation()):
        tween.kill()
        return _HANDLED_REFUSED

    var updated_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.calculate_innner_corner(
        move_direction, entity.look_direction, entity.down)

    _handle_corner(
        movement,
        tween,
        node,
        anchor,
        target_anchor,
        move_direction,
        entity.down,
        updated_directions
    )

    print_debug("inner corner")
    return _HANDLED

func _handle_corner(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    target_anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    target_anchor_edge: CardinalDirections.CardinalDirection,
    updated_directions: Array[CardinalDirections.CardinalDirection],
) -> void:
    var start_edge: Vector3 = anchor.get_edge_position(move_direction)
    var target_edge: Vector3 = target_anchor.get_edge_position(target_anchor_edge)
    var intermediate: Vector3 = lerp(start_edge, target_edge, 0.5)

    var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vector(updated_directions[0])),
        Vector3(CardinalDirections.direction_to_vector(CardinalDirections.invert(updated_directions[1]))),
        )

    var intermediate_rotation: Quaternion = lerp(entity.global_transform.basis.get_rotation_quaternion(), final_rotation.basis.get_rotation_quaternion(), 0.5)
    var half_time: float = exotic_translation_time * 0.5 / animation_speed

    entity.block_concurrent_movement()

    entity.update_entity_anchorage(node, target_anchor)

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        entity,
        "global_position",
        intermediate,
        half_time)

    var meth_tweener: MethodTweener = tween.tween_method(
        func (value: Quaternion) -> void:
            entity.global_rotation = value.get_euler(),
        entity.global_basis.get_rotation_quaternion(),
        intermediate_rotation,
        half_time)

    if !tank_movement:
        meth_tweener.set_trans(Tween.TRANS_QUAD)

    var second_tween: Tween = tween.chain()
    second_tween.tween_property(
        entity,
        "global_position",
        target_anchor.global_position,
        half_time)

    var meth_tweener2: MethodTweener = second_tween.tween_method(
        func (value: Quaternion) -> void:
            entity.global_rotation = value.get_euler(),
        intermediate_rotation,
        final_rotation.basis.get_rotation_quaternion(),
        half_time)

    if !tank_movement:
        meth_tweener2.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    second_tween.connect(
        "finished",
        func () -> void:
            entity.sync_position()
            entity.look_direction = updated_directions[0]
            entity.down = updated_directions[1]
            entity.orient()
            entity.remove_concurrent_movement_block()
            entity.end_movement(movement))

    @warning_ignore_restore("return_value_discarded")
