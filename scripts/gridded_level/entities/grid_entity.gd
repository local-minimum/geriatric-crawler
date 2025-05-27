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

@export
var can_jump_off_walls: bool

@export
var planner: MovementPlanner

@export
var instant_step: bool

var is_moving: bool

func _ready() -> void:
    super()
    orient()

func falling() -> bool:
    return transportation_mode.mode == TransportationMode.NONE

var tween: Tween

func attempt_move(move_direction: CardinalDirections.CardinalDirection) -> bool:
    if is_moving:
        return false

    if tween:
        tween.kill()

    tween = planner.move_entity(move_direction)
    _handle_new_tween()

    return tween != null

func attempt_rotate(clockwise: bool) -> bool:
    if is_moving:
        return false

    if tween:
        tween.kill()

    tween = planner.rotate_entity(clockwise)
    _handle_new_tween()

    return tween != null

func _handle_new_tween() -> void:
    if tween != null:
        tween.play()
        if instant_step:
            var t: float = 999
            while tween.custom_step(t):
                t *= 2
        else:
            is_moving = true

func update_entity_anchorage(node: GridNode, anchor: GridAnchor, deferred: bool = false) -> void:
    if anchor != null:
        set_grid_anchor(anchor, deferred)
        transportation_mode.mode = transportation_abilities.intersection(anchor.required_transportation_mode)
    else:
        set_grid_node(node, deferred)
        transportation_mode.mode = TransportationMode.NONE

    # print_debug("%s is now %s" % [name, transportation_mode.humanize()])
    # print_stack()

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
