extends GridEvent
class_name Crusher

enum Phase { RETRACTED, CRUSHING, CRUSHED, RETRACTING }

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

func _ready() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

    _phase = Phase.RETRACTED
    _phase_ticks = _start_delay_ticks

func _handle_move_end(entity: GridEntity) -> void:
    if entity is not GridPlayer || _managed:
        return

    _phase_ticks -= 1
    if _phase_ticks <= 0:
        _phase = get_next_phase()
        _anim.play(get_animation())

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
