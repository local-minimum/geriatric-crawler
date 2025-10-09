@tool
extends VBoxContainer
class_name GridNodeDigger

@export var panel: GridLevelDiggerPanel

@export var nav: GridLevelNav

@export var style: GridLevelStyle

@export var level_actions: GridLevelActions

@export var auto_digg_btn: CheckButton
@export var auto_clear_sides: CheckButton
@export var auto_add_sides: CheckButton
@export var preserve_vertical_btn: CheckButton

@export var cam_offset_x: SpinBox
@export var cam_offset_y: SpinBox
@export var cam_offset_z: SpinBox
@export var place_node_btn: Button

func _ready() -> void:
    if auto_clear_sides != null:
        auto_clear_sides.button_pressed = true
    if auto_add_sides != null:
        auto_add_sides.button_pressed = true

    style.on_style_updated.connect(_sync_features)

    if nav.on_update_nav.connect(_handle_update_nav) != OK:
        push_error("Failed to connect update nav")

func _handle_update_nav(_coordinates: Vector3i, _look_direction: CardinalDirections.CardinalDirection) -> void:
    sync()

func _sync_features() -> void:
    auto_digg_btn.disabled = !style.has_grid_node_resource_selected()
    _auto_dig = !auto_digg_btn.disabled && auto_digg_btn.button_pressed

    auto_add_sides.disabled = auto_digg_btn.disabled || !style.has_any_side_resource_selected()
    _auto_add_sides = !auto_add_sides.disabled && auto_add_sides.toggle_mode

    auto_clear_sides.disabled = auto_digg_btn.disabled
    preserve_vertical_btn.disabled = auto_digg_btn.disabled

    var has_origion_node: bool = panel.get_focus_node() != null
    place_node_btn.disabled = has_origion_node || !style.has_grid_node_resource_selected()
    if has_origion_node:
        place_node_btn.tooltip_text = "There's already a node at %s" % panel.coordinates
    elif place_node_btn.disabled:
        place_node_btn.tooltip_text = "Style doesn't have a node selected"
    else:
        place_node_btn.tooltip_text = "Put a node at %s" % panel.coordinates

func sync() -> void:
    var node: GridNode = panel.get_grid_node()

    if !_cam_offset_synced:
        _cam_offset_syncing = true
        cam_offset_x.value = _cam_offset.x
        cam_offset_y.value = _cam_offset.y
        cam_offset_z.value = _cam_offset.z
        _cam_offset_syncing = false
        _cam_offset_synced = true

    _sync_features()

var _auto_clear_walls: bool = true
var _preserve_vertical: bool = true
var _auto_add_sides: bool = true
var _auto_dig: bool
var _follow_cam: bool
var _cam_offset_synced: bool
var _cam_offset_syncing: bool
var _cam_offset: Vector3 = Vector3(0, 0.5, 0)

func _on_auto_dig_toggled(toggled_on:bool) -> void:
    print_debug("Auto-diggs %s" % toggled_on)
    _auto_dig = toggled_on

func _on_auto_clear_toggled(toggled_on:bool) -> void:
    _auto_clear_walls = toggled_on

func _on_auto_wall_toggled(toggled_on:bool) -> void:
    print_debug("Auto-add walls %s" % toggled_on)
    _auto_add_sides = toggled_on

func _on_follow_cam_toggled(toggled_on:bool) -> void:
    _follow_cam = toggled_on

func _on_preserve_vertical_toggled(toggled_on:bool) -> void:
    _preserve_vertical = toggled_on

func _on_cam_offset_z_value_changed(value:float) -> void:
    if _cam_offset_syncing: return
    _cam_offset.z = value
    _sync_viewport_camera()

func _on_cam_offset_y_value_changed(value:float) -> void:
    if _cam_offset_syncing: return
    _cam_offset.y = value
    _sync_viewport_camera()

func _on_cam_offset_x_value_changed(value:float) -> void:
    if _cam_offset_syncing: return
    _cam_offset.x = value
    _sync_viewport_camera()

