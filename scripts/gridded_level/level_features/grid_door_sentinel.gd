extends GridEvent
class_name GridDoorSentinel

var door: GridDoor

var door_face: CardinalDirections.CardinalDirection

var automation: GridDoor.OpenAutomation
var close_automation: GridDoor.CloseAutomation

func should_trigger(
    _entity: GridEntity,
    _from: GridNode,
    _from_side: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return door.lock_state != GridDoor.LockState.OPEN

func blocks_entry_translation(
    _entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return CardinalDirections.invert(move_direction) == door_face && door.lock_state != GridDoor.LockState.OPEN

func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return exit_direction == door_face && door.lock_state != GridDoor.LockState.OPEN

func anchorage_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return side == door_face && door.lock_state == GridDoor.LockState.OPEN || super.anchorage_blocked(side)

func manages_triggering_translation() -> bool:
    return false

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if !_repeatable && _triggered:
        return

    super.trigger(entity, movement)

    if close_automation == GridDoor.CloseAutomation.PROXIMITY && !door.proximate_entitites.has(entity):
        _monitor_entity_for_closing(entity)

    if automation == GridDoor.OpenAutomation.PROXIMITY && door.lock_state == GridDoor.LockState.CLOSED:
        door.open_door()
        return

func _monitor_entity_for_closing(entity: GridEntity) -> void:
    door.proximate_entitites.append(entity)
    if entity.on_move_end.connect(_check_autoclose) != OK:
        push_error("Door %s failed to connect %s on move end for auto-closing" % [self, entity])

func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, door_face):
        return

    door.proximate_entitites.erase(entity)
    entity.on_move_end.disconnect(_check_autoclose)

    if door.proximate_entitites.is_empty():
        door.close_door()

func needs_saving() -> bool:
    return false

func save_key() -> String:
    return ""

func collect_save_data() -> Dictionary:
    return {}

func load_save_data(_data: Dictionary) -> void:
    pass
