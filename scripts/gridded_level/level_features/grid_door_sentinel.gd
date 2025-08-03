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
    return true

func blocks_entry_translation(
    entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
    _silent: bool = false,
) -> bool:
    return CardinalDirections.invert(move_direction) == door_face && (
        door.lock_state != GridDoor.LockState.OPEN ||
        door.block_traversal_anchor_sides.has(entity.get_grid_anchor_direction())
    )

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

    if close_automation == GridDoor.CloseAutomation.PROXIMITY:
        _monitor_entity_for_closing(entity)
    elif close_automation == GridDoor.CloseAutomation.END_WALK:
        _monitor_entity_for_walkthrough_closing(entity)

    if door.lock_state == GridDoor.LockState.CLOSED:
        if automation == GridDoor.OpenAutomation.PROXIMITY:
            print_debug("Sentinel opens %s" % door)
            door.open_door()
            return

    if automation == GridDoor.OpenAutomation.WALK_INTO:
        if !entity.on_move_start.is_connected(_check_walk_onto_closed_door):
            if entity.on_move_start.connect(_check_walk_onto_closed_door) != OK:
                push_error("Failed to connect %s on move start to check door opening" % entity)
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

    if from != coordinates() && entity.coordinates() != coordinates():
        entity.on_move_start.disconnect(_check_walk_onto_closed_door)
        return

    if from == coordinates() && translation_direction == door_face:
        print_debug("Sentinel opens %s" % door)
        door.open_door()
        entity.on_move_start.disconnect(_check_walk_onto_closed_door)

func _monitor_entity_for_closing(entity: GridEntity) -> void:
    if !door.proximate_entitites.has(entity):
        door.proximate_entitites.append(entity)

    if !entity.on_move_end.is_connected(_check_autoclose):
        print_debug("%s monitors %s" % [self, entity])
        if entity.on_move_end.connect(_check_autoclose) != OK:
            push_error("Door %s failed to connect %s on move end for auto-closing" % [self, entity])

func _monitor_entity_for_walkthrough_closing(
    entity: GridEntity,
) -> void:
    if entity.on_move_start.is_connected(_check_traversing_door_should_autoclose):
        return

    if entity.on_move_start.connect(_check_traversing_door_should_autoclose) != OK:
        push_error("Door %s failed to connect %s on move start for walk through auto-closing" % [self, entity])

func _check_traversing_door_should_autoclose(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if entity.coordinates() != coordinates():
        entity.on_move_start.disconnect(_check_traversing_door_should_autoclose)

    if from == coordinates() && translation_direction == door_face && door.lock_state == GridDoor.LockState.OPEN:
        if entity.on_move_end.connect(_do_autoclose) != OK:
            push_error("Door %s failed to conntect %s on move end when walking through door to autoclose it" % [self, entity])

func _do_autoclose(entity: GridEntity) -> void:
    entity.on_move_end.disconnect(_do_autoclose)

    if door.lock_state == GridDoor.LockState.OPEN:
        door.close_door()

func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, door_face):
        return

    door.proximate_entitites.erase(entity)
    entity.on_move_end.disconnect(_check_autoclose)

    if door.proximate_entitites.is_empty() && door.lock_state == GridDoor.LockState.OPEN:
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
