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
@export var _grid_node_use: CheckBox
var _grid_node_resource: Resource
var _grid_node_used: bool:
    get():
        return _grid_node_use.toggle_mode
    set(value):
        _grid_node_use.toggle_mode = value

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
@export var _grid_ceiling_use: CheckBox
var _grid_ceiling_resource: Resource
var _grid_ceiling_used: bool:
    get():
        return _grid_ceiling_use.toggle_mode
    set(value):
        _grid_ceiling_use.toggle_mode = value

func get_ceiling_resource() -> Resource:
    return _grid_ceiling_resource if _grid_ceiling_used else null

func get_ceiling_resource_path() -> String:
    return _grid_ceiling_resource.resource_path if _grid_ceiling_resource != null && _grid_ceiling_used else ""

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
@export var _grid_floor_use: CheckBox
var _grid_floor_resource: Resource
var _grid_floor_used: bool:
    get():
        return _grid_floor_use.toggle_mode
    set(value):
        _grid_floor_use.toggle_mode = value

func get_floor_resource() -> Resource:
    return _grid_floor_resource if _grid_floor_used else null

func get_floor_resource_path() -> String:
    return _grid_floor_resource.resource_path if _grid_floor_resource != null && _grid_floor_used else ""

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
@export var _grid_wall_use: CheckBox
var _grid_wall_resource: Resource
var _grid_wall_used: bool:
    get():
        return _grid_wall_use.toggle_mode
    set(value):
        _grid_wall_use.toggle_mode = value

func get_wall_resource() -> Resource:
    return _grid_wall_resource if _grid_wall_used else null

func get_wall_resource_path() -> String:
    return _grid_wall_resource.resource_path if _grid_wall_resource != null && _grid_wall_used else ""

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

func _on_grid_ceiling_used_toggled(_toggled_on: bool) -> void:
    on_style_updated.emit()

func _on_grid_floor_used_toggled(_toggled_on: bool) -> void:
    on_style_updated.emit()

func _on_grid_wall_used_toggled(_toggled_on: bool) -> void:
    on_style_updated.emit()

func _on_grid_node_used_toggled(_toggled_on: bool) -> void:
    on_style_updated.emit()

func get_resource_from_direction(dir: CardinalDirections.CardinalDirection) -> Resource:
    if CardinalDirections.is_planar_cardinal(dir):
        return _grid_wall_resource if _grid_wall_used else null
    elif dir == CardinalDirections.CardinalDirection.UP:
        return _grid_ceiling_resource if _grid_ceiling_used else null
    elif dir == CardinalDirections.CardinalDirection.DOWN:
        return _grid_floor_resource if _grid_floor_used else null
    return null

func set_resource(dir: CardinalDirections.CardinalDirection, resource: Resource) -> void:
    if CardinalDirections.is_planar_cardinal(dir):
        _grid_wall_resource = resource
        grid_wall_picker.edited_resource = resource
        _grid_wall_used = true
        _grid_wall_use.button_pressed = true
    elif dir == CardinalDirections.CardinalDirection.UP:
        _grid_ceiling_resource = resource
        grid_ceiling_picker.edited_resource = resource
        _grid_ceiling_used = true
        _grid_ceiling_use.button_pressed = true
    elif dir == CardinalDirections.CardinalDirection.DOWN:
        _grid_floor_resource = resource
        grid_floor_picker.edited_resource = resource
        _grid_floor_used = true
        _grid_floor_use.button_pressed = true

    on_style_updated.emit()

func get_resource_path_from_direction(dir: CardinalDirections.CardinalDirection) -> String:
    if CardinalDirections.is_planar_cardinal(dir):
        return get_wall_resource_path()
    elif dir == CardinalDirections.CardinalDirection.UP:
        return get_ceiling_resource_path()
    elif dir == CardinalDirections.CardinalDirection.DOWN:
        return get_floor_resource_path()
    return ""

const _NODE_KEY: String = "node"
const _NODE_USED_KEY: String = "node-used"
const _CEILING_KEY: String = "ceiling"
const _CEILING_USED_KEY: String = "ceiling-used"
const _WALL_KEY: String = "wall"
const _WALL_USED_KEY: String = "wall-used"
const _FLOOR_KEY: String = "floor"
const _FLOOR_USED_KEY: String = "floor-used"

func collect_save_data() -> Dictionary:
    return {
        _NODE_KEY: _grid_node_resource.resource_path if _grid_node_resource != null else "",
        _NODE_USED_KEY: _grid_node_used,
        _CEILING_KEY: _grid_ceiling_resource.resource_path if _grid_ceiling_resource != null else "",
        _CEILING_USED_KEY: _grid_ceiling_used,
        _FLOOR_KEY: _grid_floor_resource.resource_path if _grid_floor_resource != null else "",
        _FLOOR_USED_KEY: _grid_floor_used,
        _WALL_KEY: _grid_wall_resource.resource_path if _grid_wall_resource != null else "",
        _WALL_USED_KEY: _grid_wall_used,
    }

func load_from_save(data: Dictionary) -> void:
    _grid_node_used = DictionaryUtils.safe_getb(data, _NODE_USED_KEY, true, false)
    _grid_ceiling_used = DictionaryUtils.safe_getb(data, _CEILING_USED_KEY, true, false)
    _grid_wall_used = DictionaryUtils.safe_getb(data, _WALL_USED_KEY, true, false)
    _grid_floor_used = DictionaryUtils.safe_getb(data, _FLOOR_USED_KEY, true, false)

    var path: String = DictionaryUtils.safe_gets(data, _NODE_KEY, "", false)
    if !ResourceUtils.valid_abs_resource_path(path):
        _grid_node_resource = null
    else:
        _grid_node_resource = load(path)
    _grid_node_picker.edited_resource = _grid_node_resource

    path = DictionaryUtils.safe_gets(data, _CEILING_KEY, "", false)
    if !ResourceUtils.valid_abs_resource_path(path):
        _grid_ceiling_resource = null
    else:
        _grid_ceiling_resource = load(path)
    grid_ceiling_picker.edited_resource = _grid_ceiling_resource

    path = DictionaryUtils.safe_gets(data, _WALL_KEY, "", false)
    if !ResourceUtils.valid_abs_resource_path(path):
        _grid_wall_resource = null
    else:
        _grid_wall_resource = load(path)
    grid_wall_picker.edited_resource = _grid_wall_resource

    path = DictionaryUtils.safe_gets(data, _FLOOR_KEY, "", false)
    if !ResourceUtils.valid_abs_resource_path(path):
        _grid_floor_resource = null
    else:
        _grid_floor_resource = load(path)
    grid_floor_picker.edited_resource = _grid_floor_resource
