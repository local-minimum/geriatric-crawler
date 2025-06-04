@tool
extends VBoxContainer
class_name GridNodeDigger

@export
var panel: GridLevelDiggerPanel

@export
var node_type_label: Label

@export
var coordinates_label: Label

@export
var sync_position_btn: Button

@export
var infer_coordinates_btn: Button

@export
var auto_clear_sides: CheckButton

@export
var auto_add_sides: CheckButton

@export
var cam_offset_x: SpinBox

@export
var cam_offset_y: SpinBox

@export
var cam_offset_z: SpinBox

func _ready() -> void:
    if auto_clear_sides != null:
        auto_clear_sides.button_pressed = true
    if auto_add_sides != null:
        auto_add_sides.button_pressed = true

func sync(force_coordinates: bool) -> void:
    var node: GridNode = panel.get_grid_node()
    if node == null:
        if force_coordinates:
            _coordinates_valid = false
    else:
        sync_position_btn.disabled = false
        if force_coordinates:
            _coordinates = node.coordinates
            _coordinates_valid = true

    if _coordinates_valid:
        var coords_have_node: bool = panel.get_grid_node_at(_coordinates) != null
        if coords_have_node:
            sync_position_btn.visible = true
            infer_coordinates_btn.visible = true
            node_type_label.text = "Node"
        else:
            node_type_label.text = "[EMPTY]"
            sync_position_btn.visible = false
            infer_coordinates_btn.visible = false

        coordinates_label.text = "(%s, %s, %s)" % [_coordinates.x, _coordinates.y, _coordinates.z]
        coordinates_label.visible = true
    else:
        node_type_label.text = "Node editing not possible"
        sync_position_btn.visible = false
        infer_coordinates_btn.visible = false
        coordinates_label.visible = false

    _sync_look_direction(0)

    if !_cam_offset_synced:
        _cam_offset_syncing = true
        cam_offset_x.value = _cam_offset.x
        cam_offset_y.value = _cam_offset.y
        cam_offset_z.value = _cam_offset.z
        _cam_offset_syncing = false
        _cam_offset_synced = true

func _on_sync_position_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(_coordinates)
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)

        if new_position != node.global_position:
            panel.undo_redo.create_action("GridLevelDigger: Sync node position")

            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

            panel.undo_redo.commit_action()

func _on_infer_coordinates_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(_coordinates)
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_coordinates: Vector3i = GridLevel.node_coordinates_from_position(level, node)
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, new_coordinates)

        if new_coordinates != node.coordinates || new_position != node.global_position:

            panel.undo_redo.create_action("GridLevelDigger: Infer node coordinates")

            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

            panel.undo_redo.add_do_property(node, "coordinates", new_coordinates)
            panel.undo_redo.add_undo_property(node, "coordinates", node.coordinates)

            panel.undo_redo.commit_action()
            sync(true)


var _auto_clear_walls: bool
var _auto_add_walls: bool
var _auto_dig: bool
var _follow_cam: bool
var _cam_offset_synced: bool
var _cam_offset_syncing: bool
var _cam_offset: Vector3 = Vector3(0, 0.5, 0)

var _coordinates_valid: bool
var _coordinates: Vector3i

func _on_auto_dig_toggled(toggled_on:bool) -> void:
    _auto_dig = toggled_on

func _on_auto_clear_toggled(toggled_on:bool) -> void:
    _auto_clear_walls = toggled_on

func _on_auto_wall_toggled(toggled_on:bool) -> void:
    _auto_add_walls = toggled_on

func _on_follow_cam_toggled(toggled_on:bool) -> void:
    _follow_cam = toggled_on


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

var _look_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NORTH

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
    _look_direction = CardinalDirections.yaw_cw(_look_direction, CardinalDirections.CardinalDirection.DOWN)[0]
    _sync_look_direction(PI * 0.5)

func _on_turn_left_pressed() -> void:
    _look_direction = CardinalDirections.yaw_ccw(_look_direction, CardinalDirections.CardinalDirection.DOWN)[0]
    _sync_look_direction(-PI * 0.5)

var _debug_arrow_mesh: MeshInstance3D

func _sync_look_direction(rot: float) -> void:
    _draw_debug_arrow()
    _sync_viewport_camera()

func _enact_translation(movement: Movement.MovementType) -> void:
    if !Movement.is_translation(movement) || panel.level == null: return

    var direction: CardinalDirections.CardinalDirection = Movement.to_direction(movement, _look_direction, CardinalDirections.CardinalDirection.DOWN)

    var old_coordinates: Vector3i = _coordinates
    _coordinates = CardinalDirections.translate(_coordinates, direction)

    _sync_viewport_camera()
    _draw_debug_arrow()

    _perform_auto_dig(old_coordinates, direction)
    sync(false)
    panel.draw_debug_node_meshes(_coordinates)

