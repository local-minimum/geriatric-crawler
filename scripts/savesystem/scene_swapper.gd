extends Node
class_name SceneSwapper

@export var scenes: Dictionary[String, String]
@export var fallback_scene_id: String = "hub-spaceship"

enum Phase { IDLE, LOADING_PACKED_SCENE, SWAPPING_ROOT, WAIT_TO_LOAD_NEW_SCENE, SWAPPING_COMPLETE }

var _phase: Phase = Phase.IDLE
var _loading_scene_id: String
var _loading_resource_path: String

func _process(_delta: float) -> void:
    match _phase:
        Phase.LOADING_PACKED_SCENE:
            _check_loading_next_scene()
        Phase.SWAPPING_COMPLETE:
            __SignalBus.on_scene_transition_complete.emit(_loading_scene_id)
            _reset_phase()

func transition_to_next_scene() -> bool:
    if _phase != Phase.IDLE:
        return false

    _loading_scene_id = ""
    if SaveSystem.instance != null:
        _loading_scene_id = SaveSystem.instance.get_next_scene_id()

    if _loading_scene_id.is_empty():
        _loading_scene_id = fallback_scene_id

    __SignalBus.on_scene_transition_initiate.emit(_loading_scene_id)

    if !scenes.has(_loading_scene_id):
        push_error("Failed to initiate root swapping to scene id '%s', not known" % _loading_scene_id)
        _handle_fail_and_reset()
        return false

    _loading_resource_path = scenes[_loading_scene_id]
    if ResourceLoader.load_threaded_request(scenes[_loading_scene_id], "PackedScene") != OK:
        push_error("Failed to initiate root swapping to '%s'" % _loading_resource_path)
        _handle_fail_and_reset()
        return false

    _phase = Phase.LOADING_PACKED_SCENE
    return true

func _check_loading_next_scene() -> void:
    var progress: Array = []

    match ResourceLoader.load_threaded_get_status(_loading_resource_path, progress):
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
            if progress.size() == 1:
                __SignalBus.on_scene_transition_progress.emit(progress[0])
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
            var scene: PackedScene = ResourceLoader.load_threaded_get(_loading_resource_path)
            _phase = Phase.SWAPPING_ROOT
            match get_tree().change_scene_to_packed(scene):
                OK:
                    _phase = Phase.WAIT_TO_LOAD_NEW_SCENE
                ERR_CANT_CREATE:
                    push_error("Cannot create new root scene '%s'" % _loading_resource_path)
                    _handle_fail_and_reset()
                ERR_INVALID_PARAMETER:
                    push_error("Invalid parameter swapping root to packed scene '%s'" % _loading_resource_path)
                    _handle_fail_and_reset()

        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
            push_error("Loading scene '%s', thread failed" % _loading_resource_path)
            _handle_fail_and_reset()
        ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
            push_error("Loading scene '%s', failed due to invalid resource" % _loading_resource_path)
            _handle_fail_and_reset()

func _handle_fail_and_reset() -> void:
    __SignalBus.on_scene_transition_fail.emit(_loading_scene_id)
    _reset_phase()

func _reset_phase() -> void:
    _loading_resource_path = ""
    _loading_scene_id = ""
    _phase = Phase.IDLE
