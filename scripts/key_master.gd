extends Node
class_name KeyMaster

@export
var _key_descriptions: Dictionary[String, String]

## Current support are values 1-3, will default to 1 if missing
@export
var _key_models: Dictionary[String, int]

@export
var default_key_description: String = "key"

static var instance: KeyMaster

func _ready() -> void:
    instance = self

func get_description(key: String) -> String:
    return _key_descriptions.get(key, default_key_description)


func get_key_model_id(key: String) -> int:
    return _key_models.get(key, 1)

func clear_keys() -> void:
    _key_descriptions.clear()
    _key_models.clear()

func add_key(id: String, description: String = "", model: int = 1) -> void:
    if id.begins_with(KeyRing.KEY_PREFIX):
        id = id.substr(KeyRing.KEY_PREFIX.length())

    if !description.is_empty():
        _key_descriptions[id] = description
    else:
        @warning_ignore_start("return_value_discarded")
        _key_descriptions.erase(id)
        @warning_ignore_restore("return_value_discarded")

    if model > 0:
        _key_models[id] = model
    else:
        @warning_ignore_start("return_value_discarded")
        _key_models.erase(id)
        @warning_ignore_restore("return_value_discarded")
