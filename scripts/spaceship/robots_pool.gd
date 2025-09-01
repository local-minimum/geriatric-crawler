extends Node
class_name RobotsPool

class PrinterJob:
    var model: RobotModel
    var start_day: int
    var given_name: String

    const MODEL_NAME_KEY: String = "model"
    const START_DAY_KEY: String = "start"
    const GIVEN_NAME_KEY: String = "given_name"

    @warning_ignore_start("shadowed_variable")
    func _init(model: RobotModel, given_name: String, start_day: int = -1) -> void:
        @warning_ignore_restore("shadowed_variable")
        self.model = model
        self.given_name = given_name
        self.start_day = __GlobalGameState.game_day if start_day < 0 else start_day

    func remaining_days() -> int:
        return maxi(0, model.production.days - (__GlobalGameState.game_day - start_day))

    func busy() -> bool:
        return model.production.days - (__GlobalGameState.game_day - start_day) > 0

    func to_save() -> Dictionary:
        return {
            MODEL_NAME_KEY: model.model_name,
            START_DAY_KEY: start_day,
            GIVEN_NAME_KEY: given_name,
        }

    static func from_save(data: Dictionary, models: Array[RobotModel]) -> PrinterJob:
        var _given_name: String = DictionaryUtils.safe_gets(data, GIVEN_NAME_KEY)
        var _start_day: int = DictionaryUtils.safe_geti(data, START_DAY_KEY)
        var _model_name: String = DictionaryUtils.safe_gets(data, MODEL_NAME_KEY)
        var idx: int = models.find_custom(func (mod: RobotModel) -> bool: return mod.model_name == _model_name)
        if idx < 0:
            return null

        return PrinterJob.new(models[idx], _given_name, _start_day)

static var _MAX_ROBOT_ID: int = 1000
static func _get_next_robot_id() -> String:
    _MAX_ROBOT_ID += 1
    return "%s-%s" % [_MAX_ROBOT_ID, Time.get_ticks_msec()]

class SpaceshipRobot:
    var id: String
    var model: RobotModel
    var given_name: String
    var storage_location: Spaceship.Room
    var excursions: int
    var damage: int

    const MODEL_NAME_KEY: String = "model"
    const GIVEN_NAME_KEY: String = "given_name"
    const STORAGE_LOCATION_KEY: String = "location"
    const EXCURSIONS_KEY: String = "excursions"
    const DAMAGE_KEY: String = "damage"
    const ID_KEY: String = "id"

    @warning_ignore_start("shadowed_variable")
    func _init(
        model: RobotModel,
        given_name: String,
        storage_location: Spaceship.Room = Spaceship.Room.PRINTERS,
        excursions: int = 0,
        damage: int = 0,
    ) -> void:
        @warning_ignore_restore("shadowed_variable")
        self.model = model
        self.given_name = given_name
        self.storage_location = storage_location
        self.excursions = excursions
        self.damage = damage
        self.id = RobotsPool._get_next_robot_id()

    func to_save() -> Dictionary:
        return {
            ID_KEY: id,
            MODEL_NAME_KEY: model.model_name,
            GIVEN_NAME_KEY: given_name,
            STORAGE_LOCATION_KEY: storage_location,
            EXCURSIONS_KEY: excursions,
            DAMAGE_KEY: damage,
        }

    static func from_save(data: Dictionary, models: Array[RobotModel]) -> SpaceshipRobot:
        var _given_name: String = DictionaryUtils.safe_gets(data, GIVEN_NAME_KEY)
        var _model_name: String = DictionaryUtils.safe_gets(data, MODEL_NAME_KEY)

        var _id: String = DictionaryUtils.safe_gets(data, ID_KEY, RobotsPool._get_next_robot_id())
        var _id_counter: int = int(_id.split("-")[0])
        RobotsPool._MAX_ROBOT_ID = maxi(RobotsPool._MAX_ROBOT_ID, _id_counter)

        var idx: int = models.find_custom(func (mod: RobotModel) -> bool: return mod.model_name == _model_name)
        if idx < 0:
            return null

        var _excursions: int = DictionaryUtils.safe_geti(data, EXCURSIONS_KEY)
        var _damage: int = DictionaryUtils.safe_geti(data, DAMAGE_KEY)
        var room: Spaceship.Room = Spaceship.to_room(DictionaryUtils.safe_geti(data, STORAGE_LOCATION_KEY), Spaceship.Room.PRINTERS)

        var robot: SpaceshipRobot = SpaceshipRobot.new(models[idx], _given_name, room, _excursions, _damage)
        robot.id = _id

        return robot