func _perform_auto_dig(dig_direction: CardinalDirections.CardinalDirection, ignore_auto_dig: bool = false) -> void:
    if !(_auto_dig || ignore_auto_dig) || panel.level == null:
        if !_auto_dig:
            print_debug("Not digging @ %s" % panel.coordinates)
        if panel.level == null:
            print_debug("No level")
        return

    var level: GridLevel = panel.level
    var target_node = panel.get_focus_node()
    var may_wall: bool = true
    var node_resource: Resource = style.get_node_resource()

    if target_node == null && node_resource == null:
        print_debug("Will not auto-dig at %s because no dig-node selected" % panel.coordinates)
        may_wall = false

    elif target_node == null:
        panel.undo_redo.create_action("GridLevelDigger: Auto-dig node @ %s" % panel.coordinates)

        panel.undo_redo.add_do_method(self, "_do_auto_dig_node", level, node_resource, panel.coordinates)
        panel.undo_redo.add_undo_method(self, "_undo_auto_dig_node", panel.coordinates)

        panel.undo_redo.commit_action()

        target_node = panel.get_focus_node()

    for dir: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.coordinates, dir))

        var is_traversed = CardinalDirections.invert(dig_direction) == dir
        if (_auto_clear_walls || is_traversed) && neighbor != null && (!_preserve_vertical || CardinalDirections.is_planar_cardinal(dir) || is_traversed):
            remove_node_side(target_node, dir)
            remove_node_side(neighbor, CardinalDirections.invert(dir))

        if _auto_add_sides && may_wall:
            var side_resource: Resource = style.get_resource_from_direction(dir)
            if neighbor == null:
                add_node_side(side_resource, level, target_node, dir, _preserve_vertical)
            elif _preserve_vertical && !CardinalDirections.is_planar_cardinal(dir):
                add_node_side(side_resource, level, target_node, dir, _preserve_vertical)

func swap_node_side_for_style(
    node: GridNode,
    side_direction: CardinalDirections.CardinalDirection
) -> bool:
    if node == null:
        return false

    var side = GridNodeSide.get_node_side(node, side_direction)
    var new_style: String = style.get_resource_path_from_direction(side_direction)

    if side == null || side.scene_file_path == new_style || !TextUtils.is_resource_path(new_style):
        return false

    panel.undo_redo.create_action("GridLevelDigger: Swap side model %s @ %s %s" % [side.name, node.coordinates, CardinalDirections.name(side_direction)])

    panel.undo_redo.add_do_method(self, "_do_swap_node_side", node, side_direction, style.get_resource_path_from_direction(side_direction))
    panel.undo_redo.add_undo_method(self, "_do_swap_node_side", node, side_direction, side.scene_file_path)

    panel.undo_redo.commit_action()

    return true

func remove_node_side(
    node: GridNode,
    side_direction: CardinalDirections.CardinalDirection,
) -> bool:
    if node == null:
        return false

    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
        panel.undo_redo.create_action("GridLevelDigger: Remove %s @ %s %s" % [side.name, node.coordinates, CardinalDirections.name(side_direction)])

        panel.undo_redo.add_do_method(self, "_do_remove_node_side", side)
        panel.undo_redo.add_undo_method(self, "_do_readd_node_side", node, side_direction, side.scene_file_path)

        panel.undo_redo.commit_action()
        return true
    return false

func _do_swap_node_side(node: GridNode, side_direction: CardinalDirections.CardinalDirection, new_side: String) -> void:
    if !TextUtils.is_resource_path(new_side):
        return

    var resource: Resource = load(new_side)
    if resource == null:
        return

    var old_side: GridNodeSide = GridNodeSide.get_node_side(node, side_direction)
    print_debug("[GLD] Removing %s of origin %s from %s" % [old_side.name, old_side.scene_file_path, node.coordinates])
    # Cannot queue free because then won't add side
    old_side.free()

    print_debug("[GLD] Adding %s to %s" % [resource.resource_path, node.coordinates])
    _do_add_node_side(
        resource,
        panel.level,
        node,
        side_direction,
        true,
    )

func _do_remove_node_side(side: GridNodeSide) -> void:
    side.queue_free()
    EditorInterface.mark_scene_as_unsaved()

