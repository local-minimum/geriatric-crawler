@tool
extends VBoxContainer
class_name GridLevelActions

@export
var panel: GridLevelDiggerPanel

@export
var style: GridLevelStyle

@export
var info: Label

@export
var origin_tile_btn: Button



func _on_align_all_nodes_pressed() -> void:
    panel.undo_redo.create_action("GridLevelAction: Sync all node positions")

    for node: GridNode in panel.all_level_nodes:
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(panel.level, node.coordinates)

        if node.global_position != new_position:
            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

    panel.undo_redo.commit_action()

func _on_set_all_wall_rotations_pressed() -> void:
    for node: GridNode in panel.all_level_nodes:
        for node_side: GridNodeSide in node.find_children("", "GridNodeSide"):
            GridNodeSide.set_direction_from_rotation(node_side)

    panel.sync_ui()

func _on_refresh_level_nodes_pressed() -> void:
    panel.refresh_level_nodes()

func sync_ui():
    info.text = "Level: %s nodes" % panel.all_level_nodes.size()
    var has_origion_node: bool = panel.get_grid_node_at(Vector3i.ZERO) != null
    origin_tile_btn.disabled = has_origion_node || !style.has_grid_node_resource_selected()
    if origin_tile_btn.disabled:
        origin_tile_btn.tooltip_text = "There's already a node at (0, 0, 0)" if has_origion_node else "First select a node scene to instantiate"
    else:
        origin_tile_btn.tooltip_text = "Puts a node at (0, 0, 0)"


func _on_place_origin_tile_pressed() -> void:

    sync_ui()
