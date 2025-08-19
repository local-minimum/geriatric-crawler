extends Node
class_name TutorialSettings

const _TUTORIALS_ROOT_KEY: String = "tutorial"

@export var settings: GameSettingsProvider

func get_tutorial_progress(part: String) -> int:
    return settings.get_settingi("%s.part.%s" % [_TUTORIALS_ROOT_KEY, part])

func set_tutorial_progress(part: String, progress: int) -> void:
    settings.set_settingi("%s.part.%s" % [_TUTORIALS_ROOT_KEY, part], progress)

func reset_all_tutorials() -> void:
    for key: String in settings.get_all_keys():
        if key.begins_with(_TUTORIALS_ROOT_KEY):
            settings.remove_setting(key)
