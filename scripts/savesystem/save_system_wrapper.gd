extends Node
class_name SaveSystemWrapper

func autosave() -> void:
    if SaveSystem.instance == null:
        push_error("No save system loaded")
        return

    __SignalBus.on_before_save.emit()

    SaveSystem.instance.save_last_slot()

    __SignalBus.on_save_complete.emit()

func load_last_save() -> void:
    if SaveSystem.instance == null:
        push_error("No save system loaded")
        __SignalBus.on_fail_load.emit()
        return

    __SignalBus.on_before_load.emit()

    if !SaveSystem.instance.load_last_save():
        push_error("Failed to load last save")
        __SignalBus.on_fail_load.emit()
        return

    __SignalBus.on_load_complete.emit()

func load_cached_save() -> void:
    if !SaveSystem.instance.load_cached_save():
        push_error("Failed to load last save")
        __SignalBus.on_fail_load.emit()

    __SignalBus.on_load_complete.emit()