func _perform_auto_dig(old_coordinates: Vector3i, dig_direction: CardinalDirections.CardinalDirection) -> void:
    if !_auto_dig || panel.level == null:
        return

    var level: GridLevel = panel.level
    var target_node = panel.get_grid_node_at(_coordinates)
    var may_wall: bool = true

    if target_node == null && (_grid_node_resource == null || !_grid_node_used):
        print_debug("Will not auto-dig at %s because no dig-node selected" % _coordinates)
        may_wall = false

    elif target_node == null:
        panel.undo_redo.create_action("GridLevelDigger: Auto-dig node @ %s" % _coordinates)

        panel.undo_redo.add_do_method(self, "_do_auto_dig_node", level, _grid_node_resource, _coordinates)
        panel.undo_redo.add_undo_method(self, "_undo_auto_dig_node", _coordinates)

        panel.undo_redo.commit_action()

        target_node = panel.get_grid_node_at(_coordinates)

    for dir: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(_coordinates, dir))
        if auto_clear_sides && neighbor != null:
            _remove_node_side(target_node, dir)
            _remove_node_side(neighbor, CardinalDirections.invert(dir))
        if auto_add_sides && may_wall:
            var side_resource: Resource = _get_resource_from_direction(dir)
            _add_node_side(side_resource, level, target_node, neighbor, dir)

func _get_resource_from_direction(dir: CardinalDirections.CardinalDirection) -> Resource:
    if CardinalDirections.is_planar_cardinal(dir):
        return _grid_wall_resource if _grid_wall_used else null
    elif dir == CardinalDirections.CardinalDirection.UP:
        return _grid_ceiling_resource if _grid_ceiling_used else null
    elif dir == CardinalDirections.CardinalDirection.DOWN:
        return _grid_floor_resource if _grid_floor_used else null
    return null

func _remove_node_side(node: GridNode, side_direction: CardinalDirections.CardinalDirection) -> void:
    if node == null:
        return

    var side = GridNodeSide.get_node_side(node, side_direction)
    if side != null:
        side.queue_free()
        EditorInterface.mark_scene_as_unsaved()

func _add_node_side(resource: Resource, level: GridLevel, node: GridNode, neighbour: GridNode, side_direction: CardinalDirections.CardinalDirection) -> void:
    if node == null || neighbour != null || resource == null:
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
    var node_parent = level.level_geometry
    if node_parent == null:
        node_parent = level

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
        var position = GridLevel.node_position_from_coordinates(panel.level, _coordinates)
        var target = position + CardinalDirections.direction_to_look_vector(_look_direction)
        var cam_position: Vector3 = position + CardinalDirections.direction_to_planar_rotation(_look_direction) * _cam_offset

        # TODO: Figure out how to know which viewport to update
        var view: SubViewport = EditorInterface.get_editor_viewport_3d(0)

        var cam: Camera3D = view.get_camera_3d()
        cam.global_position = cam_position
        cam.look_at(target)

func _draw_debug_arrow() -> void:
    _remove_debug_arrow()

    var center: Vector3 = GridLevel.node_center(panel.level, _coordinates)
    var target: Vector3 = center + CardinalDirections.direction_to_look_vector(_look_direction) * 0.75

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


var _forcing_resource_change: bool

@export
var grid_node_picker: ValidatingEditorNodePicker
var _grid_node_resource: Resource
var _grid_node_used: bool = true

func _on_grid_node_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_node_resource = null
        return

    if !grid_node_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_node_picker.edited_resource = null
        _grid_node_resource = null
        push_warning("%s is not a %s" % [resource, grid_node_picker.root_class_name])
        _forcing_resource_change = false

    _grid_node_resource = resource

@export
var grid_ceiling_picker: ValidatingEditorNodePicker
var _grid_ceiling_resource: Resource
var _grid_ceiling_used: bool = true

func _on_grid_ceiling_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_ceiling_resource = null
        return

    if !grid_ceiling_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_ceiling_picker.edited_resource = null
        _grid_ceiling_resource = null
        push_warning("%s is not a %s" % [resource, grid_ceiling_picker.root_class_name])
        _forcing_resource_change = false

    _grid_ceiling_resource = resource

@export
var grid_floor_picker: ValidatingEditorNodePicker
var _grid_floor_resource: Resource
var _grid_floor_used: bool = true

func _on_grid_floor_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_floor_resource = null
        return

    if !grid_floor_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_floor_picker.edited_resource = null
        _grid_floor_resource = null
        push_warning("%s is not a %s" % [resource, grid_floor_picker.root_class_name])
        _forcing_resource_change = false

    _grid_floor_resource = resource

@export
var grid_wall_picker: ValidatingEditorNodePicker
var _grid_wall_resource: Resource
var _grid_wall_used: bool = true

func _on_grid_wall_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_wall_resource = null
        return

    if !grid_wall_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_wall_picker.edited_resource = null
        _grid_wall_resource = null
        push_warning("%s is not a %s" % [resource, grid_wall_picker.root_class_name])
        _forcing_resource_change = false

    _grid_wall_resource = resource

func _on_grid_ceiling_used_toggled(toggled_on:bool) -> void:
    _grid_ceiling_used = toggled_on

func _on_grid_floor_used_toggled(toggled_on:bool) -> void:
    _grid_floor_used = toggled_on

func _on_grid_wall_used_toggled(toggled_on:bool) -> void:
    _grid_wall_used = toggled_on

func _on_grid_node_used_toggled(toggled_on:bool) -> void:
    _grid_node_used = toggled_on
