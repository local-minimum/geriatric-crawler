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


@export var printers: int = 3

@export var robots: Array[Robot]

func available_robots() -> Array[Robot]:
    return robots

var _printer_jobs: Array[PrinterJob]

func _ready() -> void:
    _printer_jobs.clear()
    for _idx: int in range(printers):
        _printer_jobs.append(null)

    # TODO: Load/Save jobs

func get_printer_job(printer: int) -> PrinterJob:
    if printer >= _printer_jobs.size():
        return null

    return _printer_jobs[printer]

func make_printing_job(printer: int, model: RobotModel, given_name: String) -> bool:
    if printer >= printers || _printer_jobs[printer] != null && _printer_jobs[printer].busy():
        return false

    _printer_jobs[printer] = PrinterJob.new(model, given_name)
    return true
