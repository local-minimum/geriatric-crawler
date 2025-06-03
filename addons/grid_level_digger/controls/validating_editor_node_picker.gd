@tool
extends EditorResourcePicker
class_name ValidatingEditorNodePicker

@export
var root_class_name: String = "GridNode"

func _ready() -> void:
    base_type = "PackedScene"
    toggle_mode = true

func is_valid(resource: Resource) -> bool:
    if resource is PackedScene:
        var scene: PackedScene = resource
        var scene_state: SceneState = scene.get_state()
        if scene_state.get_node_count() == 0:
            return false
        var root_script_raw: Variant = scene_state.get_node_property_value(0, 0)
        if root_script_raw is Script:
            return root_script_raw.get_global_name() == root_class_name
    return false
