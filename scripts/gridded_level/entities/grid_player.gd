extends GridEntity
class_name GridPlayer

@export
var camera: Camera3D

@export
var spawn_node: GridNode

@export
var allow_replays: bool = true

@export
var persist_repeat_moves: bool

@export
var repeat_move_delay: float = 100

func _ready() -> void:
    if spawn_node != null:
        var anchor: GridAnchor = spawn_node.get_grid_anchor(down)
        update_entity_anchorage(spawn_node, anchor, true)
        sync_position()
        print_debug("%s anchors to %s in node %s and mode %s" % [
            name,
            anchor,
            spawn_node,
            transportation_mode.humanize()
        ])

    # We do super afterwards to not get uneccesary warning about player not being
    # preset as a child of a node
    super()

var _repeat_movement: Array[Movement.MovementType] = []

func _input(event: InputEvent) -> void:
    if transportation_mode.mode == TransportationMode.NONE:
        return

    if !event.is_echo():
        if event.is_action_pressed("crawl_forward"):
            hold_movement(Movement.MovementType.FORWARD)
        elif event.is_action_released("crawl_forward"):
            clear_held_movement(Movement.MovementType.FORWARD)

        elif event.is_action_pressed("crawl_backward"):
            hold_movement(Movement.MovementType.BACK)
        elif event.is_action_released("crawl_backward"):
            clear_held_movement(Movement.MovementType.BACK)

        elif event.is_action_pressed("crawl_strafe_left"):
            hold_movement(Movement.MovementType.STRAFE_LEFT)
        elif event.is_action_released("crawl_strafe_left"):
            clear_held_movement(Movement.MovementType.STRAFE_LEFT)

        elif event.is_action_pressed("crawl_strafe_right"):
            hold_movement(Movement.MovementType.STRAFE_RIGHT)
        elif event.is_action_released("crawl_strafe_right"):
            clear_held_movement(Movement.MovementType.STRAFE_RIGHT)

        elif event.is_action_pressed("crawl_turn_left"):
            if !attempt_movement(Movement.MovementType.TURN_COUNTER_CLOCKWISE):
                print_debug("Refused Rotate Left")

        elif event.is_action_pressed("crawl_turn_right"):
            if !attempt_movement(Movement.MovementType.TURN_CLOCKWISE):
                print_debug("Refused Rotate Right")
        else:
            return

        # print_debug("%s @ %s looking %s with %s down and has %s transportation" % [
            # name,
            # coordnates(),
            # CardinalDirections.name(look_direction),
            # CardinalDirections.name(down),
            # transportation_mode.humanize()])

func hold_movement(movement: Movement.MovementType) -> void:
    if get_level().paused:
        return

    if !attempt_movement(movement):
        print_debug("Refused %s" % Movement.name(movement))

    if !allow_replays || Movement.is_turn(movement):
        return

    if persist_repeat_moves:
        if !_repeat_movement.has(movement):
            _repeat_movement.append(movement)
    else:
        _repeat_movement[0] = movement

    _next_move_repeat = Time.get_ticks_msec() + repeat_move_delay

func clear_held_movement(movement: Movement.MovementType) -> void:
    _repeat_movement.erase(movement)

var _next_move_repeat: float

func _process(_delta: float) -> void:
    if !allow_replays || is_moving() || Time.get_ticks_msec() < _next_move_repeat:
        return

    var count: int = _repeat_movement.size()
    if count > 0:
        if !attempt_movement(_repeat_movement[count - 1], false):
            clear_held_movement(_repeat_movement[count - 1])
        _next_move_repeat = Time.get_ticks_msec() + repeat_move_delay


func save() -> Dictionary:
    var anchor: GridAnchor = get_grid_anchor()
    var anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NONE
    if anchor != null:
        anchor_direction = anchor.direction


    return {
        _LOOK_DIRECTION_KEY: look_direction,
        _ANCHOR_KEY: anchor_direction,
        _COORDINATES_KEY: coordinates(),
        _DOWN_KEY: down
    }

func initial_state() -> Dictionary:
    # TODO: Note safely used on player that has moved
    return {
        _LOOK_DIRECTION_KEY: look_direction,
        _DOWN_KEY: down,
        _ANCHOR_KEY: down,
        _COORDINATES_KEY: spawn_node.coordinates
    }

func _valid_save_data(save_data: Dictionary) -> bool:
    return (
        save_data.has(_LOOK_DIRECTION_KEY) &&
        save_data.has(_ANCHOR_KEY) &&
        save_data.has(_COORDINATES_KEY) &&
        save_data.has(_DOWN_KEY))

func load_from_save(level: GridLevel, save_data: Dictionary) -> void:
    if !_valid_save_data(save_data):
        push_error("Player save data is not valid %s" % save_data)
        return

    var coords: Vector3i = save_data[_COORDINATES_KEY]
    var node: GridNode = level.get_grid_node(coords)

    if node == null:
        push_error("Trying to load player onto coordinates %s but there's no node there. Returning to spawn" % coords)
        node = level.player.spawn_node

    var look: CardinalDirections.CardinalDirection = save_data[_LOOK_DIRECTION_KEY]
    var down_direction: CardinalDirections.CardinalDirection = save_data[_DOWN_KEY]
    var anchor_direction: CardinalDirections.CardinalDirection = save_data[_ANCHOR_KEY]

    look_direction = look
    down = down_direction

    if anchor_direction == CardinalDirections.CardinalDirection.NONE:
        set_grid_node(node)
    else:
        var anchor: GridAnchor = node.get_grid_anchor(anchor_direction)
        if anchor == null:
            push_error("Trying to load player onto coordinates %s and anchor %s but node lacks anchor in that direction" % [coords, anchor_direction])
            set_grid_node(node)
        else:
            set_grid_anchor(anchor)

    sync_position()
    orient()

    camera.make_current()

func enable_player() -> void:
    set_process(true)
    # set_physics_process(true)
    set_process_input(true)
    set_process_unhandled_input(true)
    set_process_unhandled_key_input(true)
    set_process_shortcut_input(true)

    # Unclear why repeat moves can appear here if not cleared again
    clear_queue()
    _repeat_movement.clear()

func disable_player() -> void:
    set_process(false)
    # set_physics_process(false)
    set_process_input(false)
    set_process_unhandled_input(false)
    set_process_unhandled_key_input(false)
    set_process_shortcut_input(false)

    clear_queue()
    _repeat_movement.clear()
