@tool
extends VBoxContainer
class_name GridLevelManipulator

@export
var panel: GridLevelDiggerPanel

@export
var node_type_label: Label

@export
var coordinates_label: Label

@export
var sync_position_btn: Button

@export
var infer_coordinates_btn: Button

@export
var style: GridLevelStyle

@export
var remove_neighbour_in_front_button: Button

@export
var add_wall_button: Button

@export
var remove_wall_button: Button

@export
var remove_neighbour_up_button: Button

@export
var add_ceiling_button: Button

@export
var remove_ceiling_button: Button

@export
var remove_neighbour_down_button: Button

@export
var add_floor_button: Button

@export
var remove_floor_button: Button

func _ready() -> void:
    style.on_style_updated.connect(_on_style_update)
    panel.node_digger.on_new_lookdirection.connect(sync)
    _on_style_update()

var _may_add_wall_style: bool
var _has_wall: bool

var _may_add_ceiling_style: bool
var _has_ceiling: bool

var _may_add_floor_style: bool
var _has_floor: bool

func _on_style_update() -> void:
    _may_add_wall_style = style.get_wall_resource() != null
    _may_add_ceiling_style = style.get_ceiling_resource() != null
    _may_add_floor_style = style.get_floor_resource() != null

    add_ceiling_button.disabled = !_may_add_ceiling_style || _has_ceiling
    add_floor_button.disabled = !_may_add_floor_style || _has_floor
    add_wall_button.disabled = !_may_add_wall_style || _has_wall

func sync() -> void:
    var node: GridNode = panel.get_grid_node()
    _sync_node_neibours_buttons(node)
    _sync_node_side_buttons(node)

    if panel.inside_level:
        var coords: Vector3i = panel.coordinates
        var coords_have_node: bool = panel.get_grid_node_at(coords) != null

        if coords_have_node:
            node_type_label.text = "Node"

            sync_position_btn.visible = true
            infer_coordinates_btn.visible = true
        else:
            node_type_label.text = "[EMPTY]"

            sync_position_btn.visible = false
            infer_coordinates_btn.visible = false

        coordinates_label.text = "%s" % coords
        coordinates_label.visible = true

    else:
        node_type_label.text = "[NOT IN LEVEL]"
        sync_position_btn.visible = false
        infer_coordinates_btn.visible = false
        coordinates_label.visible = false

func _sync_node_side_buttons(node: GridNode) -> void:
    var forward: CardinalDirections.CardinalDirection = panel.node_digger.look_direction
    var has_node: bool = node != null
    var ceiling_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP)) if has_node else null
    var floor_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN)) if has_node else null
    var wall_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, forward)) if has_node else null

    var _ceiling: GridNodeSide = GridNodeSide.get_node_side(node, CardinalDirections.CardinalDirection.UP) if has_node else null
    _has_ceiling = _ceiling != null && _ceiling.anchor != null
    if !_has_ceiling && ceiling_neighbour != null:
        _ceiling = GridNodeSide.get_node_side(ceiling_neighbour, CardinalDirections.CardinalDirection.DOWN)
        _has_ceiling = _ceiling != null && _ceiling.negative_anchor != null

    add_ceiling_button.disabled = !_may_add_ceiling_style || _has_ceiling || !has_node
    print_debug("%s %s %s" % [_may_add_ceiling_style, _has_ceiling, has_node])
    remove_ceiling_button.disabled = !_has_ceiling

    var _floor: GridNodeSide = GridNodeSide.get_node_side(node, CardinalDirections.CardinalDirection.DOWN) if has_node else null
    _has_floor = _floor != null && _floor.anchor != null
    if !_has_floor && floor_neighbour != null:
        _floor = GridNodeSide.get_node_side(floor_neighbour, CardinalDirections.CardinalDirection.UP)
        _has_floor = _floor != null && _floor.negative_anchor != null

    add_floor_button.disabled = !_may_add_floor_style || _has_floor || !has_node
    remove_floor_button.disabled = !_has_floor

    var _wall: GridNodeSide = GridNodeSide.get_node_side(node, forward) if has_node else null
    _has_wall = _wall != null && _wall.anchor != null
    if !_has_wall && wall_neighbour != null:
        _wall = GridNodeSide.get_node_side(wall_neighbour, CardinalDirections.invert(forward))
        _has_wall = _wall != null && _wall.negative_anchor != null

    add_wall_button.disabled = !_may_add_wall_style || _has_wall || !has_node
    remove_wall_button.disabled = !_has_wall

