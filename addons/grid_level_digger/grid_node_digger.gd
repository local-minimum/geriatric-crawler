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
var cam_offset_x: SpinBox

@export
var cam_offset_y: SpinBox

@export
var cam_offset_z: SpinBox

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

        panel.undo_redo.create_action("GridLevelDigger: Sync node position")

        panel.undo_redo.add_do_property(node, "position", new_position)
        panel.undo_redo.add_undo_property(node, "position", node.position)

        panel.undo_redo.commit_action()


func _on_infer_coordinates_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(_coordinates)
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_coordinates: Vector3i = GridLevel.node_coordinates_from_position(level, node)
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, new_coordinates)

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

func _on_auto_clear_walls_toggled(toggled_on:bool) -> void:
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
    if !Movement.is_translation(movement) || panel._level == null: return

    var direction: CardinalDirections.CardinalDirection = Movement.to_direction(movement, _look_direction, CardinalDirections.CardinalDirection.DOWN)

    _coordinates = CardinalDirections.translate(_coordinates, direction)

    _sync_viewport_camera()
    _draw_debug_arrow()

    sync(false)
    panel.draw_debug_node_meshes(_coordinates)

func _sync_viewport_camera() -> void:
    if _follow_cam:
        # TODO: Rotate offset
        var position = GridLevel.node_position_from_coordinates(panel._level, _coordinates)
        var target = position + CardinalDirections.direction_to_look_vector(_look_direction)
        var cam_position: Vector3 = position + CardinalDirections.direction_to_planar_rotation(_look_direction) * _cam_offset
        for view_idx: int in [0] as Array[int]:
            var view: SubViewport = EditorInterface.get_editor_viewport_3d(view_idx)

            var cam: Camera3D = view.get_camera_3d()
            cam.global_position = cam_position
            cam.look_at(target)

func _draw_debug_arrow() -> void:
    _remove_debug_arrow()

    var center: Vector3 = GridLevel.node_center(panel._level, _coordinates)
    var target: Vector3 = center + CardinalDirections.direction_to_look_vector(_look_direction) * 0.75

    _debug_arrow_mesh = DebugDraw.arrow(
        panel._level,
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
