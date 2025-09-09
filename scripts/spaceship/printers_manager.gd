extends Node
class_name PrintersManager

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

    static func from_save(data: Dictionary) -> PrinterJob:
        if data.is_empty():
            return null

        var _given_name: String = DictionaryUtils.safe_gets(data, GIVEN_NAME_KEY, "", false)
        var _start_day: int = DictionaryUtils.safe_geti(data, START_DAY_KEY, -1, false)
        var _model_name: String = DictionaryUtils.safe_gets(data, MODEL_NAME_KEY, "", false)
        if _start_day == -1 || _model_name.is_empty():
            return null

        var _model: RobotModel = RobotModel.get_model(_model_name)
        if _model == null:
            return null

        return PrinterJob.new(_model, _given_name, _start_day)

@export var printers: int = 3
@export var robots: RobotsPool

var _printer_jobs: Array[PrinterJob]
var _unlocked_printers: Array[bool]

var _free_starter_robot_printed: bool

func _ready() -> void:
    _printer_jobs.clear()
    _unlocked_printers.clear()

    for idx: int in range(printers):
        _printer_jobs.append(null)
        _unlocked_printers.append(idx == 0)

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
    robots.add_new_robot(RobotData.new(job.model, job.given_name))
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
    var free_of_charge: bool = model == robots.base_robot && !_free_starter_robot_printed

    return PrintingCost.new(
        model,
        printer_day_rate(printer) * maxi(1, model.production.days - printer),
        free_of_charge,
    )

const _RENTED_PRINTERS_KEY: String = "rented-printer"
const _JOBS_KEY: String = "jobs"
const _FREE_STARTER_PRINTED_KEY: String = "free-printed"

func collect_save_data() -> Dictionary:
    return {
        _FREE_STARTER_PRINTED_KEY: _free_starter_robot_printed,
        _RENTED_PRINTERS_KEY: range(printers).map(func (idx: int) -> bool: return printer_is_rented(idx)),
        _JOBS_KEY: _printer_jobs.map(func (job: PrinterJob) -> Dictionary: return job.to_save() if job else {}),
    }

func load_from_save_data(data: Dictionary) -> void:
    _free_starter_robot_printed = DictionaryUtils.safe_getb(data, _FREE_STARTER_PRINTED_KEY, false, false)

    _unlocked_printers.clear()
    for printer_status: Variant in DictionaryUtils.safe_geta(data, _RENTED_PRINTERS_KEY, [], false):
        if printer_status is bool:
            _unlocked_printers.append(printer_status)
        else:
            _unlocked_printers.append(false)

    for idx: int in range(printers):
        if idx < _unlocked_printers.size():
            continue
        _unlocked_printers.append(idx == 0)

    _printer_jobs.clear()
    for job_data_item: Variant in DictionaryUtils.safe_geta(data, _JOBS_KEY, [], false):
        if job_data_item is Dictionary:
            @warning_ignore_start("unsafe_call_argument")
            var job: PrinterJob = PrinterJob.from_save(job_data_item)
            @warning_ignore_restore("unsafe_call_argument")
            _printer_jobs.append(job)

    for idx: int in range(printers):
        if idx < _printer_jobs.size():
            continue
        _printer_jobs.append(null)
