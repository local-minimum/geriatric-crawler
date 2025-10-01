extends Node3D
class_name MovementPlanner

@export var entity: GridEntity

@export var translation_time: float = 0.4

@export var fall_time: float = 0.25

@export var exotic_translation_time: float = 0.5

@export var turn_time: float = 0.3

@export var animation_speed: float = 1.0

@export var tank_movement: bool

@export var _refuse_distance_factor: float = 0.45

const _UNHANDLED: int = 0
const _HANDLED: int = 1
const _HANDLED_EVENT_MANAGED: int = 2
const _HANDLED_REFUSED: int = 3

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
    var handled: int = _handle_center(movement, tween, node, anchor)
    if handled:
        if handled == _HANDLED_REFUSED:
            _refuse_translation(movement, tween, node, anchor, move_direction)
        return tween if handled != _HANDLED_EVENT_MANAGED else null

    handled = _handle_landing(movement, tween, node, anchor, move_direction)
    if handled:
        if handled == _HANDLED_REFUSED:
            _refuse_translation(movement, tween, node, anchor, move_direction)
        return tween if handled != _HANDLED_EVENT_MANAGED else null

    handled = _handle_node_transition(movement, tween, node, anchor, move_direction, was_excotic_walk)
    if handled:
        if handled == _HANDLED_REFUSED:
            _refuse_translation(movement, tween, node, anchor, move_direction)
        return tween if handled != _HANDLED_EVENT_MANAGED else null

    handled = _handle_node_inner_corner_transition(movement, tween, node, anchor, move_direction)
    if handled:
        if handled == _HANDLED_REFUSED:
            _refuse_translation(movement, tween, node, anchor, move_direction)
        return tween if handled != _HANDLED_EVENT_MANAGED else null

    tween.kill()
    return null

func rotate_entity(
    movement: Movement.MovementType,
) -> Tween:
    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_error("Player %s not inside dungeon")
        return null

    var up: CardinalDirections.CardinalDirection = CardinalDirections.invert(entity.down)

    var target_look_direction: CardinalDirections.CardinalDirection
    match movement:
        Movement.MovementType.TURN_CLOCKWISE:
            target_look_direction = CardinalDirections.yaw_cw(entity.look_direction, entity.down)[0]
        Movement.MovementType.TURN_COUNTER_CLOCKWISE:
            target_look_direction = CardinalDirections.yaw_ccw(entity.look_direction, entity.down)[0]
        _:
            push_error("Movement %s is not a rotation" % Movement.name(movement))
            return null

    var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vectori(target_look_direction)),
        Vector3(CardinalDirections.direction_to_vectori(up)),
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

    tween.finished.connect(
        func () -> void:
            entity.look_direction = target_look_direction
            entity.orient()
            entity.end_movement(movement))
    @warning_ignore_restore("return_value_discarded")

    return tween

