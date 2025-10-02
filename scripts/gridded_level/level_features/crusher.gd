extends GridEvent
class_name Crusher

enum Phase { RETRACTED, CRUSHING, CRUSHED, RETRACTING }
static func phase_from_int(phase_value: int) -> Phase:
    match phase_value:
        0: return Phase.RETRACTED
        1: return Phase.CRUSHING
        2: return Phase.CRUSHED
        3: return Phase.RETRACTING
        _: return Phase.RETRACTED

@export var _managed: bool
## Note: This has no effect when managed
@export var _rest_crushed_ticks: int = 2
## Note: This has no effect when managed
@export var _rest_retracted_ticks: int = 3
@export var _start_delay_ticks: int = 0

@export var _always_block_crusher_side: bool = true
@export var _block_retracting_seconds: float = 0.3
@export var _crusher_side: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.UP
@export var _anim: AnimationPlayer

@export var _retracted_resting_anim: String = "Retracted"
@export var _crushed_resting_anim: String = "Crushed"
@export var _crush_anim: String = "Crush"
@export var _retract_anim: String = "Retract"

var _phase: Phase = Phase.RETRACTED:
    set(value):
        _phase = value
        match _phase:
            Phase.RETRACTED:
                _sync_block_retracted()
                _phase_ticks = _rest_retracted_ticks

            Phase.CRUSHING:
                _sync_block_retracted()
                _phase_ticks = 1

            Phase.CRUSHED:
                _blocks_sides = CardinalDirections.ALL_DIRECTIONS.duplicate()
                _phase_ticks = _rest_retracted_ticks

            Phase.RETRACTING:
                _blocks_sides = CardinalDirections.ALL_DIRECTIONS.duplicate()
                _phase_ticks = 1
                await get_tree().create_timer(_block_retracting_seconds).timeout
                _sync_block_retracted()

            _:
                _sync_block_retracted()

var _phase_ticks: int
var _exposed: Array[GridEntity]

func _ready() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

    _phase = Phase.RETRACTED
    _phase_ticks = _start_delay_ticks

func _handle_move_end(entity: GridEntity) -> void:
    if entity.coordinates() == coordinates():
        if !_exposed.has(entity):
            _exposed.append(entity)
    elif _exposed.has(entity):
        _exposed.erase(entity)

    if entity is not GridPlayer || _managed:
        return

    _phase_ticks -= 1
    if _phase_ticks <= 0:
        _phase = get_next_phase()
        _anim.play(get_animation())
        if _phase == Phase.CRUSHING:
            for exposed: GridEntity in _exposed:
                if exposed is GridPlayer:
                    var player: GridPlayer = exposed
                    player.robot.kill()
                elif exposed is GridEncounter:
                    var encounter: GridEncounter = exposed
                    encounter.kill()

func _sync_block_retracted() -> void:
    if _always_block_crusher_side:
        _blocks_sides = [_crusher_side]
    else:
        _blocks_sides = []

func get_next_phase() -> Phase:
    match _phase:
        Phase.RETRACTED:
            return Phase.CRUSHING
        Phase.CRUSHING:
            return Phase.CRUSHED
        Phase.CRUSHED:
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

func needs_saving() -> bool:
    return true

func save_key() -> String:
    return "cr-%s-%s" % [coordinates(), CardinalDirections.name(_crusher_side)]

const _PHASE_KEY: String = "phase"
const _PHASE_TICK_KEY: String = "tick"
const _TRIGGERED_KEY: String = "triggered"

func collect_save_data() -> Dictionary:
    return {
        _PHASE_KEY: _phase,
        _PHASE_TICK_KEY: _phase_ticks,
        _TRIGGERED_KEY: _triggered,
    }

func load_save_data(_data: Dictionary) -> void:
    _triggered = DictionaryUtils.safe_getb(_data, _TRIGGERED_KEY)

    var raw_phase: int = DictionaryUtils.safe_geti(_data, _PHASE_KEY)
    _phase = phase_from_int(raw_phase)
    _phase_ticks = DictionaryUtils.safe_geti(_data, _PHASE_TICK_KEY)
    _exposed.clear()

    var level: GridLevel = get_level()
    var coords: Vector3i = coordinates()

    for entity: GridEntity in level.grid_entities:
        if entity.coordinates() == coords:
            _exposed.append(entity)
