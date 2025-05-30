extends Node
class_name LevelSaver

func collect_save_state() -> Dictionary:
    return {}

func get_initial_save_state() -> Dictionary:
    return {}

## When saving and loading indicates the current level
func get_level_name() -> String:
    return "level-name"

## When saving indicates which level to load next time the save is loaded.
## This will be different from its own level if we're exiting for a new one
func get_level_to_load() -> String:
    return get_level_name()

func collect_initial_state() -> Dictionary:
    return {}


@warning_ignore_start("unused_parameter")
## Only the save data for the particular level
func load_from_save(save_data: Dictionary) -> void:
    pass
@warning_ignore_restore("unused_parameter")
