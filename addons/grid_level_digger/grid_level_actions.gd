@tool
extends VBoxContainer
class_name GridLevelActions

signal on_organize_nodes(by_elevation: bool)

@export
var panel: GridLevelDiggerPanel

@export
var style: GridLevelStyle

@export
var info: Label

@export
var organize_btn: Button

var organize_by_elevation: bool = true

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

func _on_organize_nodes_button_pressed() -> void:
    if panel.level == null:
        push_warning("No level selected")
        return
    organize_level()

func _on_organize_nodes_by_elevation_toggled(toggled_on:bool) -> void:
    organize_by_elevation = toggled_on
    organize_btn.disabled = !toggled_on
    on_organize_nodes.emit(organize_by_elevation)

const _ELEVATION_NODE_PATTERN: String = "[Ee]levation (?<elevation>-?\\d+)"
const _NEW_ELEVATION_NODE_NAME_PATTERN: String = "Elevation %s"

func organize_level() -> void:
    var geometry_root: Node3D = GridLevel.get_level_geometry_root(panel.level)
    var all_nodes: Array[GridNode] = panel.all_level_nodes
    var level_elevation_children: Dictionary[int, Node3D] = {}

    var pattern: RegEx = RegEx.new()
    pattern.compile(_ELEVATION_NODE_PATTERN)

    for child: Node in geometry_root.get_children():
        if child is not Node3D or child is GridNode:
            continue

        var result: RegExMatch = pattern.search(child.name)
        if not result:
            continue

        var elevation: int = int(result.get_string("elevation"))
        if level_elevation_children.has(elevation):
            push_warning("Duplicate elevation nodes %s and %s both act for elevation %s" % [level_elevation_children[elevation].name, child.name, elevation])
            continue

        level_elevation_children[elevation] = child as Node3D

    for node: GridNode in all_nodes:
        var node_elevation: int = node.coordinates.y
        if !level_elevation_children.has(node_elevation):
            var new_elevation_node: Node3D = Node3D.new()
            new_elevation_node.name = _NEW_ELEVATION_NODE_NAME_PATTERN % node_elevation

            geometry_root.add_child(new_elevation_node)
            new_elevation_node.owner = geometry_root.get_tree().edited_scene_root

            level_elevation_children[node_elevation] = new_elevation_node

        var elevation_node: Node3D = level_elevation_children[node_elevation]
        if node.get_parent() == elevation_node:
            continue

        node.reparent(elevation_node, true)

    var elevations: Array[int] = level_elevation_children.keys()
    elevations.sort()

    var child_idx: int = 0
    for elevation: int in elevations:
        var enode = level_elevation_children[elevation]
        geometry_root.move_child(enode, child_idx)
        child_idx += 1

    EditorInterface.mark_scene_as_unsaved()

static func get_or_add_elevation_parent(level: GridLevel, elevation: int) -> Node3D:
    var geometry_root: Node3D = GridLevel.get_level_geometry_root(level)

    var pattern: RegEx = RegEx.new()
    pattern.compile(_ELEVATION_NODE_PATTERN)

    for child: Node in geometry_root.get_children():
        if child is not Node3D or child is GridNode:
            continue

        var result: RegExMatch = pattern.search(child.name)
        if not result:
            continue

        var child_elevation: int = int(result.get_string("elevation"))

        if child_elevation == elevation:
            return child

    var new_elevation_node: Node3D = Node3D.new()
    new_elevation_node.name = _NEW_ELEVATION_NODE_NAME_PATTERN % elevation

    geometry_root.add_child(new_elevation_node)
    new_elevation_node.owner = geometry_root.get_tree().edited_scene_root

    EditorInterface.mark_scene_as_unsaved()

    return new_elevation_node
