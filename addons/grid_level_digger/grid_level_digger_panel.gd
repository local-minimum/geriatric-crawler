@tool
extends Panel
class_name GridLevelDiggerPanel

signal on_update_raw_selection(nodes: Array[Node])
signal on_update_selected_nodes(nodes: Array[GridNode])
signal on_update_level(level: GridLevel)

var level: GridLevel:
    set(value):
        if inside_level:
            level = value
            on_update_level.emit(level if inside_level else null)
        else:
            level = value

var _node: GridNode
var _anchor: GridAnchor

var inside_level: bool:
    set(value):
        if value != inside_level:
            inside_level = value
            on_update_level.emit(level if inside_level else null)

var coordinates: Vector3i = Vector3i.ZERO : set = _set_coords
func _set_coords(value: Vector3i) -> void:
    coordinates = value
    _draw_debug_node_meshes()

var undo_redo: EditorUndoRedoManager

var all_level_nodes: Array[GridNode] = []

@export var tab_container: TabContainer

@export var about_tab: Control
@export var level_tab: Control
@export var digging_tab: Control
@export var manipulate_tab: Control
@export var style_tab: Control

@export var styles: GridLevelStyle
@export var node_digger: GridNodeDigger
@export var level_actions: GridLevelActions
@export var manipulator: GridLevelManipulator
@export var zones: GridLevelZoner

@export var settings_storage: SaveStorageProvider

var selected_nodes: Array[GridNode]:
    set(value):
        selected_nodes = value
        on_update_selected_nodes.emit(value)

var raw_selection: Array[Node]:
    set(value):
        raw_selection = value
        on_update_raw_selection.emit(value)

func _enter_tree() -> void:
    _load_settings()
    if styles.on_style_updated.connect(_handle_style_updated) != OK:
        push_error("Failed to connect style updated")

func get_level() -> GridLevel:
    return level

func get_grid_node() -> GridNode:
    return _node

func get_grid_node_at(coordinates: Vector3i) -> GridNode:
    var idx = all_level_nodes.find_custom(func (n: GridNode) -> bool: return n.coordinates == coordinates)
    if idx < 0:
        return null
    return all_level_nodes[idx]

func get_focus_node() -> GridNode:
    return get_grid_node_at(coordinates)

func add_grid_node(node: GridNode) -> void:
    if all_level_nodes.has(node):
        return

    all_level_nodes.append(node)

func remove_grid_node(node: GridNode) -> void:
    all_level_nodes.erase(node)

func get_grid_anchor() -> GridAnchor:
    return _anchor

func set_level(level: GridLevel) -> void:
    if self.level != level:
        self.level = level
    _node = null
    _anchor = null
    inside_level = true
    coordinates = Vector3i.ZERO

    refresh_level_nodes()

    sync_ui()

func refresh_level_nodes():
    all_level_nodes.clear()

    if level != null:
        all_level_nodes.append_array(level.find_children("", "GridNode"))


func _update_level_if_needed(grid_node: GridNode) -> bool:
    var level: GridLevel = GridLevel.find_level_parent(grid_node)
    if self.level != level:
        self.level = level

        refresh_level_nodes()
        return true

    elif all_level_nodes.size() == 0:
        all_level_nodes.append_array(level.find_children("", "GridNode"))

    return false

func set_grid_node(grid_node: GridNode) -> void:
    if grid_node == _node:
        _update_level_if_needed(grid_node)
        if !inside_level:
            inside_level = true
            sync_ui()
        return

    if !_update_level_if_needed(grid_node) && !all_level_nodes.has(grid_node):
        if all_level_nodes.size() == 0:
            refresh_level_nodes()
        else:
            all_level_nodes.append(grid_node)

    _node = grid_node
    _anchor = null
    inside_level = true

    coordinates = grid_node.coordinates

    sync_ui()

func set_grid_anchor(grid_anchor: GridAnchor) -> void:
    if _anchor == grid_anchor:
        if !inside_level:
            inside_level = true
            sync_ui()
        return

    var grid_node: GridNode = GridNode.find_node_parent(grid_anchor)
    if grid_node != _node:
        if !_update_level_if_needed(grid_node) && !all_level_nodes.has(grid_node):
            if all_level_nodes.size() == 0:
                refresh_level_nodes()
            else:
                all_level_nodes.append(grid_node)

        _node = grid_node
        if _node != null:
            coordinates = _node.coordinates

    inside_level = true
    sync_ui()

func set_not_selected_level() -> void:
    inside_level = false
    sync_ui()

func get_tab_index(control: Control) -> int:
    return control.get_parent().get_children().find(control)

func sync_ui() -> void:
    if inside_level:
        tab_container.set_tab_disabled(get_tab_index(level_tab), false)
        tab_container.set_tab_disabled(get_tab_index(digging_tab), false)
        tab_container.set_tab_disabled(get_tab_index(manipulate_tab), false)


        if tab_container.current_tab == get_tab_index(about_tab):
            tab_container.current_tab = get_tab_index(level_tab)

        level_actions.sync_ui()
        manipulator.sync()
        node_digger.sync()

        _draw_debug_node_meshes()
    else:
        tab_container.set_tab_disabled(get_tab_index(level_tab), true)
        tab_container.set_tab_disabled(get_tab_index(digging_tab), true)
        tab_container.set_tab_disabled(get_tab_index(manipulate_tab), true)

        tab_container.current_tab = get_tab_index(about_tab)

        remove_debug_nodes()

var _node_debug_mesh: MeshInstance3D
var _node_debug_center: MeshInstance3D
var _node_debug_anchors: Array[MeshInstance3D] = []

func _draw_debug_node_meshes() -> void:
    _clear_node_debug_frame()
    _clear_node_debug_center()
    _clear_node_debug_anchors()

    if level != null:
        var center: Vector3 = GridLevel.node_center(level, coordinates)

        _node_debug_mesh = DebugDraw.box(
            level,
            center,
            level.node_size,
            Color.MAGENTA)

        var node: GridNode = get_grid_node_at(coordinates)

        if node != null:
            _node_debug_center = DebugDraw.sphere(level, center, DebugDraw.direction_to_color(CardinalDirections.CardinalDirection.NONE))

            for node_side: GridNodeSide in node.find_children("", "GridNodeSide"):
                var anchor: GridAnchor = node_side.anchor
                if anchor.required_transportation_mode.mode != TransportationMode.NONE:
                    _node_debug_anchors.append(
                        DebugDraw.sphere(node, anchor.global_position, DebugDraw.direction_to_color(node_side.direction), 0.1)
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
        if mesh == null:
            continue
        mesh.queue_free()

    _node_debug_anchors.clear()

func remove_debug_nodes() -> void:
    _clear_node_debug_frame()
    _clear_node_debug_center()
    _clear_node_debug_anchors()
    node_digger.remove_debug_nodes()

var _stored_settings: Dictionary
const _STYLE_KEY: String = "style"

func _handle_style_updated() -> void:
    _stored_settings[_STYLE_KEY] = styles.collect_save_data()
    settings_storage.store_data(0, _stored_settings)

func _load_settings() -> void:
    _stored_settings = settings_storage.retrieve_data(0, true)
    styles.load_from_save(DictionaryUtils.safe_getd(_stored_settings, _STYLE_KEY, {}, false))
