extends SaveExtension
class_name RobotMapperSaver

const _HISTORY_KEY: String = "history"

func get_key() -> String:
    return "exploration-history"

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(extentsion_save_data: Dictionary) -> Dictionary:
    if RobotExploratoinMapper.active_mapper == null:
        return extentsion_save_data
    return {
        _HISTORY_KEY: RobotExploratoinMapper.active_mapper.history()
    }

func initial_data(extentsion_save_data: Dictionary) -> Dictionary:
    return extentsion_save_data

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if RobotExploratoinMapper.active_mapper == null:
        return

    var raw_history: Array = DictionaryUtils.safe_geta(extentsion_save_data, _HISTORY_KEY, [], false)
    var history: Array[Vector3i] = []
    for item: Variant in raw_history:
        if item is Vector3i:
            history.append(item)

    RobotExploratoinMapper.active_mapper.load_history(history)
