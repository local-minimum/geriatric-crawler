extends GridEvent
class_name GridDoorCore

enum OpenAutomation { NONE, WALK_INTO, PROXIMITY, INTERACT }
enum CloseAutomation { NONE, END_WALK, PROXIMITY }
enum LockState { LOCKED, CLOSED, OPEN }

@export var animator: AnimationPlayer
@export var _door_face: CardinalDirections.CardinalDirection
@export var door_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN
@export var block_traversal_anchor_sides: Array[CardinalDirections.CardinalDirection]

@export var _inital_lock_state: LockState = LockState.CLOSED
## If door is locked, this identifies what key unlocks it, omit the universal key-prefix
@export var key_id: String
@export var _consumes_key: bool

@export_category("Automations")
@export var _automation: OpenAutomation
@export var _back_automation: OpenAutomation
@export var _close_automation: CloseAutomation

@export var _open_animation: String = "Open"
@export var _close_animation: String = "Close"
@export var _opened_animation: String = "Opened"
@export var _closed_animation: String = "Closed"

var lock_state: LockState

var _check_onto_closed: Array[GridEntity]
var _check_traversing_autoclose: Array[GridEntity]
var _check_move_end_autoclose: Array[GridEntity]
var _check_move_end_do_autoclose: Array[GridEntity]

var proximate_entitites: Array[GridEntity]

static func lock_state_name(state: LockState) -> String:
    match state:
        LockState.LOCKED: return __GlobalGameState.tr("DOOR_LOCKED")
        LockState.CLOSED: return __GlobalGameState.tr("DOOR_CLOSED")
        LockState.OPEN: return __GlobalGameState.tr("DOOR_OPEN")
        _:
            return __GlobalGameState.tr("DOOR_UNKNOWN")

func get_side() -> CardinalDirections.CardinalDirection:
    return _door_face

func _ready() -> void:
    super._ready()

    if __SignalBus.on_move_start.connect(_handle_on_move_start) != OK:
        push_error("Failed to connect on move start")
    if __SignalBus.on_move_end.connect(_handle_on_move_end) != OK:
        push_error("Failed to conntect on move end")

    lock_state = _inital_lock_state
    if lock_state == LockState.OPEN:
        animator.play(_opened_animation)
    else:
        animator.play(_closed_animation)

    get_grid_node().add_grid_event(self)

    if _back_automation != OpenAutomation.NONE:
        _add_back_sentinel.call_deferred()


func _handle_on_move_start(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if _check_onto_closed.has(entity):
        _check_walk_onto_closed_door(entity, from, translation_direction)
    elif _check_traversing_autoclose.has(entity):
        _check_traversing_door_should_autoclose(entity, from, translation_direction)

func _handle_on_move_end(entity: GridEntity) -> void:
    if _check_move_end_do_autoclose.has(entity):
        _do_autoclose(entity)
    if _check_move_end_autoclose.has(entity):
        _check_autoclose(entity)

func _add_back_sentinel() -> void:
    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates(), _door_face)
    var neighbour: GridNode = get_level().get_grid_node(neighbour_coords)
    if neighbour == null:
        push_error("Door %s @ at %s direction %s is supposed to have a backside but there's no node at %s" % [
            self,
            coordinates(),
            CardinalDirections.name(_door_face),
            neighbour_coords,
        ])
        return

    if neighbour.coordinates == coordinates():
        push_error("Door %s @ %s direction %s gets its own node as sentinel position" % [
            self,
            coordinates(),
            CardinalDirections.name(_door_face),
        ])
        return

    for sentinel: GridDoorSentinel in neighbour.find_children("", "GridDoorSentinel"):
        if sentinel.door == self:
            push_error("Door %s @ %s direction %s already has a sentinel on %s (%s)" % [
                self,
                coordinates(),
                CardinalDirections.name(_door_face),
                neighbour,
                sentinel,
            ])
            return

    var sentinel: GridDoorSentinel = GridDoorSentinel.new()

    sentinel.door = self
    sentinel.door_face = CardinalDirections.invert(_door_face)

    sentinel.automation = _back_automation
    sentinel.close_automation = _close_automation

    sentinel._repeatable = true
    sentinel._trigger_entire_node = true

    neighbour.add_child(sentinel)
    neighbour.add_grid_event(sentinel)

func get_opening_automation(reader: GridDoorInteraction) -> OpenAutomation:
    if reader.is_negative_side:
        print_debug("door %s's reader %s is negative side %s" % [self, reader, _back_automation])
        return _back_automation

    print_debug("door %s's reader %s is positive side %s" % [self, reader, _automation])
    return _automation

