@tool
extends VBoxContainer
class_name GridLevelStyle

signal on_style_updated

var _forcing_resource_change: bool


func has_any_side_resource_selected() -> bool:
    return (
        (_grid_wall_resource != null if _grid_wall_used else false) ||
        (_grid_floor_resource != null if _grid_floor_used else false) ||
        (_grid_ceiling_resource != null if _grid_ceiling_used else false)
    )

@export var _grid_node_picker: ValidatingEditorNodePicker
var _grid_node_resource: Resource
var _grid_node_used: bool = true

func get_node_resource() -> Resource:
    return _grid_node_resource if _grid_node_used else null

func has_grid_node_resource_selected() -> bool:
    return _grid_node_resource != null if _grid_node_used else false

func _on_grid_node_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_node_resource = null
        on_style_updated.emit()
        return

    if !_grid_node_picker.is_valid(resource):
        _forcing_resource_change = true
        _grid_node_picker.edited_resource = null
        _grid_node_resource = null
        push_warning("%s is not a %s" % [resource, _grid_node_picker.root_class_name])
        _forcing_resource_change = false

    _grid_node_resource = resource
    on_style_updated.emit()

@export var grid_ceiling_picker: ValidatingEditorNodePicker
var _grid_ceiling_resource: Resource
var _grid_ceiling_used: bool = true

func get_ceiling_resource() -> Resource:
    return _grid_ceiling_resource if _grid_ceiling_used else null

func _on_grid_ceiling_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_ceiling_resource = null
        on_style_updated.emit()
        return

    if !grid_ceiling_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_ceiling_picker.edited_resource = null
        _grid_ceiling_resource = null
        push_warning("%s is not a %s" % [resource, grid_ceiling_picker.root_class_name])
        _forcing_resource_change = false
    else:
        _grid_ceiling_resource = resource

    on_style_updated.emit()

@export var grid_floor_picker: ValidatingEditorNodePicker
var _grid_floor_resource: Resource
var _grid_floor_used: bool = true

func get_floor_resource() -> Resource:
    return _grid_floor_resource if _grid_floor_used else null

func _on_grid_floor_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        on_style_updated.emit()
        return

    if resource == null:
        _grid_floor_resource = null
        return

    if !grid_floor_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_floor_picker.edited_resource = null
        _grid_floor_resource = null
        push_warning("%s is not a %s" % [resource, grid_floor_picker.root_class_name])
        _forcing_resource_change = false
    else:
        _grid_floor_resource = resource

    on_style_updated.emit()

@export var grid_wall_picker: ValidatingEditorNodePicker
var _grid_wall_resource: Resource
var _grid_wall_used: bool = true

func get_wall_resource() -> Resource:
    return _grid_wall_resource if _grid_wall_used else null

func _on_grid_wall_picker_resource_changed(resource:Resource) -> void:
    if _forcing_resource_change:
        return

    if resource == null:
        _grid_wall_resource = null
        on_style_updated.emit()
        return

    if !grid_wall_picker.is_valid(resource):
        _forcing_resource_change = true
        grid_wall_picker.edited_resource = null
        _grid_wall_resource = null
        push_warning("%s is not a %s" % [resource, grid_wall_picker.root_class_name])
        _forcing_resource_change = false
    else:
        _grid_wall_resource = resource

    on_style_updated.emit()

func _on_grid_ceiling_used_toggled(toggled_on:bool) -> void:
    _grid_ceiling_used = toggled_on
    on_style_updated.emit()

func _on_grid_floor_used_toggled(toggled_on:bool) -> void:
    _grid_floor_used = toggled_on
    on_style_updated.emit()

func _on_grid_wall_used_toggled(toggled_on:bool) -> void:
    _grid_wall_used = toggled_on
    on_style_updated.emit()

func _on_grid_node_used_toggled(toggled_on:bool) -> void:
    _grid_node_used = toggled_on
    on_style_updated.emit()

func get_resource_from_direction(dir: CardinalDirections.CardinalDirection) -> Resource:
    if CardinalDirections.is_planar_cardinal(dir):
        return _grid_wall_resource if _grid_wall_used else null
    elif dir == CardinalDirections.CardinalDirection.UP:
        return _grid_ceiling_resource if _grid_ceiling_used else null
    elif dir == CardinalDirections.CardinalDirection.DOWN:
        return _grid_floor_resource if _grid_floor_used else null
    return null
