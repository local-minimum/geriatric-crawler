extends Node
class_name AccessibilitySettings

enum Handedness { LEFT, RIGHT }

static var handedness: Handedness = Handedness.RIGHT

const _HANDEDNESS_KEY: String = "accessibility.handedness"

@export var settings: GameSettingsProvider

func _ready() -> void:
    handedness = _int_to_handedness(settings.get_settingi(_HANDEDNESS_KEY, handedness))
    __SignalBus.on_update_handedness.emit(handedness)

func _int_to_handedness(value: int) -> Handedness:
    match value:
        0: return Handedness.LEFT
        1: return Handedness.RIGHT
        _:
            push_error("%s is not a handedness" % value)
            return Handedness.RIGHT

func set_handedness(value: Handedness) -> void:
    handedness = value
    settings.set_settingi(_HANDEDNESS_KEY, value)
    __SignalBus.on_update_handedness.emit(handedness)
