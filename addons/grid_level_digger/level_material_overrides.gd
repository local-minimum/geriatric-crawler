@tool
extends Node
class_name LevelMaterialOverrides

@export var level: GridLevel
@export var _overrides: Array[MaterialOverride]

func _ready() -> void:
    for override: MaterialOverride in _overrides:
        override.apply(level.level_geometry)


func add_override(target_scene_file_path: String, surface_idx: int, material: Material, known_usage_path: String) -> void:
    var existing: int = _overrides.find_custom(func (override: MaterialOverride) -> bool: return override.target_scene_file_path == target_scene_file_path && override.surface_idx == surface_idx)
    if existing >= 0:
        _overrides[existing].override_material = material
        _overrides[existing].known_usage_path = known_usage_path
        _overrides[existing].apply(level.level_geometry)
        return

    var override: MaterialOverride = MaterialOverride.new()
    override.target_scene_file_path = target_scene_file_path
    override.surface_idx = surface_idx
    override.override_material = material
    override.known_usage_path = known_usage_path
    _overrides.append(override)

    override.apply(level.level_geometry)

func remove_override(target_scene_file_path: String, surface_idx: int) -> bool:
    var existing: int = _overrides.find_custom(func (override: MaterialOverride) -> bool: return override.target_scene_file_path == target_scene_file_path && override.surface_idx == surface_idx)
    if existing < 0:
        return false

    _overrides.remove_at(existing)
    return true


func has(target_scene_file_path: String, surface_idx: int) -> bool:
    for override: MaterialOverride in _overrides:
        if override.target_scene_file_path == target_scene_file_path && override.surface_idx == surface_idx:
            return true

    return false
