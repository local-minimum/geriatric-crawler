@tool
extends VBoxContainer
class_name GridLevelManipulator

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

func sync() -> void:
    var node: GridNode = panel.get_grid_node()


    if panel.inside_level:
        var coords: Vector3i = panel.coordinates
        var coords_have_node: bool = panel.get_grid_node_at(coords) != null

        if coords_have_node:
            node_type_label.text = "Node"

            sync_position_btn.visible = true
            infer_coordinates_btn.visible = true
        else:
            node_type_label.text = "[EMPTY]"

            sync_position_btn.visible = false
            infer_coordinates_btn.visible = false

        coordinates_label.text = "%s" % coords
        coordinates_label.visible = true

    else:
        node_type_label.text = "[NOT IN LEVEL]"
        sync_position_btn.visible = false
        infer_coordinates_btn.visible = false
        coordinates_label.visible = false

func _on_sync_position_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)

        if new_position != node.global_position:
            panel.undo_redo.create_action("GridLevelDigger: Sync node position")

            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

            panel.undo_redo.commit_action()

func _on_infer_coordinates_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
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

            panel.undo_redo.add_do_property(node, "name",  "Node %s" % new_coordinates)
            panel.undo_redo.add_undo_property(node, "name", node.name)

            panel.undo_redo.commit_action()

            panel.coordinates = new_coordinates
