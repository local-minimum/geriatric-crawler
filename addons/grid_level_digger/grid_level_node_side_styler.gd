@tool
extends Control
class_name GridLevelNodeSideStyler

@export var _side_info: Label
@export var _highlight_checkbox: CheckBox
@export var _targets: MenuButton
@export var _materials_root: String = "res://"
@export var _materials_parent: Container
@export var _in_use_color: Color = Color.DEEP_PINK
@export var _override_not_in_use: Color = Color.REBECCA_PURPLE
@export var _default_color: Color = Color.DARK_KHAKI
@export var _highlight_meshes_color: Color = Color.DEEP_PINK


var _side: GridNodeSide
var _panel: GridLevelDiggerPanel
var _key_lookup: Array[String]
var _used_materials: Dictionary[String, String]
var _material_options: Array[Material]
var _showing_mats: Array[MaterialSelectionListing]
var _highlights: Array[MeshInstance3D]

func _exit_tree() -> void:
    _clear_highlights()

func configure(side: GridNodeSide, panel: GridLevelDiggerPanel) -> void:
    _side = side
    _panel = panel

    _side_info.text = "%s / %s" % [side.name, CardinalDirections.name(side.direction)]

    _highlight_checkbox.button_pressed = panel.preview_style_targets

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

    if popup.item_count > 0:
        _handle_change_target(0)

    if _highlight_checkbox.button_pressed:
        _sync_highlights(true)

    print_debug("[GLD Styler] Configured!")

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

var _key: String
var used_mat: Material

func _handle_change_target(id: int) -> void:
    _key = _key_lookup[id]
    _targets.text = _humanize_key(_key)

    print_debug("Inspecting %s with material %s" % [_key, _used_materials[_key]])

    for listing: MaterialSelectionListing in _showing_mats:
        listing.queue_free()
    _showing_mats.clear()

    var used_mat_path: String = _used_materials[_key]
    var scene: PackedScene = load("res://addons/grid_level_digger/controls/material_listing.tscn")

    var list: MaterialSelectionListing = scene.instantiate()
    used_mat = load(used_mat_path)
    list.configure(used_mat, _in_use_color, null)
    _showing_mats.append(list)
    _materials_parent.add_child(list)

    for mat: Material in _material_options:
        if mat.resource_path == used_mat.resource_path:
            continue

        list = scene.instantiate()
        _configure_listing(list, mat, true)
        _showing_mats.append(list)
        _materials_parent.add_child(list)

func _listing_color(mat_displayed: bool, has_override: bool) -> Color:
    if mat_displayed:
        return _in_use_color
    if has_override:
        return _override_not_in_use
    return _default_color

func _configure_listing(list: MaterialSelectionListing, mat: Material, allow_use: bool) -> void:
    var on_use: Variant = null
    var target: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(_side, _key)
    var surface_idx: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(_side, _key)

    var override: MaterialOverride = _panel.material_overrides.get_override(target.scene_file_path, surface_idx) if _panel.material_overrides != null else null
    if allow_use:
        on_use = func() -> void:
            _panel.undo_redo.create_action("GridLevelDigger: Swap side material %s" % _humanize_key(_key))

            _panel.undo_redo.add_do_method(self, "_do_set_override", _side, _key, mat)
            if override != null:
                _panel.undo_redo.add_undo_method(self, "_do_set_override", _side, _key, used_mat)
            else:
                _panel.undo_redo.add_undo_method(self, "_do_erase_override", _side, _key, used_mat)

            _panel.undo_redo.commit_action()

    list.configure(
        mat,
        _listing_color(mat == target.get_surface_override_material(surface_idx), override != null && override.override_material == mat),
        on_use,
    )

