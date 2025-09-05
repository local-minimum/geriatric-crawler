extends SaveExtension
## NOTE: Must be a late extension to modify the robot pool of the spaceship
class_name DeploymentSaver

@export var _save_key: String = "deployment"
@export var _tick_time_on_load: bool
@export var _tick_excursions_on_load: bool

func _enter_tree() -> void:
    if __SignalBus.on_increment_day.connect(_handle_day_increment) != OK:
        push_warning("Failed to connect day increment")

    if __SignalBus.on_before_deploy.connect(_handle_before_deploy) != OK:
        push_warning("Failed to connect before deploy")

func _exit_tree() -> void:
    __SignalBus.on_before_deploy.disconnect(_handle_before_deploy)
    __SignalBus.on_increment_day.disconnect(_handle_day_increment)

var _deploying: bool
var _level_id: String
var _robot_id: String
var _insured: bool
var _days: int

func _handle_day_increment(_day_of_month: int, _days_remaining_of_month: int) -> void:
    _deploying = false

func _handle_before_deploy(level_id: String, robot: RobotData, duration_days: int, insured: bool) -> void:
    _level_id = level_id

    _robot_id = robot.id

    _insured = insured
    _days = duration_days

    _deploying = true

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

const ROBOT_ID_KEY: String = "robot_id"
const DURATION_DAYS_KEY: String = "duration"
const INSURED_KEY: String = "insured"
const LEVEL_ID_KEY: String = "level"

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    if !_deploying:
        return {}

    var save: Dictionary = {
        ROBOT_ID_KEY: _robot_id,
        INSURED_KEY: _insured,
        DURATION_DAYS_KEY: _days,
        LEVEL_ID_KEY: _level_id,
    }

    return save

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var robot_id: String = DictionaryUtils.safe_gets(extentsion_save_data, ROBOT_ID_KEY, "", false)
    var level_id: String = DictionaryUtils.safe_gets(extentsion_save_data, LEVEL_ID_KEY, "", false)

    if RobotsPool.instance != null:
        var robot: RobotData = RobotsPool.instance.get_robot(robot_id)
        if robot != null && _tick_excursions_on_load:
            robot.excursions += 1

    if ExplorationScene.instance != null:
        var level: GridLevel = ExplorationScene.instance.level
        var player: GridPlayer = level.player
        if RobotsPool.instance != null:
            player.robot.load_from_data(RobotsPool.instance.get_robot(robot_id))
        else:
            player.robot.robot_id = robot_id

        level.on_change_player.emit()

    var days: int = DictionaryUtils.safe_geti(extentsion_save_data, DURATION_DAYS_KEY, 0, false)
    if _tick_time_on_load:
        if days > 0:
            __GlobalGameState.go_to_next_day(days)

    _deploying = !extentsion_save_data.is_empty() && days >= 0 && !robot_id.is_empty() && !level_id.is_empty()
    if _deploying:
        _days = days
        _robot_id = robot_id
        _level_id = level_id
        _insured = DictionaryUtils.safe_getb(extentsion_save_data, INSURED_KEY, false, false)
    else:
        _days = 0
        _robot_id = ""
        _level_id = ""
        _insured = false
