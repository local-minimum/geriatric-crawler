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

    for key: String in _used_materials:
        var idx: int = _key_lookup.size()
        _key_lookup.append(key)
        popup.add_radio_check_item(_humanize_key(key))

    if popup.id_pressed.connect(_handle_change_target) != OK:
        push_error("Failed to connect id pressed")

    _material_options = gather_available_materials()

func _humanize_key(path: String) -> String:
    var m_instance: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(_side, path)
    if m_instance == null:
        return "[Missing node: %s]" % path.split("|")[0]
    else:
        var surface: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(_side, path)

        if surface < 0:
            return "[Invalid surface: %s of %s]" % [surface, m_instance.name]
        else:
            return "%s [Surface %s]" % [m_instance.name, surface]

    return path

func _handle_change_target(id: int) -> void:
    var key: String = _key_lookup[id]
    _targets.text = _humanize_key(key)

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
        _configure_listing(list, mat, key, used_mat, true)
        _showing_mats.append(list)
        _materials_parent.add_child(list)

func _configure_listing(list: MaterialSelectionListing, mat: Material, key: String, used_mat: Material, allow_use: bool) -> void:
    var on_use: Variant = null
    if allow_use:
        on_use = func() -> void:
            _panel.undo_redo.create_action("GridLevelDigger: Swap side material %s" % _humanize_key(key))

            _panel.undo_redo.add_do_method(self, "_do_set_override", _side, key, mat.resource_path)
            if _side._material_overrides.has(key):
                _panel.undo_redo.add_undo_method(self, "_do_set_override", _side, key, used_mat.resource_path)
            else:
                _panel.undo_redo.add_undo_method(self, "_do_erase_override", _side, key, used_mat)

            _panel.undo_redo.commit_action()

    list.configure(
        mat,
        _override_not_in_use if _side._material_overrides.get(key, "") == mat.resource_path else _default_color,
        on_use,
    )

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

func _do_set_override(side: GridNodeSide, key: String, path: String) -> void:
    side._material_overrides = side._material_overrides.merged({key: path}, true)
    GridNodeSide.apply_material_overrride(side, key)

    # TODO: Update listing to reflect new state
    EditorInterface.mark_scene_as_unsaved()

func _erase_override(side: GridNodeSide, key: String, default: Material) -> void:
    GridNodeSide.revert_material_overrride(side, key, default)

    # TODO: Update listing to reflect new state
    EditorInterface.mark_scene_as_unsaved()

static func _is_allowed_material(path: String) -> bool:
    var resource: Resource = load(path)
    return resource is StandardMaterial3D or resource is ShaderMaterial or resource is ORMMaterial3D

# Look into make unique button to clone the GridNodeSide resource
# How to store overriude state so that it is only one stored for all of shared material