func _sync_node_neibours_buttons(node: GridNode) -> void:
    var has_up: bool =  node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP)) != null
    var has_down: bool = node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN)) != null
    var has_forward: bool = node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, panel.node_digger.look_direction)) != null

    remove_neighbour_down_button.disabled = !has_down
    remove_neighbour_up_button.disabled = !has_up
    remove_neighbour_in_front_button.disabled = !has_forward

func _on_sync_position_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, node.coordinates)

        if new_position != node.global_position:
            panel.undo_redo.create_action("GridLevelDigger: Sync node position")

            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

            panel.undo_redo.commit_action()

func _on_infer_coordinates_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var level: GridLevel = panel.get_level()

    if node != null && level != null:
        var new_coordinates: Vector3i = GridLevel.node_coordinates_from_position(level, node)
        var new_position: Vector3 = GridLevel.node_position_from_coordinates(level, new_coordinates)

        if new_coordinates != node.coordinates || new_position != node.global_position:

            panel.undo_redo.create_action("GridLevelDigger: Infer node coordinates")

            panel.undo_redo.add_do_property(node, "global_position", new_position)
            panel.undo_redo.add_undo_property(node, "global_position", node.global_position)

            panel.undo_redo.add_do_property(node, "coordinates", new_coordinates)
            panel.undo_redo.add_undo_property(node, "coordinates", node.coordinates)

            panel.undo_redo.add_do_property(node, "name",  "Node %s" % new_coordinates)
            panel.undo_redo.add_undo_property(node, "name", node.name)

            panel.undo_redo.commit_action()

            panel.coordinates = new_coordinates


# Removing neighbours
func _on_remove_node_in_front_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, panel.node_digger.look_direction))
    if node != null:
        panel.remove_grid_node(node)
        node.queue_free()

func _on_remove_node_up_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, CardinalDirections.CardinalDirection.UP))
    if node != null:
        panel.remove_grid_node(node)
        node.queue_free()

func _on_remove_node_down_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, CardinalDirections.CardinalDirection.DOWN))
    if node != null:
        panel.remove_grid_node(node)
        node.queue_free()

# Adding sides
func _on_add_wall_in_front_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, panel.node_digger.look_direction))
    panel.node_digger.add_node_side(
        style.get_wall_resource(),
        panel.level,
        node,
        neighbor,
        panel.node_digger.look_direction,
        true,
    )

func _on_add_floor_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN))
    panel.node_digger.add_node_side(
        style.get_floor_resource(),
        panel.level,
        node,
        neighbor,
        CardinalDirections.CardinalDirection.DOWN,
        true,
    )

func _on_add_ceiling_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP))
    panel.node_digger.add_node_side(
        style.get_ceiling_resource(),
        panel.level,
        node,
        neighbor,
        CardinalDirections.CardinalDirection.UP,
        true,
    )

# Remove sidde

func _on_remove_ceiling_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, CardinalDirections.CardinalDirection.UP):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.CardinalDirection.DOWN)

func _on_remove_floor_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, CardinalDirections.CardinalDirection.DOWN):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.CardinalDirection.UP)

func _on_remove_wall_in_front_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, panel.node_digger.look_direction):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, panel.node_digger.look_direction))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.invert(panel.node_digger.look_direction))