func _update_listing() -> void:
    var target: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(_side, _key)
    var surface_idx: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(_side, _key)
    var override: MaterialOverride = _panel.material_overrides.get_override(target.scene_file_path, surface_idx) if _panel.material_overrides != null else null

    for list: MaterialSelectionListing in _showing_mats:
        var on_use: Variant = null
        if list.mat != used_mat:
            on_use = func() -> void:
                _panel.undo_redo.create_action("GridLevelDigger: Swap side material %s" % _humanize_key(_key))

                _panel.undo_redo.add_do_method(self, "_do_set_override", _side, _key, list.mat)
                if override != null:
                    _panel.undo_redo.add_undo_method(self, "_do_set_override", _side, _key, used_mat)
                else:
                    _panel.undo_redo.add_undo_method(self, "_do_erase_override", _side, _key, used_mat)

                _panel.undo_redo.commit_action()


        list.update(
            _listing_color(list.mat == used_mat, override != null && override.override_material == list.mat),
            on_use
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

func _do_set_override(side: GridNodeSide, key: String, material: Material) -> void:
    var target: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(side, key)
    var surface_idx: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(side, key)

    if target == null || surface_idx < 0 || surface_idx >= target.get_surface_override_material_count():
        push_error("Invalid override target=%s, surface index=%s (valid 0-%s)" % [target, surface_idx, 0 if target == null else target.get_surface_override_material_count()])
        return

    if _panel.material_overrides == null:
        var level: GridLevel = _panel.level
        if level == null:
            push_error("We cannot set an override without having a level")
            return

        var overrides = LevelMaterialOverrides.new()
        overrides.name = "Material Overrides"
        overrides.level = level
        level.add_child(overrides)
        overrides.owner = level.get_tree().edited_scene_root
        _panel.material_overrides = overrides

    if _panel.material_overrides.add_override(
        target,
        surface_idx,
        material,
    ):
        used_mat = material
        _used_materials[key] = material.resource_path

        _update_listing()

        EditorInterface.mark_scene_as_unsaved()


func _do_erase_override(side: GridNodeSide, key: String, default: Material) -> void:
    if _panel.material_overrides == null:
        push_error("There are no overrides to this level")
        return

    var target: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(side, key)
    var surface_idx: int = GridNodeSide.get_meshinstance_surface_index_from_override_path(side, key)

    if target == null || surface_idx < 0 || surface_idx >= target.get_surface_override_material_count():
        push_error("Invalid override target=%s, surface index=%s (valid 0-%s)" % [target, surface_idx, 0 if target == null else target.get_surface_override_material_count()])
        return

    if _panel.material_overrides.remove_override(target.scene_file_path, surface_idx):
        EditorInterface.mark_scene_as_unsaved()

    GridNodeSide.revert_material_overrride(side, key, default)
    used_mat = default
    _used_materials[key] = default.resource_path

    _update_listing()

static func _is_allowed_material(path: String) -> bool:
    var resource: Resource = load(path)
    return resource is StandardMaterial3D or resource is ShaderMaterial or resource is ORMMaterial3D

# Look into make unique button to clone the GridNodeSide resource

func _on_highlight_pressed() -> void:
    _on_highlight_toggled(_highlight_checkbox.button_pressed)

func _on_highlight_toggled(toggled_on:bool) -> void:
    _panel.preview_style_targets = toggled_on
    _sync_highlights(toggled_on)
    print_debug("[GLD Styler] Should show hightlight %s" % toggled_on)


func _clear_highlights() -> void:
    for m_instance: MeshInstance3D in _highlights:
        m_instance.queue_free()
    _highlights.clear()

func _sync_highlights(shown: bool) -> void:
    _clear_highlights()

    if !shown:
        print_debug("[GLD Styler] Not showing highlights")
        return

    var target: MeshInstance3D = GridNodeSide.get_meshinstance_from_override_path(_side, _key)
    if target == null:
        push_error("[GLD Styler] Have a target, side %s with key %s lacks this!" % [_side, _key])
        return

    var parentage: Array[Array] = ResourceUtils.list_resource_parentage(target)
    if parentage.is_empty():
        push_error("[GLD Styler] Have a parent that is a scene, %s lacks this!" % target)
        return

    var target_scene_file_path: String = parentage[0][1]

    for node: Node in ResourceUtils.find_all_nodes_using_resource(_panel.level.level_geometry, target_scene_file_path):
        if node is Node3D:
            var bounds: AABB = AABBUtils.bounding_box(node).grow(0.1)

            var box: MeshInstance3D = DebugDraw.box(
                _panel.level,
                bounds.get_center(),
                bounds.size,
                _highlight_meshes_color,
                false,
            )

            _highlights.append(box)


    print_debug("[GLD Styler] showing %s highlights using resource '%s'" % [_highlights.size(), target_scene_file_path])
