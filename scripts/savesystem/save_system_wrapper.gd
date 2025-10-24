extends Node
class_name SaveSystemWrapper

# TODO: Why is this not a static class?

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
        __SignalBus.on_load_fail.emit()
        return

    __SignalBus.on_before_load.emit()

    if !SaveSystem.instance.preload_last_save_into_cache():
        push_error("Failed to load last save")
        __SignalBus.on_load_fail.emit()
        return

    if !SaveSystem.instance.can_load_cach_onto_this_level():
        if !(__SceneSwapper as SceneSwapper).transition_to_next_scene():
            push_error("Failed to transition to next scene")
    elif !SaveSystem.instance.load_cached_save():
        push_error("Failed to load cached save")

    __SignalBus.on_load_complete.emit()

func load_cached_save() -> void:
    if !SaveSystem.instance.load_cached_save():
        push_error("Failed to load last save")
        __SignalBus.on_load_fail.emit()

    __SignalBus.on_load_complete.emit()
