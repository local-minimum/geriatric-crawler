extends GridNodeFeature
class_name GridEntity

@export
var look_direction: CardinalDirections.CardinalDirection

@export
var down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export
var transportation_abilities: TransportationMode

@export
var transportation_mode: TransportationMode

func _ready() -> void:
    super()
    orient()

func falling() -> bool:
    return transportation_mode.mode == TransportationMode.NONE

func attempt_move(move_direction: CardinalDirections.CardinalDirection) -> bool:
    var node: GridNode = get_grid_node()
    if node == null:
        push_error("Player %s not inside dungeon")
        return false

    var was_excotic_walk: bool = transportation_mode.has_any(TransportationMode.EXOTIC_WALKS)

    # We're in the air but moving onto an anchor of the current node
    if _handle_landing(node, move_direction):
        return true

    if _handle_node_transition(node, move_direction, was_excotic_walk):
        return true

    return _handle_node_internal_transition(node, move_direction, was_excotic_walk)

func _handle_landing(node: GridNode, move_direction: CardinalDirections.CardinalDirection) -> bool:
    if _anchor == null:
        var land_anchor: GridAnchor = node.get_anchor(move_direction)
        if land_anchor != null && land_anchor.can_anchor(self):
            update_entity_anchorage(node, land_anchor)
            sync_position()

            return true
    return false

func _handle_node_transition(
    node: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    was_excotic_walk: bool,
) -> bool:
    if node.may_exit(self, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour != null && neighbour.may_enter(self, move_direction):

            var anchor: GridAnchor = neighbour.get_anchor(down)
            update_entity_anchorage(neighbour, anchor)
            sync_position()

            if was_excotic_walk && anchor == null:
                if look_direction == CardinalDirections.CardinalDirection.DOWN:
                    look_direction = CardinalDirections.pitch_up(look_direction, down)[0]
                elif look_direction == CardinalDirections.CardinalDirection.UP:
                    look_direction = CardinalDirections.pitch_down(look_direction, down)[0]
                down = CardinalDirections.CardinalDirection.DOWN
                orient()

            return true
    return false

func _handle_node_internal_transition(
    node: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    was_excotic_walk: bool,
) -> bool:
    var internal_anchor: GridAnchor = node.get_anchor(move_direction)

    if internal_anchor == null || !internal_anchor.can_anchor(self):
        return false

    update_entity_anchorage(node, internal_anchor)

    if transportation_mode.has_any(TransportationMode.EXOTIC_WALKS) || was_excotic_walk:
        var updated_directions: Array[CardinalDirections.CardinalDirection]  = CardinalDirections.calculate_innner_corner(move_direction, look_direction, down)

        # print_debug("%s was looking %s, down %s -> looking %s, down %s" % [
            # name,
            # CardinalDirections.name(look_direction),
            # CardinalDirections.name(down),
            # CardinalDirections.name(updated_directions[0]),
            # CardinalDirections.name(updated_directions[1])
        # ])

        look_direction = updated_directions[0]
        down = updated_directions[1]
        sync_position()
        orient()
        return true

    return false

func update_entity_anchorage(node: GridNode, anchor: GridAnchor, deferred: bool = false) -> void:
    if anchor != null:
        set_grid_anchor(anchor, deferred)
        transportation_mode.mode = transportation_abilities.intersection(anchor.required_transportation_mode)
    else:
        set_grid_node(node, deferred)
        transportation_mode.mode = TransportationMode.NONE

    # print_debug("%s is now %s" % [name, transportation_mode.humanize()])
    # print_stack()

func attempt_rotate(clockwise: bool) -> bool:
    if clockwise:
        look_direction = CardinalDirections.yaw_cw(look_direction, down)[0]
    else:
        look_direction = CardinalDirections.yaw_ccw(look_direction, down)[0]
    orient()
    return true

func sync_position() -> void:
    var anchor: GridAnchor = get_grid_anchor()
    if anchor != null:
        global_position = anchor.global_position
        return

    var node: GridNode = get_grid_node()
    if node != null:
        global_position = node.get_center_pos()

func orient() -> void:
    look_at(
        global_position + Vector3(CardinalDirections.direction_to_vector(look_direction)),
        CardinalDirections.direction_to_vector(CardinalDirections.invert(down)),
    )
