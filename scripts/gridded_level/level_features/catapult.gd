extends GridEvent
class_name Catapult

enum Phase { NONE, CENTERING, ORIENTING, FLYING, CRASHING }
enum Targets { EVERYONE, PLAYER, ENEMY }
@export var _targets: Targets

@export var _orient_entity: bool = false

@export var _crashes_forward: bool = false
@export var _crash_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NONE

static var _managed_entities: Dictionary[GridEntity, Catapult]
static var _entity_phases: Dictionary[GridEntity, Phase]
static var _prev_coordinates: Dictionary[GridEntity, Vector3i]

var field_direction: CardinalDirections.CardinalDirection:
    get():
        return CardinalDirections.invert(_trigger_sides[0])

func _ready() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

func _exit_tree() -> void:
    for entity: GridEntity in _managed_entities:
        if _managed_entities[entity] == self:
            _release_entity(entity)

func _release_entity(entity: GridEntity) -> void:
    if !_managed_entities.erase(entity):
        push_warning("Could not remove entity '%s' as held though it should have been there" % entity.name)

    if !_entity_phases.erase(entity):
        push_warning("Could not remove entity '%s' from phase tracking" % entity.name)

    if !_prev_coordinates.erase(entity):
        push_warning("Could not clear entity '%s' previous coordinates" % entity.name)

    if _crashes_forward:
        if !entity.attempt_movement(Movement.MovementType.FORWARD, false, true):
            push_warning("Failed to crash entity %s forward" % entity.name)
    elif _crash_direction != CardinalDirections.CardinalDirection.NONE:
        if !entity.attempt_movement(Movement.from_directions(_crash_direction, entity.look_direction, entity.down), false, true):
            push_warning("Failed to crash entity %s %s" % [entity.name, _crash_direction])

    entity.cinematic = false
    entity.clear_queue()
    print_debug("[Catapult] %s released" % entity.name)

func _handle_move_end(entity: GridEntity) -> void:
    if _managed_entities.get(entity) != self:
        return

    match _entity_phases.get(entity, Phase.NONE):
        Phase.NONE:
            print_debug("[Catapult] %s nothing" % entity.name)
            if entity.attempt_movement(Movement.MovementType.CENTER, false, true):
                _entity_phases[entity] = Phase.CENTERING
        Phase.CENTERING:
            print_debug("[Catapult] %s centered" % entity.name)
            if _orient_entity:
                _entity_phases[entity] = Phase.FLYING
            else:
                if !_fly(entity) || _prev_coordinates.get(entity, Vector3i.ZERO) == entity.coordinates():
                    _entity_phases[entity] = Phase.CRASHING
                else:
                    _entity_phases[entity] = Phase.FLYING
        Phase.FLYING:
            print_debug("[Catapult] %s flying" % entity.name)
            if !_fly(entity) || _prev_coordinates.get(entity, Vector3i.ZERO) == entity.coordinates():
                print_debug("[Catapult] %s is now crashing" % entity.name)
                _entity_phases[entity] = Phase.CRASHING
            else:
                _prev_coordinates[entity] = entity.coordinates()
        Phase.CRASHING:
            print_debug("[Catapult] %s crashing" % entity.name)
            _release_entity(entity)

func _fly(entity: GridEntity) -> bool:
    var direction: CardinalDirections.CardinalDirection = field_direction
    var movement: Movement.MovementType = Movement.from_directions(
        direction,
        entity.look_direction,
        entity.down,
    )

    if movement == Movement.MovementType.NONE:
        _release_entity(entity)
        return false

    return entity.attempt_movement(movement, false, true)

func trigger(entity: GridEntity, _movement: Movement.MovementType) -> void:
    _triggered = true

    if !_managed_entity(entity):
        return

    print_debug("[Catapult] Grabbing %s" % [entity.name])

    entity.cinematic = true
    _managed_entities[entity] = self
    _entity_phases[entity] = Phase.NONE

    _lay_claim.call_deferred(entity)

func _lay_claim(entity: GridEntity) -> void:
    _prev_coordinates[entity] = entity.coordinates()
    if entity.attempt_movement(Movement.MovementType.CENTER, false, true):
        _entity_phases[entity] = Phase.CENTERING

func _managed_entity(entity: GridEntity) -> bool:
    if _managed_entities.get(entity) == self:
        return false

    if entity is GridPlayer:
        return _targets != Targets.ENEMY
    else:
        return _targets != Targets.PLAYER

func _tick() -> void:
    pass
