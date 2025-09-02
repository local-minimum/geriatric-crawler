extends CanvasLayer

@export var _progress_label: Label

func _ready() -> void:
    if __SignalBus.on_scene_transition_initiate.connect(_show_ui) != OK:
        push_error("Failed to connect scene transition initiate")

    if __SignalBus.on_scene_transition_fail.connect(_fail) != OK:
        push_error("Failed to connect scene transition fail")

    if __SignalBus.on_scene_transition_complete.connect(_hide_ui) != OK:
        push_error("Failed to connect scene transition initiate")

    if __SignalBus.on_scene_transition_progress.connect(_update_progress) != OK:
        push_error("Failed to connect scene transition progress")

    hide()

func _show_ui(_target_scene: String) -> void:
    _update_progress(0)
    show()

func _fail(_target_scene: String) -> void:
    NotificationsManager.warn(tr("NOTICE_SYSTEM_ERROR"), tr("FAILED_TO_CHANGE_SCENE"))
    _hide_ui(_target_scene)

func _hide_ui(_target_scene: String) -> void:
    hide()

func _update_progress(progress: float) -> void:
    _progress_label.text = "%03d%%" % ceili(progress * 100)
