extends Node
class_name RobotsPool

static var instance: RobotsPool
static var _MAX_ROBOT_ID: int = 1000
static func _get_next_robot_id() -> String:
    _MAX_ROBOT_ID += 1
    return "%s-%s" % [_MAX_ROBOT_ID, Time.get_ticks_msec()]

@export var base_robot: RobotModel
@export var available_models: Array[RobotModel]

var _robots: Array[RobotData]

func available_robots() -> Array[RobotData]:
    return _robots

func get_robot(id: String) -> RobotData:
    if id.is_empty():
        return null

    for robot: RobotData in _robots:
        if robot.id == id:
            return robot
    return null

func add_new_robot(robot: RobotData) -> void:
    _robots.append(robot)

func _enter_tree() -> void:
    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null


func get_model(idx: int) -> RobotModel:
    return available_models[idx]

const _ROBOTS_KEY: String = "robots"

func collect_save_data() -> Dictionary:
    return {
        _ROBOTS_KEY: _robots.map(func (robot: RobotData) -> Dictionary: return robot.to_save()),
    }

func load_from_save_data(data: Dictionary) -> void:
    _robots.clear()
    for robot_data: Variant in DictionaryUtils.safe_geta(data, _ROBOTS_KEY, [], false):
        if robot_data is Dictionary:
            @warning_ignore_start("unsafe_call_argument")
            var robot: RobotData = RobotData.from_save(robot_data)
            @warning_ignore_restore("unsafe_call_argument")
            _robots.append(robot)
