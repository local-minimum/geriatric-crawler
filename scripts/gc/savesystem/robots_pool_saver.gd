extends SaveExtension
class_name RobotsPoolsSaver

@export var _save_key: String = "robots"

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    if RobotsPool.instance == null:
        return _extentsion_save_data

    var save: Dictionary = _extentsion_save_data.merged(RobotsPool.instance.collect_save_data(), true)

    if GCExplorationSceneUI.instance != null:
        var robot: Robot = (GCExplorationSceneUI.instance.level.player as GridPlayer).robot
        save[robot.robot_id] = robot.collect_save_data()

    return save

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if RobotsPool.instance != null:
        RobotsPool.instance.load_from_save_data(extentsion_save_data)
