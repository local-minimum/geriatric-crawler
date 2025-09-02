extends SaveSceneLoader
class_name SceneSwapper

@export var scenes: Dictionary[String, String]

var path: String

func load_root_scene_by_id(scene_id: String) -> bool:
    if !scenes.has(scene_id):
        path = ""
        return false

    path = scenes[scene_id]
    if ResourceLoader.load_threaded_request(scenes[scene_id], "PackedScene") != OK:
        push_error("Failed to initiate root swapping to '%s'" % path)
        path = ""
        return false

    return true


func _process(_delta: float) -> void:
    if path.is_empty():
        return
    else:
        _loading_next_scene()

func _loading_next_scene() -> void:
    var progress: Array = []

    match ResourceLoader.load_threaded_get_status(path, progress):
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
            if progress.size() == 1:
                __SignalBus.on_load_scene_progress.emit(progress[0])
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
            var scene: PackedScene = ResourceLoader.load_threaded_get(path)
            match get_tree().change_scene_to_packed(scene):
                OK:
                    pass
                ERR_CANT_CREATE:
                    push_error("Cannot create new root scene '%s'" % path)
                    __SignalBus.on_fail_load.emit()
                    path = ""
                ERR_INVALID_PARAMETER:
                    push_error("Invalid parameter swapping root to packed scene '%s'" % path)
                    __SignalBus.on_fail_load.emit()
                    path = ""
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
            push_error("Loading scene '%s', thread failed" % path)
            __SignalBus.on_fail_load.emit()
            path = ""
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
            push_error("Loading scene '%s', failed due to invalid resource" % path)
            __SignalBus.on_fail_load.emit()
            path = ""
