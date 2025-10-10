@tool
extends Control
class_name GridLevelNodeSideStyler

@export var _side_info: Label
@export var _targets: MenuButton
@export var _materials_root: String = "res://"

var _key_lookup: Array[String]
var _used_materials: Dictionary[String, String]

func configure(side: GridNodeSide, panel: GridLevelDiggerPanel) -> void:
    _side_info.text = "%s / %s" % [side.name, CardinalDirections.name(side.direction)]

    _used_materials = GridNodeSide.get_used_materials(side).merged(side._material_overrides, true)

    var popup: PopupMenu = _targets.get_popup()
    popup.clear()
    _key_lookup.clear()

    for path: String in _used_materials:
        var m_instance: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(side, path)
        var idx: int = _key_lookup.size()
        _key_lookup.append(path)
        if m_instance == null:
            popup.add_radio_check_item("[Missing node: %s]" % path.split("|")[0])
        else:
            var surface: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(side, path)

            if surface < 0:
                popup.add_radio_check_item("[Invalid surface: %s of %s]" % [surface, m_instance.name])
            else:
                popup.add_radio_check_item("%s [Surface %s]" % [m_instance.name, surface])

    if popup.id_pressed.connect(_handle_change_target) != OK:
        push_error("Failed to connect id pressed")

    gather_available_materials()

func _handle_change_target(id: int) -> void:
    var key: String = _key_lookup[id]
    print_debug("Inspecting %s with material %s" % [key, _used_materials[key]])

func gather_available_materials() -> Array[Material]:
    var mats: Array[Material]
    for path: String in ResourceUtils.find_resources(
        _materials_root,
        ".tres,.material",
        _is_allowed_material
    ):
        var mat: Material = load(path)
        if mat != null:
            mats.push_back(mat)
            print_debug("Found material at '%s'" % mat.resource_path)

    return mats

static func _is_allowed_material(path: String) -> bool:
    var resource: Resource = load(path)
    return resource is StandardMaterial3D or resource is ShaderMaterial or resource is ORMMaterial3D
