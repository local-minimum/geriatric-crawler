extends Node
class_name RobotsPool

class PrinterJob:
    var model: RobotModel
    var start_day: int
    var given_name: String

    @warning_ignore_start("shadowed_variable")
    func _init(model: RobotModel, given_name: String) -> void:
        @warning_ignore_restore("shadowed_variable")
        self.model = model
        self.given_name = given_name
        start_day = __GlobalGameState.game_day

    func remaining_days() -> int:
        return maxi(0, __GlobalGameState.game_day - start_day - model.production.days)

    func busy() -> bool:
        return __GlobalGameState.game_day - start_day - model.production.days > 0

class SpaceshipRobot:
    var model: RobotModel
    var given_name: String
    var storage_location: Spaceship.Room
    var excursions: int
    var damage: int

    @warning_ignore_start("shadowed_variable")
    func _init(
        model: RobotModel,
        given_name: String,
        storage_location: Spaceship.Room = Spaceship.Room.PRINTERS,
    ) -> void:
        @warning_ignore_restore("shadowed_variable")
        self.model = model
        self.given_name = given_name
        self.storage_location = storage_location


@export var base_robot: RobotModel
@export var available_models: Array[RobotModel]
@export var printers: int = 3

var _robots: Array[SpaceshipRobot]

func available_robots() -> Array[SpaceshipRobot]:
    return _robots

var _printer_jobs: Array[PrinterJob]

func _ready() -> void:
    _printer_jobs.clear()
    for _idx: int in range(printers):
        _printer_jobs.append(null)

    if __SignalBus.on_increment_day.connect(_handle_new_day) != OK:
        push_error("Failed to connect increment day")
    # TODO: Load/Save jobs

func _handle_new_day(_dom: int, _days_left_of_month: int) -> void:
    for printer: int in range(_printer_jobs.size()):
        var job: PrinterJob = _printer_jobs[printer]
        if job == null:
            continue

        if !job.busy():
            _printer_jobs[printer] = null
            _complete_printer_job(job)

func _complete_printer_job(job: PrinterJob) -> void:
    _robots.append(SpaceshipRobot.new(job.model, job.given_name))

func get_printer_job(printer: int) -> PrinterJob:
    if printer >= _printer_jobs.size():
        return null

    return _printer_jobs[printer]

func make_printing_job(printer: int, model: RobotModel, given_name: String) -> bool:
    if printer >= printers || _printer_jobs[printer] != null && _printer_jobs[printer].busy():
        return false

    _printer_jobs[printer] = PrinterJob.new(model, given_name)
    return true
