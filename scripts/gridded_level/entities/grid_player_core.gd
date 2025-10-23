extends GridEntity
class_name GridPlayerCore

@export var camera: Camera3D
var camera_resting_position: Vector3
var camera_resting_rotation: Quaternion

var camera_wanted_position: Vector3:
    get():
        if _ducking:
            return camera_resting_position * _duck_camera_height
        return camera_resting_position

@export var allow_replays: bool = true

@export var persist_repeat_moves: bool

@export var repeat_move_delay: float = 100

@export_range(0, 1) var _duck_camera_height: float = 0.5

@export var key_ring: KeyRingCore

func _ready() -> void:
    if __SignalBus.on_cinematic.connect(_handle_cinematic) != OK:
        push_error("Failed to connect to cinematic")

    camera_resting_position = camera.position
    camera_resting_rotation = camera.basis.get_rotation_quaternion()

    _sync_level_entry()

    # We do super afterwards to not get uneccesary warning about player not being
    # preset as a child of a node
    super()

func _handle_cinematic(entity: GridEntity, _is_cinematic: bool) -> void:
    if entity == self:
        print_debug("[Grid Player] clear all input")
        clear_queue()
        _repeat_movement.clear()

func _sync_level_entry() -> void:
    var entry: LevelPortal = get_level().entry_portal
    var spawn_node: GridNode = null

    if entry == null:
        push_error("Level doesn't have an entry portal")
        down = CardinalDirections.CardinalDirection.DOWN
        look_direction = CardinalDirections.CardinalDirection.NORTH
        spawn_node = get_level().nodes()[0]
    else:
        down = entry.entry_down
        look_direction = entry.entry_lookdirection
        spawn_node = entry.get_grid_node()

    if spawn_node == null:
        push_error("Level has no node!")
        __SignalBus.on_critical_level_corrupt.emit(get_level().level_id)
        return

    var anchor: GridAnchor = spawn_node.get_grid_anchor(down)
    update_entity_anchorage(spawn_node, anchor, true)
    sync_position()
    orient()
    print_debug("[Grid Player] %s anchors to %s in node %s and mode %s" % [
        name,
        anchor,
        spawn_node,
        transportation_mode.humanize()
    ])

var _repeat_movement: Array[Movement.MovementType] = []

func is_alive() -> bool:
    return true

func kill() -> void:
    pass

func _input(event: InputEvent) -> void:
    if transportation_mode.mode == TransportationMode.NONE:
        return

    if !event.is_echo():
        if !cinematic && event.is_action_pressed("crawl_forward"):
            hold_movement(Movement.MovementType.FORWARD)
        elif event.is_action_released("crawl_forward"):
            clear_held_movement(Movement.MovementType.FORWARD)

        elif !cinematic && event.is_action_pressed("crawl_backward"):
            hold_movement(Movement.MovementType.BACK)
        elif event.is_action_released("crawl_backward"):
            clear_held_movement(Movement.MovementType.BACK)

        elif !cinematic && event.is_action_pressed("crawl_strafe_left"):
            hold_movement(Movement.MovementType.STRAFE_LEFT)
        elif event.is_action_released("crawl_strafe_left"):
            clear_held_movement(Movement.MovementType.STRAFE_LEFT)

        elif !cinematic && event.is_action_pressed("crawl_strafe_right"):
            hold_movement(Movement.MovementType.STRAFE_RIGHT)
        elif event.is_action_released("crawl_strafe_right"):
            clear_held_movement(Movement.MovementType.STRAFE_RIGHT)

        elif !cinematic && event.is_action_pressed("crawl_turn_left"):
            if !attempt_movement(Movement.MovementType.TURN_COUNTER_CLOCKWISE):
                print_debug("Refused Rotate Left")

        elif !cinematic && event.is_action_pressed("crawl_turn_right"):
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
    if cinematic:
        return

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
    if cinematic || falling():
        _repeat_movement.clear()
        return

    if !allow_replays || is_moving() || Time.get_ticks_msec() < _next_move_repeat:
        return

    var count: int = _repeat_movement.size()
    if count > 0:
        if !attempt_movement(_repeat_movement[count - 1], false):
            clear_held_movement(_repeat_movement[count - 1])
        _next_move_repeat = Time.get_ticks_msec() + repeat_move_delay

