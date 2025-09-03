extends Node
class_name SaveExtension

@export var warn_missing: bool = true

func get_key() -> String:
    return ""

func load_from_initial_if_save_missing() -> bool:
    return true

@warning_ignore_start("unused_parameter")
func retrieve_data(extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func initial_data(extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    pass
@warning_ignore_restore("unused_parameter")
