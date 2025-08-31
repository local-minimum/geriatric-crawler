extends SpaceshipRoom
class_name PrintersRoom

@export var robots_pool: RobotsPool

@export var available_models: Array[RobotModel]

@export var printer_buttons: Array[Button]
@export var printer_statuses: Array[Label]

@export var rent_panel: Control
@export var rent_down_payment_cost: Label
@export var rent_cost: Label

@export var models_panel: Control
@export var model_title: Label
@export var model_description: Label
@export var model_price: Label
@export var print_model_btn: Button
@export var buy_materials_btn: Button

var _selected_printer: int = -1
var _model_index: int = 0

func _ready() -> void:
    if __SignalBus.on_increment_day.connect(_handle_increment_day) != OK:
        push_error("Failed to connect increment day")

    _sync_printer_buttons()
    _sync_printer_statues()
    _sync_panels()

func activate() -> void:
    _selected_printer = -1
    _model_index = 0
    _sync_panels()
    show()

func deactivate() -> void:
    hide()

func _handle_increment_day(_day_of_month: int, _remaining_days: int) -> void:
    _sync_printer_statues()

func _sync_printer_buttons() -> void:
    for idx: int in range(printer_buttons.size()):
        printer_buttons[idx].text = tr("PRINTER_ID").format({"id": IntUtils.to_roman(idx + 1)})
        if idx >= robots_pool.printers:
            var parent: Control = printer_buttons[idx].get_parent()
            parent.hide()

func _sync_printer_statues() -> void:
    for idx: int in range(printer_statuses.size()):
        var status: String = ""
        var job: RobotsPool.PrinterJob = robots_pool.get_printer_job(idx)
        if !_is_rented(idx):
            status = tr("STATUS_NOT_RENTED")
        elif job == null:
            status = tr("STATUS_IDLE")
        else:
            var days: int = job.remaining_days()
            print_debug("Job %s has %s days left" % [job, days])
            if days == 0:
                status = tr("STATUS_IDLE")
            elif days == 1:
                status = tr("STATUS_PRINTING_DAY")
            else:
                status = tr("STATUS_PRINTING_DAYS").format({"days": days})

        printer_statuses[idx].text = status

func _is_rented(printer: int) -> bool: return printer == 0
func _get_down_payement(printer: int) -> int: return 5000 + printer * 2000
func _get_rent(printer: int) -> int: return printer * 200

func _on_printer_i_button_pressed() -> void:
    _toggle_select_printer(0)

func _on_printer_ii_button_pressed() -> void:
    _toggle_select_printer(1)

func _on_printer_iii_button_pressed() -> void:
    _toggle_select_printer(2)

func _toggle_select_printer(idx: int) -> void:
    if idx == _selected_printer:
        _selected_printer = -1
    else:
        _selected_printer = idx

    _sync_panels()

func _has_materials(cost: RobotsPool.PrintingCost) -> bool:
    if cost.free:
        return true

    # TODO: Figure this out
    return false

var _selected_cost: RobotsPool.PrintingCost
var _selected_model: RobotModel

func _sync_panels() -> void:
    if _selected_printer == -1:
        models_panel.hide()
        rent_panel.hide()
        return

    var active_job: RobotsPool.PrinterJob = robots_pool.get_printer_job(_selected_printer)

    if _is_rented(_selected_printer):
        var busy: bool = active_job != null && active_job.busy()
        if busy:
            models_panel.hide()
        else:
            _selected_model = robots_pool.get_model(_model_index)
            model_title.text = _selected_model.model_name

            # TODO: Figure out this
            model_description.text = ""

            _selected_cost = robots_pool.calculate_printing_costs(_selected_model, _selected_printer)
            model_price.text = tr("TOTAL_COST_PRICE").format({"price": GlobalGameState.credits_with_sign(_selected_cost.total)})

            var has_materials: bool = _has_materials(_selected_cost)
            if has_materials:
                buy_materials_btn.hide()
            else:
                buy_materials_btn.show()

            print_model_btn.text = tr("ACTION_PRINT_FREE_SAMPLE") if _selected_cost.free else tr("ACTION_PRINT")
            print_model_btn.disabled = !has_materials && __GlobalGameState.can_afford(_selected_cost.total)

            models_panel.show()
        rent_panel.hide()
    else:
        rent_down_payment_cost.text = GlobalGameState.credits_with_sign(_get_down_payement(_selected_printer))
        rent_cost.text = GlobalGameState.credits_with_sign(_get_rent(_selected_printer))
        rent_panel.show()
        models_panel.hide()

func _on_buy_missing_resources_pressed() -> void:
    pass # Replace with function body.

func _on_print_pressed() -> void:
    if _selected_cost != null && !_selected_cost.free:
        if !__GlobalGameState.withdraw_credits(_selected_cost.total):
            push_warning("Couldn't withdraw sufficient funds to start printing %s on printer %s" % [_selected_model.model_name, _selected_printer])
            return

    if !robots_pool.make_printing_job(_selected_printer, _selected_model, "Squirrel"):
        push_warning("Failed to start printing %s on printer %s" % [_selected_model.model_name, _selected_printer])

    print_debug("Started printing %s on printer %s" % [_selected_model.model_name, _selected_printer])
    _sync_printer_statues()
    _sync_panels()
