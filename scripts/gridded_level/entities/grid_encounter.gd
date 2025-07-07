extends GridEntity
class_name GridEncounter

static var _TRIGGERED_KEY: String = "triggered"
static var _ID_KEY: String = "id"

enum EncounterMode { NEVER, NODE, ANCHOR }

## When encounters trigger, be it never, when player collides on same node, or when player collides on same anchor
@export
var encounter_mode: EncounterMode = EncounterMode.NODE

@export
var encounter_id: String

@export
var repeatable: bool = true

@export
var effect: GridEncounterEffect

@export
var graphics: MeshInstance3D

@export
var _spawn_node: GridNode

@export
var _start_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

var _triggered: bool
var _was_on_node: bool

func _ready() -> void:
    if _spawn_node != null:
        var anchor: GridAnchor = _spawn_node.get_grid_anchor(_start_anchor_direction)
        if anchor == null:
            push_error("%s doesn't have anchor in %s direction" % [
                _spawn_node.name,
                CardinalDirections.name(_start_anchor_direction),
            ])
        update_entity_anchorage(_spawn_node, anchor, true)
        sync_position()

    super._ready()

    _connect_player_callbacks(get_level())

    effect.prepare(self)

var _connected_player: GridPlayer

func _connect_player_callbacks(level: GridLevel) -> void:
    if _connected_player == level.player:
        return
    elif _connected_player != null:
        _disconnect_player_callbacks()

    if level != null:
        if level.player.on_change_anchor.connect(_check_colliding_anchor) != OK:
            push_error("%s failed to connect to player anchor change signal" % name)
        if level.player.on_change_node.connect(_check_colliding_node) != OK:
            push_error("%s failed to connect to player node change signal" % name)
        _connected_player = level.player
    else:
        push_error("%s is not part of a level" % name)

func _disconnect_player_callbacks() -> void:
    if _connected_player == null:
        return

    _connected_player.on_change_anchor.disconnect(_check_colliding_anchor)
    _connected_player.on_change_node.disconnect(_check_colliding_node)
    _connected_player = null


func _check_colliding_anchor(feature: GridNodeFeature) -> void:
    if encounter_mode != EncounterMode.ANCHOR:
        return

    if feature.get_grid_node() == get_grid_node() && feature.get_grid_anchor() == get_grid_anchor():
        if feature is GridEntity:
            _trigger(feature as GridEntity)

func _check_colliding_node(feature: GridNodeFeature) -> void:
    var is_on_node: bool = feature.get_grid_node() == get_grid_node()

    if encounter_mode != EncounterMode.NODE:
        _was_on_node = is_on_node
        return

    if is_on_node:
        if !_was_on_node && feature is GridEntity:
            _trigger(feature as GridEntity)

    _was_on_node = is_on_node

func _trigger(entity: GridEntity) -> void:
    if !repeatable && _triggered:
        return

    if effect != null && effect.invoke(self, entity):
        _triggered = true

func save() -> Dictionary:
    var anchor: GridAnchor = get_grid_anchor()
    var anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NONE
    if anchor != null:
        anchor_direction = anchor.direction

    return {
        _ID_KEY: encounter_id,
        _LOOK_DIRECTION_KEY: look_direction,
        _ANCHOR_KEY: anchor_direction,
        _COORDINATES_KEY: coordinates(),
        _DOWN_KEY: down,
        _TRIGGERED_KEY: _triggered,
    }

func _valid_save_data(save_data: Dictionary) -> bool:
    return (
        save_data.has(_ID_KEY) &&
        save_data.has(_LOOK_DIRECTION_KEY) &&
        save_data.has(_ANCHOR_KEY) &&
        save_data.has(_COORDINATES_KEY) &&
        save_data.has(_DOWN_KEY))

func load_from_save(level: GridLevel, save_data: Dictionary) -> void:
    if !_valid_save_data(save_data):
        push_error("%s (%s) cannot load from %s because data not valid" % [name, encounter_id, save_data])
        return

    if save_data[_ID_KEY] != encounter_id:
        push_error("Attempting load of '%s' but I'm '%s" % [save_data[_ID_KEY], encounter_id])
        return

    var coords: Vector3i = save_data[_COORDINATES_KEY]
    var node: GridNode = level.get_grid_node(coords)

    if node == null:
        push_error("Trying to load player onto coordinates %s but there's no node there." % coords)
        return

    var look: CardinalDirections.CardinalDirection = save_data[_LOOK_DIRECTION_KEY]
    var down_direction: CardinalDirections.CardinalDirection = save_data[_DOWN_KEY]
    var anchor_direction: CardinalDirections.CardinalDirection = save_data[_ANCHOR_KEY]

    look_direction = look
    down = down_direction
    _triggered = save_data[_TRIGGERED_KEY] if save_data.has(_TRIGGERED_KEY) else false

    if anchor_direction == CardinalDirections.CardinalDirection.NONE:
        set_grid_node(node)
    else:
        var anchor: GridAnchor = node.get_grid_anchor(anchor_direction)
        if anchor == null:
            push_error("Trying to load player onto coordinates %s and anchor %s but node lacks anchor in that direction" % [coords, anchor_direction])
        update_entity_anchorage(node, anchor, true)

    sync_position()
    orient()

    _connect_player_callbacks(level)

    print_debug("Loaded %s from %s" % [encounter_id, save_data])
