@tool
extends Control
class_name GridLevelBoxIn

@export_group("Size")
@export var _x_size: SpinBox
@export var _y_size: SpinBox
@export var _z_size: SpinBox

@export_group("Other")
@export var _nav: GridLevelNav
@export var _highligh_color: Color = Color.AZURE
@export var _preserve: CheckButton

var _panel: GridLevelDiggerPanel
var _size: Vector3i = Vector3i(12, 12, 12)
var _preview_highlight: MeshInstance3D

func configure(panel: GridLevelDiggerPanel) -> void:
    _panel = panel
    _nav.panel = panel

    if _nav.on_update_nav.connect(_handle_nav) != OK:
        push_error("[GDL Box In] Failed to connect update nav")

    panel.register_nav(_nav)

    _size = panel.boxin_size
    _x_size.value = _size.x
    _y_size.value = _size.y
    _z_size.value = _size.z

    _preserve.button_pressed = panel.boxin_preserve

    _handle_nav(panel.coordinates, panel.look_direction)

func _exit_tree() -> void:
    _panel.set_boxin_settings(_size, _preserve.button_pressed)
    _panel.unregister_nav(_nav)

    _nav.on_update_nav.disconnect(_handle_nav)

    _clear_highlights()
    print_debug("[GDL Box In] Exit tree")

func _on_z_size_value_changed(value:float) -> void:
    _size.z = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _on_y_size_value_changed(value:float) -> void:
    _size.y = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _on_x_size_value_changed(value:float) -> void:
    _size.x = maxi(1, roundi(value))
    _handle_nav(_panel.coordinates, _panel.look_direction)

func _handle_nav(coordinates: Vector3i, _look_directoin: CardinalDirections.CardinalDirection) -> void:
    _clear_highlights()

    var bounds: AABB = AABBUtils.create_around_coordinates(coordinates, _size, _panel.level.node_size, _panel.level.node_spacing).grow(0.1)
    _preview_highlight = DebugDraw.box(
        _panel.level,
        bounds.get_center(),
        bounds.size,
        _highligh_color,
        false,
    )

func _clear_highlights() -> void:
    if _preview_highlight != null:
        _preview_highlight.queue_free()
        _preview_highlight = null

func _add_side_to_node(node: GridNode, side_direction: CardinalDirections.CardinalDirection, styles: GridLevelStyle, level: GridLevel) -> void:
    var side_resource: PackedScene = styles.get_resource_from_direction(side_direction)
    var side: GridNodeSide = side_resource.instantiate()

    side.direction = side_direction
    side.name = "Side %s" % CardinalDirections.name(side_direction)

    node.add_child(side, true)

    side.position = Vector3.ZERO
    if CardinalDirections.is_planar_cardinal(side_direction):
        side.global_rotation = CardinalDirections.direction_to_planar_rotation(side_direction).get_euler()

    side.owner = level.get_tree().edited_scene_root

    if side.infer_direction_from_rotation:
        GridNodeSide.set_direction_from_rotation(side)

func _on_preserve_existing_toggled(toggled_on:bool) -> void:
    # If we want to highlight preserving differently then we should do so from here
    pass

func _on_box_in_pressed() -> void:
    if !_panel.styles.has_grid_node_resource_selected():
        push_error("[GLD Box In] Must have at least a grid node active and selected in the style tab to box in!")
        return

    var min: Vector3i = _panel.coordinates - (_size - Vector3i.ONE) / 2
    var preexisting: Dictionary[Vector3i, GridNode]
    var to_dig: Array[Vector3i] = VectorUtils.all_surrounding_coordinates(min, _size, true)

    for coords: Vector3i in to_dig:
        var node: GridNode = _panel.get_grid_node_at(coords)
        if node != null:
            preexisting[coords] = node

    if _preserve.button_pressed:
        for coords: Vector3i in preexisting:
            to_dig.erase(coords)

    # Inside the shell
    var inside: Dictionary[Vector3i, GridNode]
    min = _panel.coordinates - (_size - 2 * Vector3i.ONE) / 2
    for coords: Vector3i in VectorUtils.all_surrounding_coordinates(min, _size, true):
        var node: GridNode = _panel.get_grid_node_at(coords)
        if node != null:
            inside[coords] = node

    # TODO: Figure out proper undo
    _do_boxin(_panel.coordinates, to_dig, preexisting, inside, _preserve.button_pressed)

func _do_boxin(center: Vector3i, to_dig: Array[Vector3i], preexisting: Dictionary[Vector3i, GridNode], inside: Dictionary[Vector3i, GridNode], preserve: bool) -> void:
    var level: GridLevel = _panel.level
    var level_actions: GridLevelActions = _panel.level_actions
    var styles: GridLevelStyle = _panel.styles
    var node_resource: PackedScene = styles.get_node_resource()

    for coords: Vector3i in to_dig:
        if preexisting.has(coords):
            if preserve:
                continue

            for side_direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                var neighbor: Vector3i = CardinalDirections.translate(coords, side_direction)
                if VectorUtils.manhattan_distance(neighbor, center) >= VectorUtils.manhattan_distance(coords, center) || to_dig.has(coords) || preexisting.has(coords):
                    var node_side: GridNodeSide = GridNodeSide.get_node_side(preexisting[coords], side_direction)
                    if node_side != null:
                        node_side.queue_free()

                    continue

                var node_side: GridNodeSide = GridNodeSide.get_node_side(preexisting[coords], side_direction)
                if node_side == null:
                    _add_side_to_node(preexisting[coords], side_direction, styles, level)

                if inside.has(neighbor):
                    var inv_side_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(side_direction)
                    node_side = GridNodeSide.get_node_side(inside[neighbor], inv_side_direction)
                    if node_side == null:
                        _add_side_to_node(inside[neighbor], inv_side_direction, styles, level)

        else:

            var node: GridNode = node_resource.instantiate()

            node.coordinates = coords
            node.name = "Node %s" % coords

            var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)
            var node_parent: Node3D = (
                GridLevelActions.get_or_add_elevation_parent(level, node.coordinates.y)
                if level_actions.organize_by_elevation else
                GridLevel.get_level_geometry_root(level)
            )

            _panel.add_grid_node(node)
            node_parent.add_child(node, true)

            node.global_position = new_position
            node.owner = level.get_tree().edited_scene_root

            for side_direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                var neighbor: Vector3i = CardinalDirections.translate(coords, side_direction)
                if VectorUtils.manhattan_distance(neighbor, center) >= VectorUtils.manhattan_distance(coords, center) || to_dig.has(neighbor) || preexisting.has(neighbor):
                    continue

                _add_side_to_node(node, side_direction, styles, level)

                if inside.has(neighbor):
                    var inv_side_direction: CardinalDirections.CardinalDirection = CardinalDirections.invert(side_direction)
                    var node_side: GridNodeSide = GridNodeSide.get_node_side(inside[neighbor], inv_side_direction)
                    if node_side == null:
                        _add_side_to_node(inside[neighbor], inv_side_direction, styles, level)

    EditorInterface.mark_scene_as_unsaved()
