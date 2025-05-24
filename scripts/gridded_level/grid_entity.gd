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

func attempt_move(move_direction: CardinalDirections.CardinalDirection) -> bool:
    if node == null:
        push_error("Player %s not inside dungeon")
        return false

    if node.may_exit(self, move_direction):
        var neighbour: GridNode = node.neighbour(move_direction)
        if neighbour != null && neighbour.may_enter(self, move_direction):
            node = neighbour
            global_position = neighbour.global_position
            parent_to_node()

            return true
    return false

func attempt_rotate(clockwise: bool) -> bool:
    if clockwise:
        look_direction = CardinalDirections.yaw_cw(look_direction, down)
    else:
        look_direction = CardinalDirections.yaw_ccw(look_direction, down)
    orient()
    return true

func orient() -> void:
    look_at(
        global_position + Vector3(CardinalDirections.direction_to_vector(look_direction)),
        CardinalDirections.direction_to_vector(CardinalDirections.invert(down)),
    )