@export var base_robot: RobotModel
@export var available_models: Array[RobotModel]
@export var printers: int = 3

var _free_starter_robot_printed: bool
var _robots: Array[SpaceshipRobot]

func available_robots() -> Array[SpaceshipRobot]:
    return _robots

func get_robot(id: String) -> SpaceshipRobot:
    if id.is_empty():
        return null

    for robot: SpaceshipRobot in _robots:
        if robot.id == id:
            return robot
    return null

var _printer_jobs: Array[PrinterJob]

func _ready() -> void:
    _printer_jobs.clear()
    for _idx: int in range(printers):
        _printer_jobs.append(null)

    if __SignalBus.on_increment_day.connect(_handle_increment_day) != OK:
        push_error("Failed to connect increment day")

func _handle_increment_day(_dom: int, _days_left_of_month: int) -> void:
    for printer: int in range(_printer_jobs.size()):
        var job: PrinterJob = _printer_jobs[printer]
        if job == null:
            continue

        if !job.busy():
            _printer_jobs[printer] = null
            _complete_printer_job(job)

func _complete_printer_job(job: PrinterJob) -> void:
    _robots.append(SpaceshipRobot.new(job.model, job.given_name))
    NotificationsManager.info(tr("NOTICE_PRINTING"), tr("PRINTING_ITEM_DONE").format({"item": job.given_name}))

func printer_is_rented(printer: int) -> bool: return printer == 0
func get_printer_down_payement(printer: int) -> int: return 5000 + printer * 2000
func get_printer_rent(printer: int) -> int: return printer * 200

func get_printer_job(printer: int) -> PrinterJob:
    if printer < 0 || printer >= _printer_jobs.size():
        return null

    return _printer_jobs[printer]

func make_printing_job(printer: int, model: RobotModel, given_name: String) -> bool:
    if printer >= printers || _printer_jobs[printer] != null && _printer_jobs[printer].busy():
        return false

    _printer_jobs[printer] = PrinterJob.new(model, given_name)
    print_debug("[RobotsPool] started printing %s" % model.model_name)
    return true

class PrintingCost:
    var ip_cost_credits: int
    var printer_day_costs: int
    var materials: Dictionary[String, float]
    var total: int:
        get(): return ip_cost_credits + printer_day_costs

    var free: bool

    func _init(model: RobotModel, printer_cost: int, free_of_charge: bool = false) -> void:
        free = free_of_charge
        ip_cost_credits = model.production.credits
        printer_day_costs = printer_cost
        materials = model.production.materials


func printer_day_rate(printer: int) -> int: return printer * 100 + 200

func calculate_printing_costs(model: RobotModel, printer: int) -> PrintingCost:
    var free_of_charge: bool = model == base_robot && !_free_starter_robot_printed

    return PrintingCost.new(
        model,
        printer_day_rate(printer) * maxi(1, model.production.days - printer),
        free_of_charge,
    )

func get_model(idx: int) -> RobotModel:
    return available_models[idx]

const _RENTED_PRINTERS_KEY: String = "rented-printer"
const _JOBS_KEY: String = "jobs"
const _FREE_STARTER_PRINTED_KEY: String = "free-printed"
const _ROBOTS_KEY: String = "robots"

func collect_save_data() -> Dictionary:
    return {
        _FREE_STARTER_PRINTED_KEY: _free_starter_robot_printed,
        _RENTED_PRINTERS_KEY: range(printers).map(func (idx: int) -> bool: return printer_is_rented(idx)),
        _JOBS_KEY: _printer_jobs.map(func (job: PrinterJob) -> Dictionary: return job.to_save() if job else {}),
    }

func load_from_save_data(data: Dictionary) -> void:
    _free_starter_robot_printed = DictionaryUtils.safe_getb(data, _RENTED_PRINTERS_KEY, false)
    # TODO: When we can unlock printers do load them here

    # Note that available models need to be loaded first
    _printer_jobs.clear()
    for job_data_item: Variant in DictionaryUtils.safe_geta(data, _JOBS_KEY, [], false):
        if job_data_item is Dictionary:
            @warning_ignore_start("unsafe_call_argument")
            var job: PrinterJob = PrinterJob.from_save(job_data_item, available_models)
            @warning_ignore_restore("unsafe_call_argument")
            _printer_jobs.append(job)
