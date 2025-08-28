extends SpaceshipRoom
class_name PrintersRoom

@export var robots_pool: RobotsPool

@export var available_models: Array[RobotModel]

@export var printer_buttons: Array[Button]
@export var printer_statuses: Array[Label]

func _ready() -> void:
    _sync_printer_buttons()
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
        if idx > 0:
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

func _on_printer_i_button_pressed() -> void:
    pass # Replace with function body.

func _on_printer_ii_button_pressed() -> void:
    pass # Replace with function body.

func _on_printer_iii_button_pressed() -> void:
    pass # Replace with function body.