func should_trigger(
    _entity: GridEntity,
    _from: GridNode,
    _from_side: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return true

func blocks_entry_translation(
    entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
    _silent: bool = false,
) -> bool:
    return CardinalDirections.invert(move_direction) == _door_face && (
        lock_state != LockState.OPEN || block_traversal_anchor_sides.has(entity.get_grid_anchor_direction())
    )

func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return exit_direction == _door_face && lock_state != LockState.OPEN

func anchorage_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return side == _door_face && lock_state == LockState.OPEN || super.anchorage_blocked(side)

func manages_triggering_translation() -> bool:
    return false

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    #print_debug("%s door is state %s automation %s" % [self, lock_state_name(lock_state), _automation])

    if !_repeatable && _triggered:
        return

    super.trigger(entity, movement)

    if _close_automation == CloseAutomation.PROXIMITY:
        _monitor_entity_for_proximity_closing(entity)
    elif _close_automation == CloseAutomation.END_WALK:
        if !_check_traversing_autoclose.has(entity):
            _check_traversing_autoclose.append(entity)

    if lock_state == LockState.CLOSED:
        if _automation == OpenAutomation.PROXIMITY:
            print_debug("Door opens %s" % self)
            open_door()
            return

    if _automation == OpenAutomation.WALK_INTO:
        if !_check_onto_closed.has(entity):
            _check_onto_closed.append(entity)
        return

func _check_walk_onto_closed_door(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    print_debug("[Door] %s %s vs %s and %s vs %s" % [
        self,
        from,
        coordinates(),
        CardinalDirections.name(translation_direction),
        CardinalDirections.name(_door_face),
    ])

    _check_onto_closed.erase(entity)

    if from != coordinates() && entity.coordinates() != coordinates():
        return

    if from == coordinates() && translation_direction == _door_face:
        print_debug("Door opens %s" % self)
        open_door()

func _check_traversing_door_should_autoclose(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if entity.coordinates() != coordinates():
        _check_traversing_autoclose.erase(entity)

    if from == coordinates() && translation_direction == _door_face && lock_state == LockState.OPEN:
        if !_check_move_end_do_autoclose.has(entity):
            _check_move_end_do_autoclose.append(entity)

func _do_autoclose(entity: GridEntity) -> void:
    _check_move_end_do_autoclose.erase(entity)

    if lock_state == LockState.OPEN:
        close_door()

func _monitor_entity_for_proximity_closing(entity: GridEntity) -> void:
    if !proximate_entitites.has(entity):
        proximate_entitites.append(entity)

    if _check_move_end_autoclose.has(entity):
        _check_move_end_autoclose.append(entity)

func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, _door_face):
        return

    proximate_entitites.erase(entity)
    _check_move_end_autoclose.erase(entity)

    if proximate_entitites.is_empty() && lock_state == LockState.OPEN:
        print_debug("%s close door" % self)
        close_door()
        return

    print_debug("%s don't close door %s" % [self, proximate_entitites])

func close_door() -> void:
    print_debug("Close %s" % self)
    var prev_state: LockState = lock_state
    lock_state = LockState.CLOSED
    animator.play(_close_animation, 0.5)
    await get_tree().create_timer(0.5).timeout
    __SignalBus.on_door_state_chaged.emit(self, prev_state, lock_state)

func open_door() -> void:
    print_debug("Open %s" % self)
    var prev_state: LockState = lock_state
    lock_state = LockState.OPEN
    animator.play(_open_animation, 0.5)
    await get_tree().create_timer(0.5).timeout
    __SignalBus.on_door_state_chaged.emit(self, prev_state, lock_state)

func toggle_door() -> void:
    if lock_state == LockState.LOCKED:
        return

    if lock_state == LockState.CLOSED:
        open_door()
    else:
        close_door()

## Attempts to unlokc and returns true if handled (only false if locked and key is missing)
func attempt_door_unlock(_puller: CameraPuller) -> bool:
    if lock_state != LockState.LOCKED:
        return true

    var player: GridPlayerCore = get_level().player

    var key_ring: KeyRingCore = player.key_ring
    if key_ring == null || !key_ring.has_key(key_id):
        NotificationsManager.warn(tr("NOTICE_DOOR_LOCKED"), tr("MISSING_ITEM").format({"item": KeyMasterCore.instance.get_description(key_id)}))
        return false


    if _consumes_key:
        if key_ring.consume_key(key_id):
            NotificationsManager.important(tr("NOTICE_DOOR_UNLOCKED"), tr("LOST_ITEM").format({"item": KeyMasterCore.instance.get_description(key_id)}))
        else:
            NotificationsManager.warn(tr("NOTICE_DOOR_LOCKED"), tr("UNLOCK_FAILED").format({"item": KeyMasterCore.instance.get_description(key_id)}))
            return true
    else:
        NotificationsManager.info(tr("NOTICE_DOOR_UNLOCKED"), tr("USED_ITEM").format({"item": KeyMasterCore.instance.get_description(key_id)}))

    var prev_state: LockState = lock_state
    lock_state = LockState.CLOSED
    __SignalBus.on_door_state_chaged.emit(self, prev_state, lock_state)
    open_door()
    return true


func needs_saving() -> bool:
    return true

func save_key() -> String:
    return "d-%s-%s" % [coordinates(), CardinalDirections.name(_door_face)]

const _LOCK_STATE_KEY: String = "lock"
const _TRIGGERED_KEY: String = "triggered"

func collect_save_data() -> Dictionary:
    return {
        _LOCK_STATE_KEY: lock_state,
        _TRIGGERED_KEY: _triggered,
    }

func _deserialize_lockstate(state: int) -> LockState:
    match state:
        0: return LockState.LOCKED
        1: return LockState.CLOSED
        2: return LockState.OPEN
        _:
            push_error("State %s is not a serialized lockstate, using initial lock state" % state)
            return _inital_lock_state

func load_save_data(data: Dictionary) -> void:
    print_debug("Door %s loads from %s" % [self, data])
    _triggered = DictionaryUtils.safe_getb(data, _TRIGGERED_KEY, false, false)

    var lock_state_int: int = DictionaryUtils.safe_geti(data, _LOCK_STATE_KEY, _inital_lock_state, false)
    lock_state = _deserialize_lockstate(lock_state_int)

    print_debug("Door %s loads with state %s" % [self, lock_state_name(lock_state)])
    if lock_state == LockState.OPEN:
        animator.play(_opened_animation)
    else:
        animator.play(_closed_animation)

    if _close_automation == CloseAutomation.PROXIMITY:
        var coords: Vector3i = coordinates()
        for entity: GridEntity in get_level().grid_entities:
            if entity != null && coords == entity.coordinates():
                _monitor_entity_for_proximity_closing(entity)
