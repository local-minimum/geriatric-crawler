@tool
extends VBoxContainer
class_name GridNodeDigger

@export
var panel: GridLevelDiggerPanel

@export
var style: GridLevelStyle

@export
var level_actions: GridLevelActions

@export
var auto_digg_btn: CheckButton

@export
var auto_clear_sides: CheckButton

@export
var auto_add_sides: CheckButton

@export
var preserve_vertical_btn: CheckButton

@export
var cam_offset_x: SpinBox

@export
var cam_offset_y: SpinBox

@export
var cam_offset_z: SpinBox

@export
var place_node_btn: Button

func _ready() -> void:
    if auto_clear_sides != null:
        auto_clear_sides.button_pressed = true
    if auto_add_sides != null:
        auto_add_sides.button_pressed = true

    style.on_style_updated.connect(_sync_features)

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

    _sync_look_direction(0)

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

var look_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NORTH

func _on_down_pressed() -> void:
    _enact_translation(Movement.MovementType.ABS_DOWN)

func _on_strafe_right_pressed() -> void:
    _enact_translation(Movement.MovementType.STRAFE_RIGHT)

func _on_back_pressed() -> void:
    _enact_translation(Movement.MovementType.BACK)

func _on_strafe_left_pressed() -> void:
    _enact_translation(Movement.MovementType.STRAFE_LEFT)

func _on_up_pressed() -> void:
    _enact_translation(Movement.MovementType.ABS_UP)

func _on_forward_pressed() -> void:
    _enact_translation(Movement.MovementType.FORWARD)

func _on_turn_right_pressed() -> void:
    look_direction = CardinalDirections.yaw_cw(look_direction, CardinalDirections.CardinalDirection.DOWN)[0]
    _sync_look_direction(PI * 0.5)

func _on_turn_left_pressed() -> void:
    look_direction = CardinalDirections.yaw_ccw(look_direction, CardinalDirections.CardinalDirection.DOWN)[0]
    _sync_look_direction(-PI * 0.5)

var _debug_arrow_mesh: MeshInstance3D

func _sync_look_direction(rot: float) -> void:
    _draw_debug_arrow()
    _sync_viewport_camera()

func _enact_translation(movement: Movement.MovementType) -> void:
    if !Movement.is_translation(movement) || panel.level == null: return

    var direction: CardinalDirections.CardinalDirection = Movement.to_direction(movement, look_direction, CardinalDirections.CardinalDirection.DOWN)

    panel.coordinates = CardinalDirections.translate(panel.coordinates, direction)

    _sync_viewport_camera()
    _draw_debug_arrow()

    _perform_auto_dig(direction)
    sync()

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
            _remove_node_side(target_node, dir)
            _remove_node_side(neighbor, CardinalDirections.invert(dir))

        if _auto_add_sides && may_wall:
            var side_resource: Resource = style.get_resource_from_direction(dir)
            _add_node_side(side_resource, level, target_node, neighbor, dir, _preserve_vertical)

func _remove_node_side(node: GridNode, side_direction: CardinalDirections.CardinalDirection) -> void:
    if node == null:
        return

    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
        side.queue_free()
        EditorInterface.mark_scene_as_unsaved()

func _add_node_side(
    resource: Resource,
    level: GridLevel,
    node: GridNode,
    neighbour: GridNode,
    side_direction: CardinalDirections.CardinalDirection,
    treat_elevation_as_separate: bool,
) -> void:
    print_debug("%s %s %s with neighbour %s using %s" % [
        node.name,
        CardinalDirections.name(side_direction),
        "Elevation separate" if treat_elevation_as_separate else "Elevation included",
        neighbour,
        resource
    ])
    if node == null || resource == null:
        return

    if neighbour != null && (!treat_elevation_as_separate || CardinalDirections.is_planar_cardinal(side_direction)):
        return

    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
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
        var position = GridLevel.node_position_from_coordinates(panel.level, panel.coordinates)
        var target = position + CardinalDirections.direction_to_look_vector(look_direction)
        var cam_position: Vector3 = position + CardinalDirections.direction_to_planar_rotation(look_direction) * _cam_offset

        # TODO: Figure out how to know which viewport to update
        var view: SubViewport = EditorInterface.get_editor_viewport_3d(0)

        var cam: Camera3D = view.get_camera_3d()
        cam.global_position = cam_position
        cam.look_at(target)

func _draw_debug_arrow() -> void:
    _remove_debug_arrow()

    var center: Vector3 = GridLevel.node_center(panel.level, panel.coordinates)
    var target: Vector3 = center + CardinalDirections.direction_to_look_vector(look_direction) * 0.75

    _debug_arrow_mesh = DebugDraw.arrow(
        panel.level,
        center,
        target,
        Color.MAGENTA,
    )

func remove_debug_nodes() -> void:
    _remove_debug_arrow()

func _remove_debug_arrow() -> void:
    if _debug_arrow_mesh != null:
        _debug_arrow_mesh.queue_free()
        _debug_arrow_mesh = null

func _on_place_node_pressed() -> void:
    _perform_auto_dig(CardinalDirections.CardinalDirection.NONE, true)
