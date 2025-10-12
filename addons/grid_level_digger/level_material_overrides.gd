@tool
extends Node
class_name LevelMaterialOverrides

@export var level: GridLevel
@export var _overrides: Array[MaterialOverride]

func _ready() -> void:
    for override: MaterialOverride in _overrides:
        override.apply(level.level_geometry)


func add_override(target: MeshInstance3D, surface_idx: int, material: Material) -> bool:
    var parentage: Array[Array] = ResourceUtils.list_resource_parentage(target)
    if parentage.is_empty():
        push_error("[Level Material Overrides] we must have a target parent with scene file path, %s lacks this!" % target)
        return false

    var target_scene_file_path: String = parentage[0][1]
    var parent_path: String = parentage[0][0]
    var target_path: String = target.get_path()
    if target_path.begins_with(parent_path):
        # print_debug("[Level Material Overrides] trimming target path '%s' with parent '%s'" % [target_path, parent_path])
        target_path = target_path.substr(parent_path.length())
    else:
        push_error("[Level Material Overrides] found scene-parent doesn't share path with target %s vs %s" % [parent_path, target_path])
        return false

    target_path = target_path.trim_prefix("/")

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
