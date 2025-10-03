@tool
extends EditorPlugin
class_name GridLevelDigger

@export
var panel: GridLevelDiggerPanel
const TOOL_PANEL: Resource = preload("res://addons/grid_level_digger/grid_level_digger_panel.tscn")

var editor_selection: EditorSelection

func _enter_tree() -> void:
    panel = TOOL_PANEL.instantiate()
    panel.undo_redo = get_undo_redo()

    add_control_to_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, panel)

    editor_selection = get_editor_interface().get_selection()
    editor_selection.connect("selection_changed", _on_selection_change)

    # Get the proper initial state
    _on_selection_change()

func _exit_tree() -> void:
    remove_control_from_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, panel)

    editor_selection.disconnect("selection_changed", _on_selection_change)

    panel.remove_debug_nodes()
    panel.queue_free()

func _grid_node_from_selected(selected: Node) -> GridNode:
    if selected is GridNode:
        return selected

    if selected is GridNodeFeature || selected is GridNodeSide:
        return GridNode.find_node_parent(selected, false)

    print_debug("[Grid Level Digger] '%s' (%s) is not a node or part of one" % [selected.name, selected])
    return null

func _on_selection_change() -> void:
    var selections: Array[Node] = editor_selection.get_selected_nodes()
    var selected_nodes: Array[GridNode] = []

    for selected: Node in selections:
        var node: GridNode = _grid_node_from_selected(selected)
        if node != null && !selected_nodes.has(node):
            selected_nodes.append(node)

    panel.selected_nodes = selected_nodes
    panel.raw_selection = selections

    if selected_nodes.size() > 1:
        return

    if selections.size() == 1:
        var selection: Node = selections[0]
        var grid_level: GridLevel = GridLevel.find_level_parent(selection)

        if selection is LevelZone:
            print_debug("[Grid Level Digger] Selected a zone: %s" % selection.name)
            var zone: LevelZone = selection
            if zone != panel.zones.selected_zone:
                if panel.level != grid_level:
                    panel.set_level(grid_level)
                panel.zones.selected_zone = zone
            return

        var grid_anchor: GridAnchor = GridAnchor.find_anchor_parent(selection)
        if grid_anchor != null:
            panel.set_grid_anchor(grid_anchor)
            return

        var grid_node: GridNode = GridNode.find_node_parent(selection)
        if grid_node != null:
            panel.set_grid_node(grid_node)
            return

        if grid_level != null:
            if grid_level != panel.level:
                panel.set_level(grid_level)
            return

        print_debug("Selection outside level (%s)" % selection.name)
        panel.set_not_selected_level()
        return

    panel.set_not_selected_level()
    if selections.size():
        print_debug("Multiple items selected (%s)" % selections.size())
    else:
        print_debug("Nothing selected")
