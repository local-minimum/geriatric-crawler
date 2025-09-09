extends LevelSaver
class_name SpaceshipSaver

const _PRINTERS_KEY: String = "printers"

@export var _level_name: String = "hub-spaceship"

@export var ship: Spaceship

var _destination_level: String

func _ready() -> void:
    if __SignalBus.on_before_deploy.connect(_handle_before_deploy) != OK:
        push_error("Failed to connect on before deploy")

func _handle_before_deploy(level_id: String, _robot: RobotData, _duration_days: int, _insured: bool) -> void:
    _destination_level = level_id

func collect_save_state() -> Dictionary:
    var save: Dictionary = {
        _PRINTERS_KEY: ship.printers.collect_save_data(),
    }

    return save

func get_initial_save_state() -> Dictionary:
    return {}

## When saving and loading indicates the current level
func get_level_name() -> String:
    return _level_name

## When saving indicates which level to load next time the save is loaded.
## This will be different from its own level if we're exiting for a new one
func get_level_to_load() -> String:
    return get_level_name() if _destination_level.is_empty() else _destination_level

## Only the save data for the particular level
func load_from_save(save_data: Dictionary, _entry_portal_id: String) -> void:
    ship.printers.load_from_save_data(DictionaryUtils.safe_getd(save_data, _PRINTERS_KEY))
