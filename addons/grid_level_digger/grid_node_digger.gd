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

    _sync_look_direction()

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
var _auto_dig: bool
var _coordinates_valid: bool
var _coordinates: Vector3i

func _on_auto_clear_walls_toggled(toggled_on:bool) -> void:
    _auto_clear_walls = toggled_on


func _on_auto_dig_toggled(toggled_on:bool) -> void:
    _auto_dig = toggled_on

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
    _sync_look_direction()

func _on_turn_left_pressed() -> void:
    _look_direction = CardinalDirections.yaw_ccw(_look_direction, CardinalDirections.CardinalDirection.DOWN)[0]
    _sync_look_direction()

func _sync_look_direction() -> void:
    # TODO: Show look direction
    pass

func _enact_translation(movement: Movement.MovementType) -> void:
    if !Movement.is_translation(movement): return
    var direction: CardinalDirections.CardinalDirection = Movement.to_direction(movement, _look_direction, CardinalDirections.CardinalDirection.DOWN)
    _coordinates = CardinalDirections.translate(_coordinates, direction)
    sync(false)
    panel.draw_debug_node_meshes(_coordinates)
