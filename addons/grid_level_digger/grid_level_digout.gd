@tool
extends Control
class_name GridLevelDigout

@export_group("Size")
@export var _x_size: SpinBox
@export var _y_size: SpinBox
@export var _z_size: SpinBox

@export_group("Other")
@export var _nav: GridLevelNav
@export var _highligh_color: Color = Color.AZURE
@export var _preserve: CheckButton

var _panel: GridLevelDiggerPanel
var _size: Vector3i = Vector3i(3, 1, 3)
var _preview_highlight: MeshInstance3D

func configure(panel: GridLevelDiggerPanel) -> void:
    _panel = panel
    _nav.panel = panel

    if _nav.on_update_nav.connect(_handle_nav) != OK:
        push_error("Failed to connect update nav")

    panel.register_nav(_nav)

    _size = panel.digout_size
    _x_size.value = _size.x
    _y_size.value = _size.y
    _z_size.value = _size.z

    _preserve.button_pressed = panel.digout_preserve

    _handle_nav(panel.coordinates, panel.look_direction)

func _exit_tree() -> void:
    _panel.set_digout_settings(_size, _preserve.button_pressed)
    _panel.unregister_nav(_nav)

    _nav.on_update_nav.disconnect(_handle_nav)

    _clear_highlights()
    print_debug("[GDL Dig-Out] Exit tree")

func _on_z_size_value_changed(value:float) -> void:
    _size.z = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _on_y_size_value_changed(value:float) -> void:
    _size.y = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _on_x_size_value_changed(value:float) -> void:
    _size.x = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _clear_highlights() -> void:
    if _preview_highlight != null:
        _preview_highlight.queue_free()
        _preview_highlight = null

func _handle_nav(coordinates: Vector3i, _look_directoin: CardinalDirections.CardinalDirection) -> void:
    _clear_highlights()

    var bounds: AABB = AABBUtils.create_around_coordinates(coordinates, _size, _panel.level.node_size, _panel.level.node_spacing)
    _preview_highlight = DebugDraw.box(
        _panel.level,
        bounds.get_center(),
        bounds.size,
        _highligh_color,
        false,
    )

func _on_dig_out_pressed() -> void:
    pass

func _on_preserve_existing_toggled(toggled_on:bool) -> void:
    pass
