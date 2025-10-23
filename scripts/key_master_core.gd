extends Node
class_name KeyMasterCore

static var instance: KeyMasterCore

@export
var _key_descriptions: Dictionary[String, String]

## Current support are values 1-3, will default to 1 if missing
@export
var _key_models: Dictionary[String, int]

func _enter_tree() -> void:
    if instance != null && instance != self:
        instance.queue_free()

    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null

func get_description(key: String) -> String:
    return _key_descriptions.get(key, "LOOT_KEY")

func get_key_model_id(key: String) -> int:
    return _key_models.get(key, 1)
