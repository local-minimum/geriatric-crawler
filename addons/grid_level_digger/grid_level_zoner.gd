@tool
extends Control
class_name GridLevelZoner

@export var zone_highlight_color: Color = Color.ORANGE_RED
@export var panel: GridLevelDiggerPanel
@export var new_zone_button: Button
@export var zone_picker: ValidatingEditorNodePicker
@export var zone_lister: MenuButton
@export var add_to_zone: Button
@export var remove_from_zone: Button
@export var set_as_zone: Button
@export var delete_zone: Button

var _zone_resource: Resource
var _selected_nodes: Array[GridNode]
var selected_zone: LevelZone:
    set(value):
        selected_zone = value
        _sync_zone_lister()
        _sync_zone_actions()
        _sync_zone_highlight()
        print_debug("[Grid Level Zoner] Updated selected zone to '%s'" % value)

var _zone_highlights: Array[MeshInstance3D]

func _enter_tree() -> void:
    if !panel.on_update_selected_nodes.is_connected(_handle_selection_change):
        if panel.on_update_selected_nodes.connect(_handle_selection_change) != OK:
            push_error("Failed to connect update selected nodes")

    if !panel.on_update_level.is_connected(_handle_update_level):
        if panel.on_update_level.connect(_handle_update_level) != OK:
            push_error("Failed to connect update level")

    if !zone_lister.get_popup().id_pressed.is_connected(_handle_select_zone):
        if zone_lister.get_popup().id_pressed.connect(_handle_select_zone) != OK:
            push_error("Failed to connect zone lister changed")

func _exit_tree() -> void:
    panel.on_update_selected_nodes.disconnect(_handle_selection_change)
    panel.on_update_level.disconnect(_handle_update_level)

    for mesh: MeshInstance3D in _zone_highlights:
        mesh.queue_free()
    _zone_highlights.clear()

func _ready() -> void:
    _sync_zone_lister()
    _sync_zone_actions()
    _sync_zone_actions()
    _sync_zone_highlight()

var _forcing_resource_change: bool

func _on_zone_picker_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _zone_resource = null
        new_zone_button.disabled = true
        return

    if !zone_picker.is_valid(resource):
        _forcing_resource_change = true
        zone_picker.edited_resource = null
        _zone_resource = null
        push_warning("%s is not a %s" % [resource, zone_picker.root_class_name])
        _forcing_resource_change = false
        new_zone_button.disabled = !_allow_create_new
    else:
        _zone_resource = resource
        new_zone_button.disabled = false
        print_debug("[Grid Level Zoner] %s selected nodes -> can create %s" % [_selected_nodes.size(), _allow_create_new])

var _allow_create_new: bool:
    get():
        return panel.level != null && _zone_resource != null && !_selected_nodes.is_empty()

func _handle_select_zone(id: int) -> void:
    var level: GridLevel = panel.level
    if level == null:
        push_error("Cannot select zones when not a grid level scene")
        return

    var zone: LevelZone
    if id == NO_ZONE:
        zone = null
    else:
        zone = level.zones[id] if id >= 0 && id < level.zones.size() else null

    if zone == selected_zone:
        return

    selected_zone = zone
    print_debug("[Grid Level Zoner] Selected zone from popup")

func _handle_update_level(level: GridLevel) -> void:
    _selected_nodes.clear()
    selected_zone = null

    print_debug("[Grid Level Zoner] Updated level")

func _handle_selection_change(selected_nodes: Array[GridNode]) -> void:
    _selected_nodes = selected_nodes
    new_zone_button.disabled = !_allow_create_new
    new_zone_button.text = "Create new zone from %s selected node%s" % [selected_nodes.size(), "" if selected_nodes.size() == 1 else "s"]
    _sync_zone_actions()

func _on_create_new_zone_pressed() -> void:
    panel.undo_redo.create_action("GridLevelZoner: Create Zone")
    panel.undo_redo.add_do_method(self, "_do_create_zone", _zone_resource, _selected_nodes.duplicate())
    panel.undo_redo.add_undo_method(self, "_do_erase_zone", panel.level.zones.size() if panel.level != null else -1)
    panel.undo_redo.commit_action()

func _do_create_zone(resource: Resource, nodes: Array[GridNode]) -> void:
    var level: GridLevel = panel.level
    if level == null:
        push_error("Cannot add zone current scene isn't a grid level")
        return

    if resource == null:
        push_error("Cannot create zone without a resource to instance")
        return

    var zone: LevelZone = resource.instantiate()

    zone.nodes = nodes

    level.zones_parent.add_child(zone, true)
    zone.owner = level.get_tree().edited_scene_root

    level.zones.append(zone)
    selected_zone = zone
    print_debug("[Grid Level Zoner] Added new zone %s" % _name_zone(zone))

func _name_zone(zone: LevelZone) -> String: return "%s [%s]: %s node%s" % [zone.name, zone.get_script().get_global_name(), zone.nodes.size(), "" if zone.nodes.size() == 1 else "s"]

const NO_ZONE: int = 99999

