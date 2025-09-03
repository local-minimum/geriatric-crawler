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

func count() -> int: return _robots.size()

func max_id_counter() -> int: return _robots.reduce(func (acc: int, robot: RobotData) -> int: return maxi(acc, robot.get_id_counter()), 1000)

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
    var save: Dictionary[String, Dictionary] = {}
    for robot: RobotData in _robots:
        save[robot.id] = robot.to_save()

    return save

func load_from_save_data(data: Dictionary) -> void:
    _robots.clear()
    for _id: Variant in data:
        if _id is String:
            var id: String = _id
            var robot_save: Dictionary = DictionaryUtils.safe_getd(data, id)
            var robot: RobotData = RobotData.from_save(robot_save)
            if robot != null:
                _robots.append(robot)
                if !available_models.has(robot.model):
                    available_models.append(robot.model)

    _MAX_ROBOT_ID = max_id_counter()