func _refuse_translation(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> void:
    var origin: Vector3 = anchor.global_position if anchor != null else node.get_center_pos()
    var edge: Vector3 = anchor.get_edge_position(move_direction) if anchor != null else origin + CardinalDirections.direction_to_vector(move_direction) * node.get_level().node_size * 0.1
    var distance: float = _refuse_distance_factor * 0.15 if CardinalDirections.is_parallell(move_direction, entity.down) else _refuse_distance_factor
    print_debug("[Movement Planner] Refuse movement %s, using distance %s to edge" % [CardinalDirections.name(move_direction), distance])
    var target: Vector3 = lerp(origin, edge, distance)

    @warning_ignore_start("return_value_discarded")
    var prop_tweener: PropertyTweener = tween.tween_property(
        entity,
        "global_position",
        target,
        translation_time * 0.5 / animation_speed)

    if !tank_movement:
        prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    var second_tween: Tween = tween.chain()
    prop_tweener = second_tween.tween_property(
        entity,
        "global_position",
        origin,
        translation_time * 0.5 / animation_speed)

    if !tank_movement:
        prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    tween.finished.connect(
        func () -> void:
            entity.sync_position()
            entity.end_movement(movement))
    @warning_ignore_restore("return_value_discarded")

    print_debug("Refusing translation movement %s for %s" % [CardinalDirections.name(move_direction), entity])

func _handle_center(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
) -> int:
    if movement != Movement.MovementType.CENTER:
        return _UNHANDLED

    if anchor != null:
        if entity.cinematic || entity.transportation_abilities.has_flag(TransportationMode.FLYING):
            var center: Vector3 = node.get_center_pos()
            var prop_tweener: PropertyTweener = tween.tween_property(
                entity,
                "global_position",
                center,
                translation_time * 0.5 / animation_speed)

            entity.update_entity_anchorage(node, null)

            @warning_ignore_start("return_value_discarded")
            if !tank_movement:
                prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

            tween.finished.connect(
                func () -> void:
                    entity.sync_position()
                    entity.end_movement(movement))
            @warning_ignore_restore("return_value_discarded")

            print_debug("lifting")
            return _HANDLED

    return _HANDLED_REFUSED

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

            if _check_handled_by_event_and_trigger(events, movement):
                tween.kill()
                print_debug("event manages landing")
                return _HANDLED_EVENT_MANAGED

            var prop_tweener: PropertyTweener = tween.tween_property(
                entity,
                "global_position",
                land_anchor.global_position,
                fall_time * 0.5 / animation_speed)

            entity.update_entity_anchorage(node, land_anchor)

            @warning_ignore_start("return_value_discarded")
            if !tank_movement:
                prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

            tween.finished.connect(
                func () -> void:
                    entity.sync_position()
                    entity.end_movement(movement))
            @warning_ignore_restore("return_value_discarded")

            print_debug("landing")
            return _HANDLED
    return _UNHANDLED

func _handle_node_transition(
    movement: Movement.MovementType,
    tween: Tween,
    from: GridNode,
    from_anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    was_excotic_walk: bool,
) -> int:
    if from.may_exit(entity, move_direction, false, true):
        var target: GridNode = from.neighbour(move_direction)
        if target == null:
            print_debug("No tile in %s direction" % CardinalDirections.name(move_direction))
            return _UNHANDLED

        # If we are doing outer corner, the assumed target is actually the imtermediate node
        var handled: int = _handle_outer_corner_transition(movement, tween, from, from_anchor, move_direction, target)
        if handled:
            print_debug("Outer corner")
            return handled

        var is_flying: bool = entity.transportation_mode.has_flag(TransportationMode.FLYING)
        if target.may_enter(
            entity,
            from,
            move_direction,
            CardinalDirections.CardinalDirection.NONE if is_flying else entity.down,
            false,
            false,
            true
        ):

            var neighbour_anchor: GridAnchor = null if is_flying else target.get_grid_anchor(entity.down)

            if was_excotic_walk && !entity.can_jump_off_walls && neighbour_anchor == null:
                return _UNHANDLED

            var events: Array[GridEvent] = target.triggering_events(
                entity,
                entity.get_grid_node(),
                entity.get_grid_anchor_direction(),
                entity.down,
            )

            if _check_handled_by_event_and_trigger(events, movement):
                tween.kill()
                print_debug("event manages normal same side translation")
                return _HANDLED_EVENT_MANAGED

            if neighbour_anchor != null:
                # Normal movement between two tiles keeping the same down
                entity.update_entity_anchorage(target, neighbour_anchor)

                @warning_ignore_start("return_value_discarded")
                var prop_tweener: PropertyTweener = tween.tween_property(
                    entity,
                    "global_position",
                    neighbour_anchor.global_position,
                    translation_time / animation_speed)

                if !tank_movement:
                    prop_tweener.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

                tween.finished.connect(
                    func () -> void:
                        entity.sync_position()
                        entity.end_movement(movement))
                @warning_ignore_restore("return_value_discarded")

                print_debug("Normal move no exotics")
                return _HANDLED

            print_debug("%s has no anchor %s" % [target.name, CardinalDirections.name(entity.down)])
            entity.block_concurrent_movement()

            @warning_ignore_start("return_value_discarded")
            tween.tween_property(
                entity,
                "global_position",
                target.get_center_pos(),
                translation_time / animation_speed)

            entity.update_entity_anchorage(target, null)

            if was_excotic_walk:
                var end_look_direction: CardinalDirections.CardinalDirection = entity.look_direction
                if entity.look_direction == CardinalDirections.CardinalDirection.DOWN:
                    end_look_direction = CardinalDirections.pitch_up(entity.look_direction, entity.down)[0]
                elif entity.look_direction == CardinalDirections.CardinalDirection.UP:
                    end_look_direction = CardinalDirections.pitch_down(entity.look_direction, entity.down)[0]
                var end_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

                var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
                    Vector3(CardinalDirections.direction_to_vectori(end_look_direction)),
                    Vector3(CardinalDirections.direction_to_vectori(CardinalDirections.CardinalDirection.UP)))

                events = target.triggering_events(
                    entity,
                    entity.get_grid_node(),
                    entity.get_grid_anchor_direction(),
                    end_down,
                )

                if _check_handled_by_event_and_trigger(events, movement):
                    tween.kill()
                    print_debug("event manages jump-off")
                    return _HANDLED_EVENT_MANAGED

                tween.tween_method(
                    func (value: Basis) -> void:
                        entity.global_rotation = value.get_euler(),
                    entity.global_basis,
                    final_rotation.basis,
                    translation_time / animation_speed)

                tween.finished.connect(
                    func () -> void:
                        entity.sync_position()
                        entity.look_direction = end_look_direction
                        entity.down = end_down
                        entity.orient()
                        entity.remove_concurrent_movement_block()
                        entity.end_movement(movement))

                print_debug("exotic jump-off")
                return _HANDLED

            tween.finished.connect(
                func () -> void:
                    entity.sync_position()
                    entity.remove_concurrent_movement_block()
                    entity.end_movement(movement))
            @warning_ignore_restore("return_value_discarded")

            print_debug("normal jump-off")
            return _HANDLED

    print_debug("not allowed to exit from")
    return _UNHANDLED

