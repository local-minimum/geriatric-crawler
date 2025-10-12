@tool
extends Resource
class_name MaterialOverride

@export var override_material: Material
@export var target_scene_file_path: String
@export var relative_path: String
@export var surface_idx: int

@export var known_usage_path: String


func apply(root: Node) -> void:
    if target_scene_file_path.is_empty():
        push_error("[Material Override] We must have a target scene file path!")
        return

    if override_material == null:
        push_error("[Material Override] To override a material we must have a material")
        return

    if surface_idx < 0:
        push_error("[Material Override] MeshInstance3D surface index must not be a negative numbe")
        return

    if !known_usage_path.is_empty():
        var node: Node = root.get_node(known_usage_path)
        if node != null && node.scene_file_path == target_scene_file_path:
            if _apply(node):
                print_debug("[Material Override] Applied %s to %s surface %s using known path" % [override_material, node, surface_idx])
                return

            else:
                print_debug("[Material Override] known path %s isn't valid target" % node)

        elif node == null:
            print_debug("[Material Override] known path is no longer present")

        else:
            push_warning("[Material Override] found candidate node %s but it has the wrong scen file path %s vs %s" % [
                node,
                node.scene_file_path,
                target_scene_file_path,
            ])

    var node: Node = ResourceUtils.find_first_node_using_resource(root, target_scene_file_path)
    if node != null && node is MeshInstance3D:
        if _apply(node):
            print_debug("[Material Override] Applied %s to %s surface %s" % [override_material, node, surface_idx])
            var new_target_path: String = root.get_path_to(node)
            known_usage_path = new_target_path
            return

    push_warning("[Material Override] Failed to apply %s to %s, no usaged found under %s" % [
        override_material,
        target_scene_file_path,
        root,
    ])


func _apply(node: Node) -> bool:
    var child: Node = node.get_node(relative_path)

    if child == null:
        push_error("[Material Override] %s doesn't have a child at path '%s'" % [node, relative_path])
        return false

    elif child is not MeshInstance3D:
        push_error("[Material Override] Target %s is not a MeshInstance3D" % child)
        return false

    var m_instance: MeshInstance3D = child
    if surface_idx >= m_instance.get_surface_override_material_count():
        push_error("[Material Override] %s only has %s surfaces, asking to apply %s doesn't work" % [
            m_instance,
            m_instance.get_surface_override_material_count(),
            surface_idx,
        ])
        return false

    m_instance.mesh.surface_set_material(surface_idx, override_material)
    return true
