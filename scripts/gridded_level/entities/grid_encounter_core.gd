extends GridEntity
class_name GridEncounterCore

static var _TRIGGERED_KEY: String = "triggered"
static var _ID_KEY: String = "id"

enum EncounterMode { NEVER, NODE, ANCHOR }
enum EncounterType { ENEMY, NPC, OTHER }

## When encounters trigger, be it never, when player collides on same node, or when player collides on same anchor
@export var encounter_mode: EncounterMode = EncounterMode.NODE
@export var encounter_type: EncounterType = EncounterType.ENEMY

@export var encounter_id: String

@export var repeatable: bool = true

@export var effect: GridEncounterEffect

@export var graphics: MeshInstance3D

@export var _spawn_node: GridNode

@export var _start_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN
@export var _start_look_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NORTH

var _triggered: bool
var _was_on_node: bool

func _ready() -> void:
    if __SignalBus.on_change_anchor.connect(_check_colliding_anchor) != OK:
        push_error("%s failed to connect to anchor change signal" % name)
    if __SignalBus.on_change_node.connect(_check_colliding_node) != OK:
        push_error("%s failed to connect to node change signal" % name)

    if _spawn_node != null:
        look_direction = _start_look_direction

        var anchor: GridAnchor = _spawn_node.get_grid_anchor(_start_anchor_direction)
        if anchor == null:
            push_error("%s doesn't have anchor in %s direction" % [
                _spawn_node.name,
                CardinalDirections.name(_start_anchor_direction),
            ])
        update_entity_anchorage(_spawn_node, anchor, true)
        sync_position()

    super._ready()

    effect.prepare(self)

func _check_colliding_anchor(feature: GridNodeFeature) -> void:
    if feature is not GridPlayerCore || encounter_mode != EncounterMode.ANCHOR:
        return

    if feature.get_grid_node() == get_grid_node() && feature.get_grid_anchor() == get_grid_anchor():
        if feature is GridEntity:
            _trigger(feature as GridEntity)

func _check_colliding_node(feature: GridNodeFeature) -> void:
    if feature is not GridPlayerCore:
        return

    var is_on_node: bool = feature.get_grid_node() == get_grid_node()

    if encounter_mode != EncounterMode.NODE:
        _was_on_node = is_on_node
        return

    if is_on_node:
        if !_was_on_node && feature is GridEntity:
            _trigger(feature as GridEntity)

    _was_on_node = is_on_node

func can_trigger() -> bool:
    return effect != null && (repeatable || !_triggered)

func _trigger(entity: GridEntity) -> void:
    if !can_trigger():
        return

    if effect != null && effect.invoke(self, entity):
        _triggered = true

func save() -> Dictionary:
    var anchor_direction: CardinalDirections.CardinalDirection = get_grid_anchor_direction()

    var data: Dictionary = {
        _ID_KEY: encounter_id,
        _LOOK_DIRECTION_KEY: look_direction,
        _ANCHOR_KEY: anchor_direction,
        _COORDINATES_KEY: coordinates(),
        _DOWN_KEY: down,
        _TRIGGERED_KEY: _triggered,
    }

    return data

func _valid_save_data(save_data: Dictionary) -> bool:
    return (
        save_data.has(_ID_KEY) &&
        save_data.has(_LOOK_DIRECTION_KEY) &&
        save_data.has(_ANCHOR_KEY) &&
        save_data.has(_COORDINATES_KEY) &&
        save_data.has(_DOWN_KEY))

func load_from_save(level: GridLevelCore, save_data: Dictionary) -> void:
    if !_valid_save_data(save_data):
        _reset_starting_condition()
        return

    if save_data[_ID_KEY] != encounter_id:
        push_error("Attempting load of '%s' but I'm '%s" % [save_data[_ID_KEY], encounter_id])
        return

    var coords: Vector3i = DictionaryUtils.safe_getv3i(save_data, _COORDINATES_KEY)
    var node: GridNode = level.get_grid_node(coords)

    if node == null:
        push_error("Trying to load encounter onto coordinates %s but there's no node there." % coords)
        _reset_starting_condition()
        return

    var look: CardinalDirections.CardinalDirection = save_data[_LOOK_DIRECTION_KEY]
    var down_direction: CardinalDirections.CardinalDirection = save_data[_DOWN_KEY]
    var anchor_direction: CardinalDirections.CardinalDirection = save_data[_ANCHOR_KEY]

    load_look_direction_and_down(look, down_direction)
    _triggered = save_data[_TRIGGERED_KEY] if save_data.has(_TRIGGERED_KEY) else false

    if anchor_direction == CardinalDirections.CardinalDirection.NONE:
        set_grid_node(node)
    else:
        var anchor: GridAnchor = node.get_grid_anchor(anchor_direction)
        if anchor == null:
            push_error("Trying to load encounter onto coordinates %s and anchor %s but node lacks anchor in that direction" % [coords, anchor_direction])
        update_entity_anchorage(node, anchor, true)

    if effect != null:
        if effect.hide_encounter_on_trigger && _triggered:
            visible = false
    sync_position()
    orient()

    print_debug("Loaded %s from %s" % [encounter_id, save_data])

func _reset_starting_condition() -> void:
    look_direction = _start_look_direction
    down = _start_anchor_direction

    if down == CardinalDirections.CardinalDirection.NONE:
        set_grid_node(_spawn_node)
    else:
        var anchor: GridAnchor = _spawn_node.get_grid_anchor(down)
        if anchor == null:
            push_error("Trying to load encounter onto node %s and anchor %s but node lacks anchor in that direction" % [_spawn_node, down])
        update_entity_anchorage(_spawn_node, anchor, true)

    sync_position()
    orient()

    _triggered = false

func kill() -> void:
    _triggered = true
