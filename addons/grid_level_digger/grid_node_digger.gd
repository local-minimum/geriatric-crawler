@tool
extends VBoxContainer
class_name GridNodeDigger

@export
var panel: GridLevelDiggerPanel

@export
var coordinates_label: Label

@export
var sync_position_btn: Button

func sync() -> void:
    var node: GridNode = panel.get_grid_node()
    if node == null:
        sync_position_btn.disabled = true
        coordinates_label.text = "- None -"
    else:
        sync_position_btn.disabled = false
        coordinates_label.text = "(%s, %s, %s)" % [node.coordinates.x, node.coordinates.y, node.coordinates.z]

func _on_sync_position_pressed() -> void:
    var node: GridNode = panel.get_grid_node()
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)

        panel.undo_redo.create_action("GridLevelDigger: Sync node position")

        panel.undo_redo.add_do_property(node, "position", new_position)
        panel.undo_redo.add_undo_property(node, "position", node.position)

        panel.undo_redo.commit_action()


func _on_infer_coordinates_pressed() -> void:
    var node: GridNode = panel.get_grid_node()
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
        sync()