func _sync_zone_lister() -> void:
    var level: GridLevel = panel.level

    if level == null:
        zone_lister.disabled = true
        zone_lister.text = "Current scene not a grid level"
        return

    if selected_zone == null:
        zone_lister.text = "%s Zones in level '%s'" % [level.zones.size(), level.level_id]
    else:
        zone_lister.text = _name_zone(selected_zone)

    zone_lister.disabled = level.zones.is_empty()

    var popup: PopupMenu = zone_lister.get_popup()
    popup.clear()

    popup.add_radio_check_item("[No zone selected]", NO_ZONE)

    for idx: int in range(level.zones.size()):
        var zone: LevelZone = level.zones[idx]
        popup.add_radio_check_item(_name_zone(zone), idx)

func _sync_zone_highlight() -> void:
    for mesh: MeshInstance3D in _zone_highlights:
        mesh.queue_free()
    _zone_highlights.clear()

    var level: GridLevel = panel.level
    if selected_zone == null || level == null:
        return

    for node: GridNode in selected_zone.nodes:
        var center: Vector3 = GridLevel.node_center(level, node.coordinates)

        _zone_highlights.append(
            DebugDraw.box(
                level,
                center,
                level.node_size,
                zone_highlight_color,
                false,
            )
        )


func _sync_zone_actions() -> void:
    add_to_zone.disabled = selected_zone == null
    remove_from_zone.disabled = selected_zone == null
    set_as_zone.disabled = selected_zone == null
    delete_zone.disabled = selected_zone == null || panel.level == null

func _on_delete_zone_pressed() -> void:
    if selected_zone == null || panel.level == null:
        return

    var resource: Resource = load(selected_zone.scene_file_path)

    panel.undo_redo.create_action("GridLevelZoner: Delete %s" % selected_zone.name)
    panel.undo_redo.add_do_method(self, "_do_erase_zone", panel.level.zones.find(selected_zone) if panel.level != null else -1)
    panel.undo_redo.add_undo_method(self, "_do_create_zone", resource, selected_zone.nodes.duplicate())
    panel.undo_redo.commit_action()

func _do_erase_zone(idx: int) -> void:
    if panel.level == null:
        push_error("Failed to erase level")
        return

    var zone: LevelZone = panel.level.zones[idx] if idx >= 0 && idx < panel.level.zones.size() else null
    if zone == null:
        return

    var updated_select: bool = zone == selected_zone

    panel.level.zones.erase(zone)
    zone.free()

    if updated_select:
        selected_zone = null

func _on_set_selection_as_zone_pressed() -> void:
    if selected_zone == null || panel.level == null:
        return

    panel.undo_redo.create_action("GridLevelZoner: Add to zone %s" % selected_zone.name)
    panel.undo_redo.add_do_method(self, "_do_set_zone_nodes", selected_zone, _selected_nodes.duplicate())
    panel.undo_redo.add_undo_method(self, "_do_set_zone_nodes", selected_zone, selected_zone.nodes.duplicate())
    panel.undo_redo.commit_action()

func _do_set_zone_nodes(zone: LevelZone, nodes: Array[GridNode]) -> void:
    zone.nodes = nodes
    _sync_zone_lister()
    _sync_zone_highlight()

func _on_add_to_zone_pressed() -> void:
    if selected_zone == null || panel.level == null:
        return

    var new_nodes: Array[GridNode] = []
    for node: GridNode in _selected_nodes:
        if selected_zone.nodes.has(node):
            continue
        new_nodes.append(node)

    if !new_nodes.is_empty():
        panel.undo_redo.create_action("GridLevelZoner: Add to zone %s" % selected_zone.name)
        panel.undo_redo.add_do_method(self, "_do_add_to_zone", selected_zone, new_nodes)
        panel.undo_redo.add_undo_method(self, "_do_remove_from_zone", selected_zone, new_nodes)
        panel.undo_redo.commit_action()

func _do_add_to_zone(zone: LevelZone, nodes: Array[GridNode]) -> void:
    var updated: bool = false
    for node: GridNode in nodes:
        if zone.nodes.has(node):
            continue

        zone.nodes.append(node)
        updated = true

    if updated:
        _sync_zone_lister()
        _sync_zone_highlight()

func _on_remove_from_zone_pressed() -> void:
    if selected_zone == null || panel.level == null:
        return

    var old_nodes: Array[GridNode] = []
    for node: GridNode in _selected_nodes:
        if selected_zone.nodes.has(node):
            old_nodes.append(node)

    if !old_nodes.is_empty():
        panel.undo_redo.create_action("GridLevelZoner: Add to zone %s" % selected_zone.name)
        panel.undo_redo.add_do_method(self, "_do_remove_from_zone", selected_zone, old_nodes)
        panel.undo_redo.add_undo_method(self, "_do_add_to_zone", selected_zone, old_nodes)
        panel.undo_redo.commit_action()

func _do_remove_from_zone(zone: LevelZone, nodes: Array[GridNode]) -> void:
    var updated: bool
    for node: GridNode in nodes:
        if zone.nodes.has(node):
            zone.nodes.erase(node)
            updated = true

    if updated:
        _sync_zone_lister()
        _sync_zone_highlight()
