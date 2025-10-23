extends GridEvent
class_name GridDoorSentinel

var door: GridDoorCore

var door_face: CardinalDirections.CardinalDirection

var automation: GridDoorCore.OpenAutomation
var close_automation: GridDoorCore.CloseAutomation

func _ready() -> void:
    super._ready()

    if __SignalBus.on_move_start.connect(_handle_entity_move_start) != OK:
        push_error("Failed to connect on move start")
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect on move end")

var _check_onto_closed: Array[GridEntity]
var _check_traversing_autoclose: Array[GridEntity]
var _check_move_end_autoclose: Array[GridEntity]
var _check_move_end_do_autoclose: Array[GridEntity]

func _handle_move_end(entity: GridEntity) -> void:
    if _check_move_end_autoclose.has(entity):
        _check_autoclose(entity)

func _handle_entity_move_start(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if _check_onto_closed.has(entity):
        _check_walk_onto_closed_door(entity, from, translation_direction)
        return
    elif _check_traversing_autoclose.has(entity):
        _check_traversing_door_should_autoclose(entity, from, translation_direction)

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
    return CardinalDirections.invert(move_direction) == door_face && (
        door.lock_state != GridDoorCore.LockState.OPEN ||
        door.block_traversal_anchor_sides.has(entity.get_grid_anchor_direction())
    )

func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return exit_direction == door_face && door.lock_state != GridDoorCore.LockState.OPEN

func anchorage_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return side == door_face && door.lock_state == GridDoorCore.LockState.OPEN || super.anchorage_blocked(side)

func manages_triggering_translation() -> bool:
    return false

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if !_repeatable && _triggered:
        return

    super.trigger(entity, movement)

    if close_automation == GridDoorCore.CloseAutomation.PROXIMITY:
        _monitor_entity_for_closing(entity)
    elif close_automation == GridDoorCore.CloseAutomation.END_WALK:
        if !_check_traversing_autoclose.has(entity):
            _check_traversing_autoclose.append(entity)

    if door.lock_state == GridDoorCore.LockState.CLOSED:
        if automation == GridDoorCore.OpenAutomation.PROXIMITY:
            print_debug("Sentinel opens %s" % door)
            door.open_door()
            return

    if automation == GridDoorCore.OpenAutomation.WALK_INTO:
        if !_check_onto_closed.has(entity):
            _check_onto_closed.append(entity)
        return

func _check_walk_onto_closed_door(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    print_debug("SENTINEL: %s %s vs %s and %s vs %s" % [
        door,
        from,
        coordinates(),
        CardinalDirections.name(translation_direction),
        CardinalDirections.name(door_face),
    ])

    _check_onto_closed.erase(entity)

    if from != coordinates() && entity.coordinates() != coordinates():
        return

    if from == coordinates() && translation_direction == door_face:
        print_debug("Sentinel opens %s" % door)
        door.open_door()

func _monitor_entity_for_closing(entity: GridEntity) -> void:
    if !door.proximate_entitites.has(entity):
        door.proximate_entitites.append(entity)

    if !_check_move_end_autoclose.has(entity):
        _check_move_end_autoclose.append(entity)

func _check_traversing_door_should_autoclose(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if entity.coordinates() != coordinates():
        _check_traversing_autoclose.erase(entity)

    if from == coordinates() && translation_direction == door_face && door.lock_state == GridDoorCore.LockState.OPEN:
        if !_check_move_end_do_autoclose.has(entity):
            _check_move_end_do_autoclose.append(entity)

func _do_autoclose(entity: GridEntity) -> void:
    _check_move_end_do_autoclose.erase(entity)

    if door.lock_state == GridDoorCore.LockState.OPEN:
        door.close_door()

func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, door_face):
        return

    door.proximate_entitites.erase(entity)
    _check_move_end_autoclose.erase(entity)

    if door.proximate_entitites.is_empty() && door.lock_state == GridDoorCore.LockState.OPEN:
        print_debug("%s close door" % self)
        door.close_door()
        return

    print_debug("%s don't close door %s" % [self, door.proximate_entitites])

func needs_saving() -> bool:
    return false

func save_key() -> String:
    return ""

func collect_save_data() -> Dictionary:
    return {}

func load_save_data(_data: Dictionary) -> void:
    pass
