extends GridEvent
class_name GridDoor

@export
var animator: AnimationPlayer

enum _OpenAutomation { NONE, WALK_INTO, PROXIMITY }
enum _CloseAutomation { NONE, PROXIMITY }
enum _LockState { LOCKED, CLOSED, OPEN }

@export
var _automation: _OpenAutomation

@export
var _back_automation: _OpenAutomation

@export
var _close_automation: _CloseAutomation

@export
var _inital_lock_state: _LockState = _LockState.CLOSED

@export
var _door_face: CardinalDirections.CardinalDirection

## If door is locked, this identifies what key unlocks it
@export
var _key_id: String

var _lock_state: _LockState

func _ready() -> void:
    super._ready()
    _lock_state = _inital_lock_state

func should_trigger(
    _entity: GridEntity,
    _from: GridNode,
    _from_side: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return _lock_state != _LockState.OPEN

func blocks_entry_translation(
    _entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return CardinalDirections.invert(move_direction) == _door_face && _lock_state != _LockState.OPEN

func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return exit_direction == _door_face && _lock_state != _LockState.OPEN

func anchorage_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return side == _door_face && _lock_state == _LockState.OPEN || super.anchorage_blocked(side)

func manages_triggering_translation() -> bool:
    return false

var _proximate_entitites: Array[GridEntity]

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if !_repeatable && _triggered:
        return

    super.trigger(entity, movement)

    if _close_automation == _CloseAutomation.PROXIMITY && !_proximate_entitites.has(entity):
        _proximate_entitites.append(entity)
        if entity.on_move_end.connect(_check_autoclose) != OK:
            push_error("Door %s failed to connect %s on move end for auto-closing" % [self, entity])

    if _close_automation == _CloseAutomation.PROXIMITY && _lock_state == _LockState.CLOSED:
        open_door()
        return


func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, _door_face):
        return

    _proximate_entitites.erase(entity)
    entity.on_move_end.disconnect(_check_autoclose)

    if _proximate_entitites.is_empty():
        close_door()

func close_door() -> void:
    _lock_state = _LockState.CLOSED

func open_door() -> void:
    _lock_state = _LockState.OPEN

func needs_saving() -> bool:
    return true

func save_key() -> String:
    return "d-%s" % coordinates()

const _LOCK_STATE_KEY: String = "lock"
const _TRIGGERED_KEY: String = "triggered"

func collect_save_data() -> Dictionary:
    return {
        _LOCK_STATE_KEY: _lock_state,
        _TRIGGERED_KEY: _triggered,
    }

func _deserialize_lockstate(state: int) -> _LockState:
    match state:
        0: return _LockState.LOCKED
        1: return _LockState.CLOSED
        2: return _LockState.OPEN
        _:
            push_error("State %s is not a serialized lockstate, using initial lock state" % state)
            return _inital_lock_state

func load_save_data(_data: Dictionary) -> void:
    _triggered = DictionaryUtils.safe_getb(_data, _TRIGGERED_KEY)
    var lock_state_int: int = DictionaryUtils.safe_geti(_data, _LOCK_STATE_KEY)
    _lock_state = _deserialize_lockstate(lock_state_int)
