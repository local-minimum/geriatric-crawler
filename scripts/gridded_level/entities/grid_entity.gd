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

func _ready() -> void:
    super()
    orient()

func falling() -> bool:
    return transportation_mode.mode == TransportationMode.NONE

var tween: Tween

func attempt_move(move_direction: CardinalDirections.CardinalDirection) -> bool:
    if tween:
        tween.kill()

    tween = planner.move_entity(move_direction)
    if tween != null:
        if instant_step:
            tween.pause()
            var t: float = 999
            while tween.custom_step(t):
                t *= 2
        tween.play()
    return tween != null

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