func _do_readd_node_side(node: GridNode, direction: CardinalDirections.CardinalDirection, resource_path: String) -> void:
    var resource: Resource = load(resource_path)
    if resource == null:
        resource = style.get_resource_from_direction(direction)

    _do_add_node_side(resource, panel.level, node, direction, true)

func add_node_side(
    resource: Resource,
    level: GridLevel,
    node: GridNode,
    side_direction: CardinalDirections.CardinalDirection,
    treat_elevation_as_separate: bool,
) -> void:
    panel.undo_redo.create_action("GridLevelDigger: Add side %s @ %s" % [CardinalDirections.name(side_direction), node.coordinates])

    panel.undo_redo.add_do_method(self, "_do_add_node_side", resource, level, node, side_direction, treat_elevation_as_separate)
    panel.undo_redo.add_undo_method(self, "_do_remove_side_from_node", node, side_direction)

    panel.undo_redo.commit_action()

func _do_remove_side_from_node(node: GridNode, side_direction: CardinalDirections.CardinalDirection) -> void:
    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
        _do_remove_node_side(side)

func _do_add_node_side(
    resource: Resource,
    level: GridLevel,
    node: GridNode,
    side_direction: CardinalDirections.CardinalDirection,
    treat_elevation_as_separate: bool,
) -> void:
    if node == null || resource == null:
        print_debug("[GLD] Refused wall because lacking resouces or node")
        return

    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
        print_debug("[GLD] Refused adding side because already exist %s" % [side.name])
        return

    var raw_node: Node = resource.instantiate()
    if raw_node is not GridNodeSide:
        push_error("Grid Node template is not a GridNode")
        raw_node.queue_free()
        return

    side = raw_node
    side.direction = side_direction

    side.name = "Side %s" % CardinalDirections.name(side_direction)

    node.add_child(side, true)

    side.position = Vector3.ZERO
    if CardinalDirections.is_planar_cardinal(side_direction):
        side.global_rotation = CardinalDirections.direction_to_planar_rotation(side_direction).get_euler()

    side.owner = level.get_tree().edited_scene_root

    if side.infer_direction_from_rotation:
        GridNodeSide.set_direction_from_rotation(side)

    EditorInterface.mark_scene_as_unsaved()

func _do_auto_dig_node(level: GridLevel, grid_node_resource: Resource, coordinates: Vector3i) -> void:
    var raw_node: Node = grid_node_resource.instantiate()
    if raw_node is not GridNode:
        push_error("Grid Node template is not a GridNode")
        raw_node.queue_free()
        return

    var node: GridNode = raw_node

    node.coordinates = coordinates
    node.name = "Node %s" % coordinates

    var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)
    var node_parent: Node3D = (
        GridLevelActions.get_or_add_elevation_parent(level, node.coordinates.y)
        if level_actions.organize_by_elevation else
        GridLevel.get_level_geometry_root(level)
    )

    panel.add_grid_node(node)
    node_parent.add_child(node, true)

    node.global_position = new_position
    node.owner = level.get_tree().edited_scene_root

    EditorInterface.mark_scene_as_unsaved()

func _undo_auto_dig_node(coordinates: Vector3i) -> void:
    var node: GridNode = panel.get_grid_node_at(coordinates)
    if node == null:
        return

    panel.remove_grid_node(node)
    node.queue_free()

func _sync_viewport_camera() -> void:
    if _follow_cam:
        var position: Vector3 = GridLevel.node_position_from_coordinates(panel.level, panel.coordinates)
        var target: Vector3 = position + CardinalDirections.direction_to_vector(nav.look_direction)
        var cam_position: Vector3 = position + CardinalDirections.direction_to_planar_rotation(nav.look_direction) * _cam_offset

        # TODO: Figure out how to know which viewport to update
        var view: SubViewport = EditorInterface.get_editor_viewport_3d(0)

        var cam: Camera3D = view.get_camera_3d()
        cam.global_position = cam_position
        cam.look_at(target)

func _on_place_node_pressed() -> void:
    _perform_auto_dig(CardinalDirections.CardinalDirection.NONE, true)
