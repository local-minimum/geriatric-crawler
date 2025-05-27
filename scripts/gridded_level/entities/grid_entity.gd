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

var _is_moving: bool

var _next_movement: Movement.MovementType = Movement.MovementType.NONE
var _next_next_movement: Movement.MovementType = Movement.MovementType.NONE

func _ready() -> void:
    super()
    orient()

func is_moving() -> bool:
    return _is_moving

func set_is_moving(value: bool) -> void:
    _is_moving = value
    if !value && _next_movement != Movement.MovementType.NONE:
        if attempt_movement(_next_movement, false):
            _next_movement = _next_next_movement
            _next_next_movement = Movement.MovementType.NONE
        else:
            _clear_queue()

func falling() -> bool:
    return transportation_mode.mode == TransportationMode.NONE

var tween: Tween

func attempt_movement(
    movement: Movement.MovementType,
    enqueue_if_occupied: bool = true,
    force: bool = false) -> bool:
    if movement == Movement.MovementType.NONE:
        return false

    if !force && is_moving():
        if enqueue_if_occupied:
            _enqeue_movement(movement)

        return false

    if force:
        _clear_queue()

    if tween:
        tween.kill()

    if Movement.is_translation(movement):
        tween = planner.move_entity(Movement.to_direction(movement, look_direction, down))
    elif Movement.is_turn(movement):
        tween = planner.rotate_entity(movement == Movement.MovementType.TURN_CLOCKWISE)

    _handle_new_tween()

    return tween != null

func _enqeue_movement(movement: Movement.MovementType) -> void:
    if _next_movement != Movement.MovementType.NONE:
        _next_next_movement = movement
        return

    _next_movement = movement

func _clear_queue() -> void:
    _next_movement = Movement.MovementType.NONE
    _next_next_movement = Movement.MovementType.NONE

func _handle_new_tween() -> void:
    if tween != null:
        tween.play()
        if instant_step:
            var t: float = 999
            while tween.custom_step(t):
                t *= 2
        else:
            set_is_moving(true)

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