var _ducking: bool = false
func duck() -> void:
    if _ducking:
        return

    _ducking = true
    _animate_ducking_stand_up()

func stand_up() -> void:
    if !_ducking:
        return

    _ducking = false
    _animate_ducking_stand_up()

func _animate_ducking_stand_up() -> void:
    @warning_ignore_start("return_value_discarded")
    create_tween().tween_property(
        camera,
        "position",
        camera_wanted_position,
        0.2)
    @warning_ignore_restore("return_value_discarded")

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

const _KEY_RING_KEY: String = "keys"

func save() -> Dictionary:
    return {
        _LOOK_DIRECTION_KEY: look_direction,
        _ANCHOR_KEY: get_grid_anchor_direction(),
        _COORDINATES_KEY: coordinates(),
        _DOWN_KEY: down,
        _KEY_RING_KEY: key_ring.collect_save_data(),
    }

func initial_state() -> Dictionary:
    # TODO: Note safely used on player that has moved
    var primary_entry: LevelPortal = get_level().entry_portal

    if primary_entry != null:
        return {
            _LOOK_DIRECTION_KEY: primary_entry.entry_lookdirection,
            _DOWN_KEY: primary_entry.entry_down,
            _ANCHOR_KEY: primary_entry.entry_down,
            _COORDINATES_KEY: primary_entry.coordinates(),

            _KEY_RING_KEY: {},
        }

    push_error("Level doesn't have an entry portal")

    return {
            _LOOK_DIRECTION_KEY: CardinalDirections.CardinalDirection.NORTH,
            _DOWN_KEY: CardinalDirections.CardinalDirection.DOWN,
            _ANCHOR_KEY: CardinalDirections.CardinalDirection.DOWN,
            _COORDINATES_KEY: get_level().nodes()[0],

            _KEY_RING_KEY: {},
    }

static func strip_save_of_transform_data(save_data: Dictionary) -> void:
    @warning_ignore_start("return_value_discarded")
    save_data.erase(_LOOK_DIRECTION_KEY)
    save_data.erase(_DOWN_KEY)
    save_data.erase(_ANCHOR_KEY)
    save_data.erase(_COORDINATES_KEY)
    @warning_ignore_restore("return_value_discarded")

static func extend_save_with_portal_entry(save_data: Dictionary, portal: LevelPortal) -> void:
    save_data[_LOOK_DIRECTION_KEY] = portal.entry_lookdirection
    save_data[_DOWN_KEY] = portal.entry_down
    save_data[_ANCHOR_KEY] = portal.entry_anchor
    save_data[_COORDINATES_KEY] = portal.coordinates()

static func valid_save_data(save_data: Dictionary) -> bool:
    return (
        save_data.has(_LOOK_DIRECTION_KEY) &&
        save_data.has(_ANCHOR_KEY) &&
        save_data.has(_COORDINATES_KEY) &&
        save_data.has(_DOWN_KEY))

func load_from_save(level: GridLevelCore, save_data: Dictionary) -> void:
    if !valid_save_data(save_data):
        push_error("Player save data is not valid %s" % save_data)
        return

    var key_ring_save: Dictionary = DictionaryUtils.safe_getd(save_data, _KEY_RING_KEY, {})
    key_ring.load_from_save(key_ring_save)

    var coords: Vector3i = DictionaryUtils.safe_getv3i(save_data, _COORDINATES_KEY)
    var node: GridNode = level.get_grid_node(coords)

    if node == null:
        push_error("Trying to load player onto coordinates %s but there's no node there. Returning to spawn" % coords)
        _sync_level_entry()
    else:
        var look: CardinalDirections.CardinalDirection = save_data[_LOOK_DIRECTION_KEY]
        var down_direction: CardinalDirections.CardinalDirection = save_data[_DOWN_KEY]
        var anchor_direction: CardinalDirections.CardinalDirection = save_data[_ANCHOR_KEY]

        load_look_direction_and_down(look, down_direction)

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
    print_debug("[Grid Player] loaded player onto %s from %s" % [coords, save_data])
