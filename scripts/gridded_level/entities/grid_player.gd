extends GridPlayerCore
class_name GridPlayer
@export var robot: Robot

var override_wall_walking: bool:
    set(value):
        override_wall_walking = value
        if value:
            transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
        else:
            var climbing: int = robot.get_skill_level(RobotAbility.SKILL_CLIMBING)
            if climbing == 0:
                transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)
            else:
                transportation_abilities.set_flag(TransportationMode.WALL_WALKING)

var override_ceiling_walking: bool:
    set(value):
        override_ceiling_walking = value
        if value:
            transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)
        else:
            var climbing: int = robot.get_skill_level(RobotAbility.SKILL_CLIMBING)
            if climbing < 2:
                if !override_wall_walking && climbing == 0:
                    transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
                transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
            else:
                transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)

func _ready() -> void:
    if __SignalBus.on_robot_death.connect(_handle_robot_death) != OK:
        push_error("Failed to connect to robot death")

    super()

func _handle_robot_death(dead_robot: Robot) -> void:
    if robot == dead_robot:
        print_debug("[Grid Player] We are dead")
        cinematic = true

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

func load_from_save(level: GridLevel, save_data: Dictionary) -> void:
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
