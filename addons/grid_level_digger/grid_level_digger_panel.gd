@tool
extends Panel
class_name GridLevelDiggerPanel

var _level: GridLevel
var _node: GridNode
var _anchor: GridAnchor

var _selected_inside_level: bool

var undo_redo: EditorUndoRedoManager

var all_level_nodes: Array[GridNode] = []

@export
var node_digger: GridNodeDigger

@export
var single_select_group: Control

@export
var info_label: Control

func get_level() -> GridLevel:
    return _level

func get_grid_node() -> GridNode:
    return _node

func get_grid_node_at(coordinates: Vector3i) -> GridNode:
    var idx = all_level_nodes.find_custom(func (n: GridNode) -> bool: return n.coordinates == coordinates)
    if idx < 0:
        return null
    return all_level_nodes[idx]


func get_grid_anchor() -> GridAnchor:
    return _anchor

func set_level(level: GridLevel) -> void:
    _level = level
    _node = null
    _anchor = null
    _selected_inside_level = true

    _draw_debug_node_meshes()
    _sync_ui()

func _update_level_if_needed(grid_node: GridNode) -> bool:
    var level: GridLevel = GridLevel.find_level_parent(grid_node)
    if level != _level:
        _level = level

        all_level_nodes.clear()
        all_level_nodes.append_array(level.find_children("", "GridNode"))

        return true

    return false


func set_grid_node(grid_node: GridNode) -> void:
    if grid_node == _node:
        if !_selected_inside_level:
            _selected_inside_level = true
            _sync_ui()
        return

    if !_update_level_if_needed(grid_node) && !all_level_nodes.has(grid_node):
        all_level_nodes.append(grid_node)

    _node = grid_node
    _anchor = null
    _selected_inside_level = true

    _draw_debug_node_meshes()
    _sync_ui()

func set_grid_anchor(grid_anchor: GridAnchor) -> void:
    if _anchor == grid_anchor:
        if !_selected_inside_level:
            _selected_inside_level = true
            _sync_ui()
        return

    var grid_node: GridNode = GridNode.find_node_parent(grid_anchor)
    if grid_node != _node:
        if !_update_level_if_needed(grid_node) && !all_level_nodes.has(grid_node):
            all_level_nodes.append(grid_node)

        _node = grid_node

        _draw_debug_node_meshes()

    _selected_inside_level = true
    _sync_ui()

func set_not_selected_level() -> void:
    _selected_inside_level = false
    _sync_ui()

func _sync_ui() -> void:
    if _selected_inside_level:
        node_digger.visible = _node != null
        if _node != null:
            node_digger.sync(true)

        info_label.visible = false
        single_select_group.visible = true
    else:
        info_label.visible = true
        single_select_group.visible = false

var _node_debug_mesh: MeshInstance3D
var _node_debug_center: MeshInstance3D
var _node_debug_anchors: Array[MeshInstance3D] = []

func _draw_debug_node_meshes() -> void:
    if _node != null:
        draw_debug_node_meshes(_node.coordinates)
        return

    _clear_node_debug_frame()
    _clear_node_debug_center()
    _clear_node_debug_anchors()

func draw_debug_node_meshes(coordinates: Vector3i) -> void:
    _clear_node_debug_frame()
    _clear_node_debug_center()
    _clear_node_debug_anchors()

    if _level != null:
        var center: Vector3 = GridLevel.node_center(_level, coordinates)

        _node_debug_mesh = DebugDraw.wireframe_box(
            _level,
            center,
            _level.node_size,
            Color.MAGENTA)


        var node: GridNode = get_grid_node_at(coordinates)

        if node != null:
            _node_debug_center = DebugDraw.sphere(_level, center, DebugDraw.direction_to_color(CardinalDirections.CardinalDirection.NONE))

            for anchor: Node in node.find_children("", "GridAnchor"):
                if anchor is GridAnchor:
                    if anchor.required_transportation_mode.mode != TransportationMode.NONE:
                        var direction: CardinalDirections.CardinalDirection = anchor.direction
                        if anchor.set_rotation_from_parent:
                            direction = CardinalDirections.node_planar_rotation_to_direction(anchor.get_parent())

                        _node_debug_anchors.append(
                            DebugDraw.sphere(node, anchor.global_position, DebugDraw.direction_to_color(direction), 0.1)
                        )

func _clear_node_debug_frame() -> void:
    if _node_debug_mesh != null:
        _node_debug_mesh.queue_free()
        _node_debug_mesh = null

func _clear_node_debug_center() -> void:
    if _node_debug_center != null:
        _node_debug_center.queue_free()
        _node_debug_center = null

func _clear_node_debug_anchors() -> void:
    if _node_debug_anchors.is_empty():
        return

    for mesh: MeshInstance3D in _node_debug_anchors:
        mesh.queue_free()

    _node_debug_anchors.clear()


func remove_debug_nodes() -> void:
    _clear_node_debug_frame()
    _clear_node_debug_center()
    _clear_node_debug_anchors()
    node_digger.remove_debug_nodes()
