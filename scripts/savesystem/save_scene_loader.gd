extends Node
class_name SaveSceneLoader

@warning_ignore_start("unused_parameter")
func load_root_scene_by_id(scene_id: String) -> bool:
    push_error("Calling base class for loading new root scene not intended")
    print_stack()
    return true
@warning_ignore_restore("unused_parameter")
