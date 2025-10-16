@tool
extends Node
class_name LevelMaterialOverrides

@export var level: GridLevel
@export var _overrides: Array[MaterialOverride]

func _ready() -> void:
    apply()

func apply() -> void:
    for override: MaterialOverride in _overrides:
        override.apply(level.level_geometry)


func add_override(target: MeshInstance3D, surface_idx: int, material: Material) -> bool:
    var parentage: Array[Array] = ResourceUtils.list_resource_parentage(target)
    if parentage.is_empty():
        push_error("[Level Material Overrides] we must have a target parent with scene file path, %s lacks this!" % target)
        return false

    var target_scene_file_path: String = parentage[0][1]
    var parent_full_path: String = parentage[0][0]
    var parent: Node = get_node(parent_full_path)
    if parent == null:
        push_error("[Level Material Overrides] Failed to locate parent %s" % parent_full_path)
        return false

    var parent_path: String = level.level_geometry.get_path_to(parent)
    var target_path: String = parent.get_path_to(target)

    if parent_path.is_empty() || target_path.is_empty():
        push_error("[Level Material Overrides] failed to get paths to parent '%s' and its target '%s'" % [parent_path, target])
        return false

    print_debug("[Level Material Overrides] trimmed target path '%s'" % [target_path])

    if target_scene_file_path.is_empty():
        push_error("[Level Material Overrides] we must have a target with scene file path, %s lacks this!" % target)
        return false

    var existing: int = _overrides.find_custom(
        func (override: MaterialOverride) -> bool:
            return (
                override.target_scene_file_path == target_scene_file_path &&
                override.relative_path == target_path &&
                override.surface_idx == surface_idx
            )
    )

    if existing >= 0:
        _overrides[existing].override_material = material
        _overrides[existing].known_usage_path = parent_path
        _overrides[existing].apply(level.level_geometry)
        return true

    var override: MaterialOverride = MaterialOverride.new()
    override.relative_path = target_path
    override.target_scene_file_path = target_scene_file_path
    override.surface_idx = surface_idx
    override.override_material = material
    override.known_usage_path = parent_path
    _overrides.append(override)

    override.apply(level.level_geometry)
    return true

func remove_override(target_scene_file_path: String, surface_idx: int) -> bool:
    var existing: int = _overrides.find_custom(func (override: MaterialOverride) -> bool: return override.target_scene_file_path == target_scene_file_path && override.surface_idx == surface_idx)
    if existing < 0:
        return false

    _overrides.remove_at(existing)
    return true

func get_override(target_scene_file_path: String, surface_idx: int) -> MaterialOverride:
    for override: MaterialOverride in _overrides:
        if override.target_scene_file_path == target_scene_file_path && override.surface_idx == surface_idx:
            return override

    return null
