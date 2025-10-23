extends GridEvent
class_name Crusher

enum LiveMode { TURN_BASED, FULL_LIVE, LIVE_ONE_SHOT }

enum Phase { RETRACTED, CRUSHING, CRUSHED, RETRACTING }
static func phase_from_int(phase_value: int) -> Phase:
    match phase_value:
        0: return Phase.RETRACTED
        1: return Phase.CRUSHING
        2: return Phase.CRUSHED
        3: return Phase.RETRACTING
        _: return Phase.RETRACTED

@export var _managed: bool
## If managed and left empty, then it listens to all messages irrespective of id
@export var _managed_message_id: String
@export var _managed_crush_message: String = "crush"
@export var _managed_retract_message: String = "retract"

## Note: This has no effect when managed
@export var _rest_crushed_ticks: int = 2
## Note: This has no effect when managed
@export var _rest_retracted_ticks: int = 3
@export var _start_delay_ticks: int = 0

@export var _always_block_crusher_side: bool = true
@export var _block_retracting_seconds: float = 0.3
@export var _crusher_side: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.UP
@export var _crush_check_delay: float = 0.05
@export var _anim: AnimationPlayer

@export var _retracted_resting_anim: String = "Retracted"
@export var _crushed_resting_anim: String = "Crushed"
@export var _crush_anim: String = "Crush"
@export var _retract_anim: String = "Retract"

@export var _live: LiveMode = LiveMode.TURN_BASED
@export var _live_tick_duration_msec: int = 500
@export var _add_anchors_when_exhausted: bool = false
@export var _anchor_position_overshoot: float

var _phase: Phase = Phase.RETRACTED:
    set(value):
        _phase = value
        match _phase:
            Phase.RETRACTED:
                _sync_blocking_retracted()
                _phase_ticks = _rest_retracted_ticks

            Phase.CRUSHING:
                _triggered = true
                _sync_blocking_retracted()
                _phase_ticks = 1

            Phase.CRUSHED:
                _blocks_sides = CardinalDirections.ALL_DIRECTIONS.duplicate()
                _phase_ticks = _rest_crushed_ticks

            Phase.RETRACTING:
                _blocks_sides = CardinalDirections.ALL_DIRECTIONS.duplicate()
                _phase_ticks = 1
                await get_tree().create_timer(_block_retracting_seconds).timeout
                _sync_blocking_retracted()

            _:
                _sync_blocking_retracted()

var _phase_ticks: int
var _exposed: Array[GridEntity]
var _last_tick: int
var _anchored: bool

func _ready() -> void:
    super._ready()

    var side: GridNodeSide = GridNodeSide.find_node_side_parent(self, true)
    _add_anchors_when_exhausted = get_bool_override(side, "add_anchors_when_exhausted", _add_anchors_when_exhausted)

    if __SignalBus.on_change_node.connect(_handle_change_node) != OK:
        push_error("Failed to connect change node")

    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

    if __SignalBus.on_broadcast_message.connect(_handle_broadcast_message) != OK:
        push_error("Failed to connect broadcast message")

    _phase = Phase.RETRACTED
    _phase_ticks = _start_delay_ticks

func _process(_delta: float) -> void:
    if !_managed && _live == LiveMode.FULL_LIVE || _live == LiveMode.LIVE_ONE_SHOT && _phase != Phase.RETRACTED:
        if Time.get_ticks_msec() - _last_tick > _live_tick_duration_msec:
            _progress_phase_cycle()
            _last_tick = Time.get_ticks_msec()

func _handle_broadcast_message(id: String, message: String) -> void:
    if !available() || !_managed || (id != _managed_message_id && !_managed_message_id.is_empty()):
        return

    match message:
        _managed_crush_message:
            if _phase == Phase.RETRACTED || _phase == Phase.RETRACTING:
                _phase = Phase.CRUSHING
                _check_crushing()
                _anim.play(get_animation())
                _last_tick = Time.get_ticks_msec()
        _managed_retract_message:
            if _live != LiveMode.LIVE_ONE_SHOT && (_phase == Phase.CRUSHING || _phase == Phase.CRUSHED):
                if _repeatable || !_triggered:
                    _phase = Phase.RETRACTING
        _:
            print_debug("[Crusher %s] Got unhandled message %s from %s" % [coordinates(), message, id])

func _handle_change_node(feature: GridNodeFeature) -> void:
    if feature is not GridEntity:
        return

    var entity: GridEntity = feature
    if entity.coordinates() == coordinates():
        if !_exposed.has(entity):
            _exposed.append(entity)
    elif _exposed.has(entity):
        _exposed.erase(entity)

func _handle_move_end(entity: GridEntity) -> void:
    if entity is not GridPlayer || _managed:
        return

    if _live == LiveMode.TURN_BASED && !_managed:
        _progress_phase_cycle()

func _progress_phase_cycle() -> void:
        _phase_ticks -= 1
        if _phase_ticks <= 0:
            _phase = get_next_phase()
            _anim.play(get_animation())
            if _phase == Phase.CRUSHING:
                _check_crushing()

