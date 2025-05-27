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

func move_entity(move_direction: CardinalDirections.CardinalDirection) -> Tween:
    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_error("Player %s not inside dungeon")
        return null

    var anchor: GridAnchor = entity.get_grid_anchor()
    var tween: Tween = entity.create_tween().set_parallel()

    var was_excotic_walk: bool = entity.transportation_mode.has_any(TransportationMode.EXOTIC_WALKS)

    # We're in the air but moving onto an anchor of the current node
    if _handle_landing(tween, node, anchor, move_direction):
        return tween

    if _handle_node_transition(tween, node, anchor, move_direction, was_excotic_walk):
        return tween

    if !_handle_node_inner_corner_transition(tween, node, anchor, move_direction):
        tween.kill()
        return null
    return tween

func rotate_entity(clockwise: bool) -> Tween:
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

    @warning_ignore_start("return_value_discarded")
    tween.tween_method(
        func (value: Basis) -> void:
            entity.global_rotation = value.get_euler(),
        entity.global_basis,
        final_rotation.basis,
        turn_time
    )

    tween.connect(
        "finished",
        func () -> void:
            entity.look_direction = target_look_direction
            entity.orient()
            entity.set_is_moving(false))
    @warning_ignore_restore("return_value_discarded")

    return tween


func _handle_landing(
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> bool:
    if anchor == null:
        var land_anchor: GridAnchor = node.get_anchor(move_direction)
        if land_anchor != null && land_anchor.can_anchor(entity):

            @warning_ignore_start("return_value_discarded")
            tween.tween_property(
                entity,
                "global_position",
                land_anchor.global_position,
                fall_time * 0.5)

            tween.connect(
                "finished",
                func () -> void:
                    entity.update_entity_anchorage(node, land_anchor)
                    entity.sync_position()
                    entity.set_is_moving(false))
            @warning_ignore_restore("return_value_discarded")

            return true
    return false

func _handle_node_transition(
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    was_excotic_walk: bool,
) -> bool:
    if node.may_exit(entity, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour != null && neighbour.may_enter(entity, move_direction):

            var neighbour_anchor: GridAnchor = neighbour.get_anchor(entity.down)

            if neighbour_anchor == null && _handle_outer_corner_transition(tween, anchor, move_direction, neighbour):
                return true

            if was_excotic_walk && !entity.can_jump_off_walls && neighbour_anchor == null:
                return false

            if neighbour_anchor != null:
                @warning_ignore_start("return_value_discarded")
                tween.tween_property(
                    entity,
                    "global_position",
                    neighbour_anchor.global_position,
                    translation_time)

                tween.connect(
                    "finished",
                    func () -> void:
                        entity.update_entity_anchorage(neighbour, neighbour_anchor)
                        entity.sync_position()
                        entity.set_is_moving(false))
                @warning_ignore_restore("return_value_discarded")

                return true


            @warning_ignore_start("return_value_discarded")
            tween.tween_property(
                entity,
                "global_position",
                neighbour.get_center_pos(),
                translation_time)

            if was_excotic_walk && neighbour_anchor == null:
                var end_look_direction: CardinalDirections.CardinalDirection = entity.look_direction
                if entity.look_direction == CardinalDirections.CardinalDirection.DOWN:
                    end_look_direction = CardinalDirections.pitch_up(entity.look_direction, entity.down)[0]
                elif entity.look_direction == CardinalDirections.CardinalDirection.UP:
                    end_look_direction = CardinalDirections.pitch_down(entity.look_direction, entity.down)[0]
                var end_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

                var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
                    Vector3(CardinalDirections.direction_to_vector(end_look_direction)),
                    Vector3(CardinalDirections.direction_to_vector(CardinalDirections.CardinalDirection.UP)))

                tween.tween_method(
                    func (value: Basis) -> void:
                        entity.global_rotation = value.get_euler(),
                    entity.global_basis,
                    final_rotation.basis,
                    translation_time)

                tween.connect(
                    "finished",
                    func () -> void:
                        entity.update_entity_anchorage(neighbour, neighbour_anchor)
                        entity.sync_position()
                        entity.look_direction = end_look_direction
                        entity.down = end_down
                        entity.orient()
                        entity.set_is_moving(false))

                return true


            tween.connect(
                "finished",
                func () -> void:
                    entity.update_entity_anchorage(neighbour, neighbour_anchor)
                    entity.sync_position()
                    entity.set_is_moving(false))

            @warning_ignore_restore("return_value_discarded")

            return true
    return false

func _handle_outer_corner_transition(
    tween: Tween,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    neighbour: GridNode,
) -> bool:
    if anchor == null || !neighbour.may_transit(entity, move_direction, entity.down):
        return false

    var target: GridNode = neighbour.neighbour(entity.down)
    if target == null || !target.may_enter(entity, entity.down):
        return false

    var updated_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.calculate_outer_corner(
        move_direction, entity.look_direction, entity.down)

    var target_anchor: GridAnchor = target.get_anchor(updated_directions[1])

    if target_anchor == null || !target_anchor.can_anchor(entity):
        return false

    _handle_corner(
        tween,
        entity.get_grid_node(),
        anchor,
        target_anchor,
        move_direction,
        updated_directions
    )
    return true


func _handle_node_inner_corner_transition(
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
) -> bool:
    var target_anchor: GridAnchor = node.get_anchor(move_direction)

    if target_anchor == null || anchor == null || !target_anchor.can_anchor(entity):
        return false


    var updated_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.calculate_innner_corner(
        move_direction, entity.look_direction, entity.down)

    _handle_corner(
        tween,
        node,
        anchor,
        target_anchor,
        move_direction,
        updated_directions
    )

    return true

func _handle_corner(
    tween: Tween,
    node: GridNode,
    anchor: GridAnchor,
    target_anchor: GridAnchor,
    move_direction: CardinalDirections.CardinalDirection,
    updated_directions: Array[CardinalDirections.CardinalDirection],
) -> void:
    var start_edge: Vector3 = anchor.get_edge_position(move_direction)
    var target_edge: Vector3 = target_anchor.get_edge_position(CardinalDirections.invert(entity.down))
    var intermediate: Vector3 = lerp(start_edge, target_edge, 0.5)

    var final_rotation: Transform3D = Transform3D.IDENTITY.looking_at(
        Vector3(CardinalDirections.direction_to_vector(updated_directions[0])),
        Vector3(CardinalDirections.direction_to_vector(CardinalDirections.invert(updated_directions[1]))),
        )
    var intermediate_rotation: Basis = lerp(entity.global_transform.basis, final_rotation.basis, 0.5)
    var half_time: float = translation_time * 0.5

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        entity,
        "global_position",
        intermediate,
        half_time)

    tween.tween_method(
        func (value: Basis) -> void:
            entity.global_rotation = value.get_euler(),
        entity.global_basis,
        intermediate_rotation,
        half_time).set_trans(Tween.TRANS_QUAD)

    var second_tween: Tween = tween.chain()
    second_tween.tween_property(
        entity,
        "global_position",
        target_anchor.global_position,
        half_time)

    second_tween.tween_method(
        func (value: Basis) -> void:
            entity.global_rotation = value.get_euler(),
        intermediate_rotation,
        final_rotation.basis,
        half_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    second_tween.connect(
        "finished",
        func () -> void:
            entity.update_entity_anchorage(node, target_anchor)
            entity.sync_position()

            entity.look_direction = updated_directions[0]
            entity.down = updated_directions[1]
            entity.orient()
            entity.set_is_moving(false))

    @warning_ignore_restore("return_value_discarded")
