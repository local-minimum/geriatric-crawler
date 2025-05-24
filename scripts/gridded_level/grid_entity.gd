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

    if node.may_exit(self, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour != null && neighbour.may_enter(self, move_direction):
            global_position = neighbour.global_position

            var anchor: GridAnchor = neighbour.get_anchor(down)
            update_entity_anchorage(neighbour, anchor)

            return true

    var internal_anchor: GridAnchor = node.get_anchor(move_direction)

    if internal_anchor == null || !internal_anchor.can_anchor(self):
        return false

    update_entity_anchorage(node, internal_anchor)
    if transportation_mode.has_any(TransportationMode.EXOTIC_WALKS):
        var updated_directions: Array[CardinalDirections.CardinalDirection]  = CardinalDirections.calculate_innner_corner(move_direction, look_direction, down)
        print_debug("%s was looking %s, down %s -> looking %s, down %s" % [
            name,
            CardinalDirections.name(look_direction),
            CardinalDirections.name(down),
            CardinalDirections.name(updated_directions[0]),
            CardinalDirections.name(updated_directions[1])
        ])
        look_direction = updated_directions[0]
        down = updated_directions[1]
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

    print_debug("%s is now %s" % [name, transportation_mode.humanize()])

func attempt_rotate(clockwise: bool) -> bool:
    if clockwise:
        look_direction = CardinalDirections.yaw_cw(look_direction, down)[0]
    else:
        look_direction = CardinalDirections.yaw_ccw(look_direction, down)[0]
    orient()
    return true

func orient() -> void:
    look_at(
        global_position + Vector3(CardinalDirections.direction_to_vector(look_direction)),
        CardinalDirections.direction_to_vector(CardinalDirections.invert(down)),
    )
