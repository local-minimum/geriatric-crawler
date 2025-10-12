extends Resource
class_name MaterialOverride

@export var override_material: Material
@export var target_scene_file_path: String
@export var surface_idx: int

@export var known_usage_path: String


func apply(root: Node) -> void:
    if target_scene_file_path.is_empty():
        push_error("We must have a target scene file path!")
        return

    if override_material == null:
        push_error("To override a material we must have a material")
        return

    if surface_idx < 0:
        push_error("MeshInstance3D surface index must not be a negative numbe")
        return

    var node = root.get_tree().root.get_node(known_usage_path)
    if node != null && node.scene_file_path == target_scene_file_path && node is MeshInstance3D:
        if _apply(node):
            return

    node = ResourceUtils.find_first_node_using_resource(root, target_scene_file_path)
    if node != null && node is MeshInstance3D:
        if _apply(node):
            return

    push_warning("Failed to apply %s to %s, no usaged found under %s" % [
        override_material,
        target_scene_file_path,
        root,
    ])


func _apply(m_instance: MeshInstance3D) -> bool:
    if surface_idx >= m_instance.get_surface_override_material_count():
        push_error("%s only has %s surfaces, asking to apply %s doesn't work" % [
            m_instance,
            m_instance.get_surface_override_material_count(),
            surface_idx,
        ])
        return false

    m_instance.mesh.surface_set_material(surface_idx, override_material)
    return true
