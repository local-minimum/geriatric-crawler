@tool
extends Control
class_name GridLevelZoner

@export var panel: GridLevelDiggerPanel
@export var new_zone_button: Button
@export var zone_picker: ValidatingEditorNodePicker

var _zone_resource: Resource
var _selected_nodes: Array[GridNode]

func _enter_tree() -> void:
    panel.on_update_selected_nodes.connect(_handle_selection_change)

func _exit_tree() -> void:
    panel.on_update_selected_nodes.disconnect(_handle_selection_change)

func get_zone_resource() -> Resource:
    return _zone_resource

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

func _handle_selection_change(selected_nodes: Array[GridNode]) -> void:
    _selected_nodes = selected_nodes
    new_zone_button.disabled = !_allow_create_new
    print_debug("[Grid Level Zoner] %s selected nodes -> can create %s (%s, %s, %s)" % [_selected_nodes.size(), _allow_create_new, panel.level != null, _zone_resource != null, _selected_nodes.size()])

func _on_create_new_zone_pressed() -> void:
    var level: GridLevel = panel.level
    var zone: LevelZone = _zone_resource.instantiate()

    zone.nodes.append_array(_selected_nodes)

    level.zones_parent.add_child(zone, true)
    zone.owner = level.get_tree().edited_scene_root
