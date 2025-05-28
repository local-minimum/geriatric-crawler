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

@export
var concurrent_turns: bool

var _active_movement: Movement.MovementType = Movement.MovementType.NONE
var _concurrent_movement: Movement.MovementType = Movement.MovementType.NONE
var _next_movement: Movement.MovementType = Movement.MovementType.NONE
var _next_next_movement: Movement.MovementType = Movement.MovementType.NONE

func _ready() -> void:
    super()
    orient()

func is_moving() -> bool:
    return _active_movement != Movement.MovementType.NONE

var _block_concurrent: bool

func block_concurrent_movement() -> void:
    _block_concurrent = true

func remove_concurrent_movement_block() -> void:
    _block_concurrent = false


func _start_movement(movement: Movement.MovementType, force: bool) -> bool:
    if Movement.MovementType.NONE == movement:
        return false

    if _active_movement == Movement.MovementType.NONE || force:
        _active_movement = movement
    elif concurrent_turns && !_block_concurrent:
        _concurrent_movement = movement
    else:
        return false

    return true

func end_movement(movement: Movement.MovementType) -> void:
    if _active_movement == movement:
        _active_movement = _concurrent_movement
        _concurrent_movement = Movement.MovementType.NONE
    elif _concurrent_movement == movement:
        _concurrent_movement = Movement.MovementType.NONE
    else:
        return

    if _next_movement != Movement.MovementType.NONE:
        if attempt_movement(_next_movement, false):
            _next_movement = _next_next_movement
            _next_next_movement = Movement.MovementType.NONE
        elif !concurrent_turns:
            _clear_queue()

func falling() -> bool:
    return transportation_mode.mode == TransportationMode.NONE

var _tween: Tween
var _concurrent_tween: Tween

func attempt_movement(
    movement: Movement.MovementType,
    enqueue_if_occupied: bool = true,
    force: bool = false) -> bool:
    if movement == Movement.MovementType.NONE:
        return false

    if !_start_movement(movement, force):
        if enqueue_if_occupied:
            _enqeue_movement(movement)
        print_debug("%s & %s are active" % [Movement.name(_active_movement), Movement.name(_concurrent_movement)])
        return false

    if force:
        _clear_queue()

    var primary_tween: bool = movement == _active_movement

    if primary_tween:
        if _tween:
            _tween.kill()
    else:
        if _concurrent_tween:
            _concurrent_tween.kill()

    var tween: Tween

    if Movement.is_translation(movement):
        tween = planner.move_entity(movement, Movement.to_direction(movement, look_direction, down))
    elif Movement.is_turn(movement):
        tween = planner.rotate_entity(movement, movement == Movement.MovementType.TURN_CLOCKWISE)

    _handle_new_tween(tween, primary_tween)

    return tween != null

func _enqeue_movement(movement: Movement.MovementType) -> void:
    if _next_movement != Movement.MovementType.NONE:
        _next_next_movement = movement
        return

    _next_movement = movement

func _clear_queue() -> void:
    _next_movement = Movement.MovementType.NONE
    _next_next_movement = Movement.MovementType.NONE

func _handle_new_tween(tween: Tween, primary_tween: bool) -> void:
    if tween != null:
        tween.play()
        if instant_step:
            var t: float = 999
            while tween.custom_step(t):
                t *= 2
        elif primary_tween:
            _tween = tween
        else:
            _concurrent_tween = tween

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
