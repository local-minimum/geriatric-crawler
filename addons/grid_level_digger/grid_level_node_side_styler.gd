@tool
extends Control
class_name GridLevelNodeSideStyler

@export var _side_info: Label
@export var _targets: MenuButton
@export var _materials_root: String = "res://"
@export var _materials_parent: Container
@export var _in_use_color: Color = Color.DEEP_PINK
@export var _override_not_in_use: Color = Color.REBECCA_PURPLE
@export var _default_color: Color = Color.DARK_KHAKI


var _side: GridNodeSide
var _panel: GridLevelDiggerPanel
var _key_lookup: Array[String]
var _used_materials: Dictionary[String, String]
var _material_options: Array[Material]
var _showing_mats: Array[MaterialSelectionListing]

func configure(side: GridNodeSide, panel: GridLevelDiggerPanel) -> void:
    _side = side
    _panel = panel

    _side_info.text = "%s / %s" % [side.name, CardinalDirections.name(side.direction)]

    _used_materials = GridNodeSide.get_used_materials(side)

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

    _material_options = gather_available_materials()

func _handle_change_target(id: int) -> void:
    var key: String = _key_lookup[id]
    print_debug("Inspecting %s with material %s" % [key, _used_materials[key]])

    for listing: MaterialSelectionListing in _showing_mats:
        listing.queue_free()
    _showing_mats.clear()

    var used_mat_path: String = _used_materials[key]
    var scene: PackedScene = load("res://addons/grid_level_digger/controls/material_listing.tscn")

    var list: MaterialSelectionListing = scene.instantiate()
    var used_mat: Material = load(used_mat_path)
    list.configure(used_mat, _in_use_color, null)
    _showing_mats.append(list)
    _materials_parent.add_child(list)

    for mat: Material in _material_options:
        if mat.resource_path == used_mat.resource_path:
            continue

        list = scene.instantiate()
        list.configure(mat, _default_color, null)
        _showing_mats.append(list)
        _materials_parent.add_child(list)

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
