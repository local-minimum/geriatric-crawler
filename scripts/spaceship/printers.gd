extends SpaceshipRoom
class_name PrintersRoom

@export var robots_pool: RobotsPool

@export var available_models: Array[RobotModel]

@export var printer_buttons: Array[Button]
@export var printer_statuses: Array[Label]

@export var rent_panel: Control
@export var rent_down_payment_cost: Label
@export var rent_cost: Label

var _selected_printer: int = -1

func _ready() -> void:
    _sync_printer_buttons()
    _sync_printer_statues()
    _sync_panels()

func activate() -> void:
    _selected_printer = -1
    _sync_panels()
    show()

func deactivate() -> void:
    hide()

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

func _sync_panels() -> void:
    if _selected_printer < 0:
        rent_panel.hide()
    elif _is_rented(_selected_printer):
        rent_panel.hide()
    else:
        rent_down_payment_cost.text = GlobalGameState.credits_with_sign(_get_down_payement(_selected_printer))
        rent_cost.text = GlobalGameState.credits_with_sign(_get_rent(_selected_printer))
        rent_panel.show()
