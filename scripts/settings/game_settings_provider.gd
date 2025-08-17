extends Node
class_name GameSettingsProvider

@warning_ignore_start("unused_private_class_variable")
static var _cache: Dictionary
@warning_ignore_restore("unused_private_class_variable")

func get_setting(_key: String, default: Variant = null) -> Variant:
    return default

func get_settingi(_key: String, default: int = 0) -> int:
    return default

func set_setting(_key: String, _value: Variant) -> void:
    pass

func set_settingi(_key: String, _value: int) -> void:
    pass
