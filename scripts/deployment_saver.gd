extends SaveExtension
## NOTE: Must be a late extension to modify the robot pool of the spaceship
class_name DeploymentSaver

@export var _save_key: String = "deployment"
@export var _tick_time_on_load: bool

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
var _robot_model_id: String
var _robot_given_name: String
var _insured: bool
var _days: int
var _incurred_damage: int

func _handle_day_increment(_day_of_month: int, _days_remaining_of_month: int) -> void:
    _deploying = false
    _incurred_damage = 0

func _handle_before_deploy(level_id: String, robot: RobotsPool.SpaceshipRobot, duration_days: int, insured: bool) -> void:
    _level_id = level_id

    _robot_id = robot.id
    _robot_given_name = robot.given_name
    _robot_model_id = robot.model.id

    _insured = insured
    _days = duration_days

    _deploying = true
    _incurred_damage = 0

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

const ROBOT_ID_KEY: String = "robot_id"
const ROBOT_GIVEN_NAME_KEY: String = "robot_given_name"
const ROBOT_MODEL_KEY: String = "robot_model"
const DURATION_DAYS_KEY: String = "duration"
const INSURED_KEY: String = "insured"
const LEVEL_ID_KEY: String = "level"
const INCURRED_DAMAGE_KEY: String = "damage"
const RESET_ROBOT_KEY: String = "reset_robot"

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    if !_deploying:
        return {}

    var save: Dictionary = {
        ROBOT_ID_KEY: _robot_id,
        ROBOT_GIVEN_NAME_KEY: _robot_given_name,
        ROBOT_MODEL_KEY: _robot_model_id,
        INSURED_KEY: _insured,
        DURATION_DAYS_KEY: _days,
        LEVEL_ID_KEY: _level_id,
    }

    if _incurred_damage > 0:
        save[INCURRED_DAMAGE_KEY] = _incurred_damage

    return save

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var robot_id: String = DictionaryUtils.safe_gets(extentsion_save_data, ROBOT_ID_KEY, "", false)
    var robot_model_id: String = DictionaryUtils.safe_gets(extentsion_save_data, ROBOT_MODEL_KEY, "", false)
    var robot_given_name: String = DictionaryUtils.safe_gets(extentsion_save_data, ROBOT_GIVEN_NAME_KEY, "", false)
    var level_id: String = DictionaryUtils.safe_gets(extentsion_save_data, LEVEL_ID_KEY, "", false)
    var damage: int = DictionaryUtils.safe_geti(extentsion_save_data, INCURRED_DAMAGE_KEY, 0, false)

    if RobotsPool.instance != null:
        var robot: RobotsPool.SpaceshipRobot = RobotsPool.instance.get_robot(robot_id)
        if robot != null:
            if damage > 0:
                robot.damage += damage

            robot.excursions += 1

    if ExplorationScene.instance != null:
        var level: GridLevel = ExplorationScene.instance.level
        var player: GridPlayer = level.player
        player.robot.given_name = robot_given_name
        player.robot.model = RobotModel.get_model(robot_model_id)

        level.on_change_player.emit()

    var days: int = DictionaryUtils.safe_geti(extentsion_save_data, DURATION_DAYS_KEY, 0, false)
    if _tick_time_on_load:
        if days > 0:
            __GlobalGameState.go_to_next_day(days)

    _deploying = !extentsion_save_data.is_empty() && days >= 0 && !robot_id.is_empty() && !level_id.is_empty()
    if _deploying:
        _days = days
        _robot_id = robot_id
        _robot_given_name = robot_given_name
        _robot_model_id = robot_model_id
        _level_id = level_id
        _insured = DictionaryUtils.safe_getb(extentsion_save_data, INSURED_KEY, false, false)
        _incurred_damage = damage
    else:
        _days = 0
        _robot_id = ""
        _robot_given_name = ""
        _robot_model_id = ""
        _level_id = ""
        _insured = false
        _incurred_damage = 0