func _handle_outer_corner_transition(
    movement: Movement.MovementType,
    tween: Tween,
    from: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    intermediate: GridNode,
) -> int:
    if (
        anchor == null ||
        entity.transportation_mode.has_flag(TransportationMode.FLYING) ||
        !intermediate.may_transit(entity, from, move_direction, entity.down, true)
    ):
        # if anchor == null:
            # print_debug("Anchor is null")
        # else:
            # print_debug("We may not transit %s entering %s exiting %s" % [neighbour.name, move_direction, entity.down])
        return _UNHANDLED

    var updated_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.calculate_outer_corner(
        move_direction, entity.look_direction, entity.down)

    var target: GridNode = intermediate.neighbour(entity.down)
    if target == null:
        # print_debug("Target is null")
        return _UNHANDLED

    if !target.may_enter(entity, intermediate, entity.down, updated_directions[1], false, false, true):
        # print_debug("We may not enter %s from %s" % [target.name, entity.down])
        if target._entry_blocking_events(entity, from, move_direction, entity.down):
            return _HANDLED_REFUSED
        return _UNHANDLED


    var target_anchor: GridAnchor = target.get_grid_anchor(updated_directions[1])

    if target_anchor == null:
        # print_debug("%s doesn't have an anchor %s" % [target.name, updated_directions[1]])
        return _UNHANDLED

    var events: Array[GridEvent] = target.triggering_events(
        entity,
        entity.get_grid_node(),
        entity.get_grid_anchor_direction(),
        target_anchor.direction,
    )

    if _check_handled_by_event_and_trigger(events, movement):
        tween.kill()
        print_debug("event manages outer corner")
        return _HANDLED_EVENT_MANAGED

    # We only check anchorage afterwards in case the event overrides those rules
    if !target_anchor.can_anchor(entity):
        # print_debug("%s of %s doesn't alow us to anchor" % [target_anchor.name, target.name])
        return _UNHANDLED

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

    print_debug("outer corner movement")
    return _HANDLED


func _handle_node_inner_corner_transition(
    movement: Movement.MovementType,
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> int:
    var target_anchor: GridAnchor = node.get_grid_anchor(move_direction)

    if (
        target_anchor == null ||
        anchor == null ||
        entity.transportation_mode.has_flag(TransportationMode.FLYING) ||
        !target_anchor.can_anchor(entity)
    ):
        print_debug("not allowed inner corner transition (has target anchor %s)" % [target_anchor != null])
        # if target_anchor != null:
        #    print_debug("%s may anchor on %s = %s" % [entity.name, target_anchor.name, target_anchor.can_anchor(entity)])
        return _HANDLED_REFUSED

    var events: Array[GridEvent] = node.triggering_events(
        entity,
        entity.get_grid_node(),
        entity.get_grid_anchor_direction(),
        target_anchor.direction,
    )

    if _check_handled_by_event_and_trigger(events, movement):
        tween.kill()
        print_debug("event manages inner corner movement")
        return _HANDLED_EVENT_MANAGED

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

    print_debug("inner corner movement")
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

    var final_rotation: Quaternion = QuaternionUtils.look_rotation_from_vectors(updated_directions)

    var intermediate_rotation: Quaternion = lerp(entity.global_transform.basis.get_rotation_quaternion(), final_rotation, 0.5)
    var half_time: float = exotic_translation_time * 0.5 / animation_speed

    entity.block_concurrent_movement()

    entity.update_entity_anchorage(node, target_anchor)

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        entity,
        "global_position",
        intermediate,
        half_time)

    var update_rotation: Callable = QuaternionUtils.create_tween_rotation_method(entity)

    var meth_tweener: MethodTweener = tween.tween_method(
        update_rotation,
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
        update_rotation,
        intermediate_rotation,
        final_rotation,
        half_time)

    if !tank_movement:
        meth_tweener2.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    second_tween.finished.connect(
        func () -> void:
            entity.sync_position()
            entity.look_direction = updated_directions[0]
            entity.down = updated_directions[1]
            entity.orient()
            entity.remove_concurrent_movement_block()
            entity.end_movement(movement))

    @warning_ignore_restore("return_value_discarded")


func _check_handled_by_event_and_trigger(events: Array[GridEvent], movement: Movement.MovementType) -> bool:
    var handled: bool
    for event: GridEvent in events:
        if event.manages_triggering_translation():
            handled = true

        event.trigger(entity, movement)

    return handled