func _check_crushing() -> void:
    await get_tree().create_timer(_crush_check_delay).timeout
    var crush_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(_crusher_side)
    var node: GridNode = get_grid_node()

    var neighbour: GridNode = null
    match node.has_side(crush_direction):
        GridNode.NodeSideState.ILLUSORY, GridNode.NodeSideState.NONE:
            neighbour = node.neighbour(crush_direction)
        GridNode.NodeSideState.DOOR:
            var door: GridDoorCore = node.get_door(crush_direction)
            if door != null && door.lock_state == GridDoorCore.LockState.OPEN:
                neighbour = node.neighbour(crush_direction)

    for exposed: GridEntity in _exposed:
        var moved: bool = false

        if (
            neighbour != null &&
            node.may_exit(exposed, crush_direction, false, true) &&
            neighbour.may_enter(exposed, node, crush_direction, exposed.get_grid_anchor_direction(), false, false, true)
        ):
            moved = exposed.force_movement(
                Movement.from_directions(crush_direction, exposed.look_direction, exposed.down)
            )

        if !moved:
            if exposed is GridPlayer:
                var player: GridPlayer = exposed
                player.robot.kill()
            elif exposed is GridEncounter:
                var encounter: GridEncounter = exposed
                encounter.kill()

func _sync_blocking_retracted() -> void:
    if _always_block_crusher_side:
        _blocks_sides = [_crusher_side]
    else:
        _blocks_sides = []

func get_next_phase() -> Phase:
    match _phase:
        Phase.RETRACTED:
            return Phase.CRUSHING
        Phase.CRUSHING:
            if !available() && _add_anchors_when_exhausted && !_anchored:
                _add_anchors()
            return Phase.CRUSHED
        Phase.CRUSHED:
            if !available():
                if _add_anchors_when_exhausted && !_anchored:
                    _add_anchors()

                return Phase.CRUSHED
            return Phase.RETRACTING
        Phase.RETRACTING:
            return Phase.RETRACTED
        _:
            push_error("Unknown phase %s" % _phase)
            return Phase.RETRACTED

func get_animation() -> String:
    match _phase:
        Phase.RETRACTED:
            return _retracted_resting_anim
        Phase.CRUSHING:
            return _crush_anim
        Phase.CRUSHED:
            return _crushed_resting_anim
        Phase.RETRACTING:
            return _retract_anim
        _:
            push_error("Unknown phase %s" % _phase)
            return _retracted_resting_anim

func _add_anchors() -> void:
    _anchored = true
    var grid_node: GridNode = GridNode.find_node_parent(self, true)
    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        var inv_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(direction)
        var neighbour: GridNode = grid_node.neighbour(direction)
        if neighbour == null:
            continue

        match neighbour.has_side(inv_direction):
            GridNode.NodeSideState.DOOR, GridNode.NodeSideState.SOLID:
                continue

        print_debug("[Crusher] Node %s asks %s to add an anchor in direction %s because its side states is %s" % [
            grid_node,
            neighbour,
            CardinalDirections.name(inv_direction),
            neighbour.has_side(inv_direction)
        ])
        var anchor: GridAnchor = GridAnchor.new()
        anchor.direction = inv_direction
        anchor.required_transportation_mode = TransportationMode.create_from_direction(inv_direction)
        if neighbour.add_anchor(anchor):
            anchor.global_position = (
                neighbour.get_center_pos() +
                _anchor_position_overshoot * CardinalDirections.direction_to_vector(inv_direction) +
                CardinalDirections.direction_to_vector(inv_direction) * grid_node.get_level().node_size * 0.5
            )
        else:
            anchor.queue_free()

func trigger(_entity: GridEntity, _movement: Movement.MovementType) -> void:
    # We don't trigger this way
    pass

func needs_saving() -> bool:
    return true

func save_key() -> String:
    return "cr-%s-%s" % [coordinates(), CardinalDirections.name(_crusher_side)]

const _PHASE_KEY: String = "phase"
const _PHASE_TICK_KEY: String = "tick"
const _TRIGGERED_KEY: String = "triggered"
const _LIVE_TIME_KEY: String = "live_time"

func collect_save_data() -> Dictionary:
    return {
        _PHASE_KEY: _phase,
        _PHASE_TICK_KEY: _phase_ticks,
        _TRIGGERED_KEY: _triggered,
        _LIVE_TIME_KEY: Time.get_ticks_msec() - _last_tick
    }

func load_save_data(_data: Dictionary) -> void:
    _triggered = DictionaryUtils.safe_getb(_data, _TRIGGERED_KEY)

    var raw_phase: int = DictionaryUtils.safe_geti(_data, _PHASE_KEY)
    _phase = phase_from_int(raw_phase)
    _phase_ticks = DictionaryUtils.safe_geti(_data, _PHASE_TICK_KEY)
    _exposed.clear()

    var live_time: int = DictionaryUtils.safe_geti(_data, _LIVE_TIME_KEY, _live_tick_duration_msec)
    _last_tick = Time.get_ticks_msec() - live_time

    var level: GridLevel = get_level()
    var coords: Vector3i = coordinates()

    for entity: GridEntity in level.grid_entities:
        if entity.coordinates() == coords:
            _exposed.append(entity)
