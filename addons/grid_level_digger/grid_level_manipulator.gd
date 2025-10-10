@tool
extends VBoxContainer
class_name GridLevelManipulator

@export var panel: GridLevelDiggerPanel

@export var node_type_label: Label
@export var coordinates_label: Label
@export var sync_position_btn: Button
@export var infer_coordinates_btn: Button
@export var style: GridLevelStyle
@export var remove_neighbour_in_front_button: Button
@export var swap_wall_button: Button
@export var style_wall_button: Button
@export var add_wall_button: Button
@export var remove_wall_button: Button
@export var remove_neighbour_up_button: Button
@export var swap_ceiling_button: Button
@export var add_ceiling_button: Button
@export var remove_ceiling_button: Button
@export var remove_neighbour_down_button: Button
@export var swap_floor_button: Button
@export var add_floor_button: Button
@export var remove_floor_button: Button
@export var own_nav: GridLevelNav

func _ready() -> void:
    style.on_style_updated.connect(_on_style_update)
    if panel.node_digger.nav.on_update_nav.connect(_sync) != OK:
        push_error("Failed to connect update nav")
    if own_nav.on_update_nav.connect(_sync) != OK:
        push_error("Failed to connect update nav")

    _on_style_update()

func _exit_tree() -> void:
    if _style_window != null:
        _style_window.queue_free()
        _style_window = null

var _may_add_wall_style: bool
var _has_wall: bool

var _may_add_ceiling_style: bool
var _has_ceiling: bool

var _may_add_floor_style: bool
var _has_floor: bool
var _style_window: Window

func _on_style_update() -> void:
    _may_add_wall_style = style.get_wall_resource() != null
    _may_add_ceiling_style = style.get_ceiling_resource() != null
    _may_add_floor_style = style.get_floor_resource() != null

    add_ceiling_button.disabled = !_may_add_ceiling_style || _has_ceiling
    add_floor_button.disabled = !_may_add_floor_style || _has_floor
    add_wall_button.disabled = !_may_add_wall_style || _has_wall

    _sync_node_side_buttons(panel.get_focus_node(), panel.look_direction)

func sync() -> void:
    _sync(panel.coordinates, panel.look_direction)

func _sync(coordinates: Vector3i, look_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.NONE) -> void:
    var node: GridNode = panel.get_grid_node_at(coordinates)
    _sync_node_neibours_buttons(node, look_direction)
    _sync_node_side_buttons(node, look_direction)

    if panel.inside_level:
        var coords_have_node: bool = node != null

        if coords_have_node:
            node_type_label.text = "Node"

            sync_position_btn.visible = true
            infer_coordinates_btn.visible = true
        else:
            node_type_label.text = "[EMPTY]"

            sync_position_btn.visible = false
            infer_coordinates_btn.visible = false

        coordinates_label.text = "%s" % coordinates
        coordinates_label.visible = true

    else:
        node_type_label.text = "[NOT IN LEVEL]"
        sync_position_btn.visible = false
        infer_coordinates_btn.visible = false
        coordinates_label.visible = false

func _sync_node_side_buttons(node: GridNode, look_direction: CardinalDirections.CardinalDirection) -> void:
    var forward: CardinalDirections.CardinalDirection = look_direction
    var has_node: bool = node != null
    var ceiling_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP)) if has_node else null
    var floor_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN)) if has_node else null
    var wall_neighbour: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, forward)) if has_node else null

    var _ceiling: GridNodeSide = GridNodeSide.get_node_side(node, CardinalDirections.CardinalDirection.UP) if has_node else null
    swap_ceiling_button.disabled = _ceiling == null || !_may_add_ceiling_style || style.get_ceiling_resource_path() == _ceiling.scene_file_path
    _has_ceiling = _ceiling != null && _ceiling.anchor != null
    #if !_has_ceiling && ceiling_neighbour != null:
    #    _ceiling = GridNodeSide.get_node_side(ceiling_neighbour, CardinalDirections.CardinalDirection.DOWN)
    #    _has_ceiling = _ceiling != null && _ceiling.negative_anchor != null

    add_ceiling_button.disabled = !_may_add_ceiling_style || _has_ceiling || !has_node
    remove_ceiling_button.disabled = !_has_ceiling

    var _floor: GridNodeSide = GridNodeSide.get_node_side(node, CardinalDirections.CardinalDirection.DOWN) if has_node else null
    swap_floor_button.disabled = _floor == null || !_may_add_floor_style || style.get_floor_resource_path() == _floor.scene_file_path
    _has_floor = _floor != null && _floor.anchor != null
    # if !_has_floor && floor_neighbour != null:
    #    _floor = GridNodeSide.get_node_side(floor_neighbour, CardinalDirections.CardinalDirection.UP)
    #    _has_floor = _floor != null && _floor.negative_anchor != null

    add_floor_button.disabled = !_may_add_floor_style || _has_floor || !has_node
    remove_floor_button.disabled = !_has_floor

    var _wall: GridNodeSide = GridNodeSide.get_node_side(node, forward) if has_node else null
    swap_wall_button.disabled = _wall == null || !_may_add_wall_style || style.get_wall_resource_path() == _wall.scene_file_path
    style_wall_button.disabled = _wall == null
    _has_wall = _wall != null && _wall.anchor != null
    # if !_has_wall && wall_neighbour != null:
    #    _wall = GridNodeSide.get_node_side(wall_neighbour, CardinalDirections.invert(forward))
    #    _has_wall = _wall != null && _wall.negative_anchor != null

    add_wall_button.disabled = !_may_add_wall_style || _has_wall || !has_node
    remove_wall_button.disabled = !_has_wall

func _sync_node_neibours_buttons(node: GridNode, look_direction: CardinalDirections.CardinalDirection) -> void:
    var has_up: bool =  node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP)) != null
    var has_down: bool = node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN)) != null
    var has_forward: bool = node != null && panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, look_direction)) != null

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

            EditorInterface.mark_scene_as_unsaved()

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

            EditorInterface.mark_scene_as_unsaved()

# Removing neighbours
func _on_remove_node_in_front_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, panel.look_direction))
    if node != null:
        print_debug("[GLD Manipulator] Removing in front %s" % node.get_node_and_resource("."))
        panel.remove_grid_node(node)
        node.queue_free()
        EditorInterface.mark_scene_as_unsaved()

func _on_remove_node_up_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, CardinalDirections.CardinalDirection.UP))
    if node != null:
        print_debug("[GLD Manipulator] Removing up %s" % node.get_node_and_resource("."))
        panel.remove_grid_node(node)
        node.queue_free()
        EditorInterface.mark_scene_as_unsaved()

func _on_remove_node_down_pressed() -> void:
    var node: GridNode = panel.get_grid_node_at(CardinalDirections.translate(panel.get_focus_node().coordinates, CardinalDirections.CardinalDirection.DOWN))
    if node != null:
        print_debug("[GLD Manipulator] Removing down %s" % node.get_node_and_resource("."))
        panel.remove_grid_node(node)
        node.queue_free()
        EditorInterface.mark_scene_as_unsaved()

# Adding sides
func _on_add_wall_in_front_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, panel.look_direction))
    panel.node_digger.add_node_side(
        style.get_wall_resource(),
        panel.level,
        node,
        panel.look_direction,
        true,
    )
    _sync_node_side_buttons(node, panel.look_direction)

func _on_add_floor_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN))
    panel.node_digger.add_node_side(
        style.get_floor_resource(),
        panel.level,
        node,
        CardinalDirections.CardinalDirection.DOWN,
        true,
    )
    _sync_node_side_buttons(node, panel.look_direction)

func _on_add_ceiling_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP))
    panel.node_digger.add_node_side(
        style.get_ceiling_resource(),
        panel.level,
        node,
        CardinalDirections.CardinalDirection.UP,
        true,
    )
    _sync_node_side_buttons(node, panel.look_direction)

# Remove sidde

func _on_remove_ceiling_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, CardinalDirections.CardinalDirection.UP):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.UP))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.CardinalDirection.DOWN)
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, panel.look_direction)

func _on_remove_floor_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, CardinalDirections.CardinalDirection.DOWN):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, CardinalDirections.CardinalDirection.DOWN))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.CardinalDirection.UP)
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, panel.look_direction)

func _on_remove_wall_in_front_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    if !panel.node_digger.remove_node_side(node, panel.look_direction):
        var neighbor: GridNode = panel.get_grid_node_at(CardinalDirections.translate(node.coordinates, panel.look_direction))
        panel.node_digger.remove_node_side(neighbor, CardinalDirections.invert(panel.look_direction))
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, panel.look_direction)

func _on_swap_wall_scene_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    panel.node_digger.swap_node_side_for_style(node, panel.look_direction)
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, panel.look_direction)

func _on_swap_floor_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    panel.node_digger.swap_node_side_for_style(node, CardinalDirections.CardinalDirection.DOWN)
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, CardinalDirections.CardinalDirection.DOWN)

func _on_swap_ceiling_pressed() -> void:
    var node: GridNode = panel.get_focus_node()
    panel.node_digger.swap_node_side_for_style(node, CardinalDirections.CardinalDirection.UP)
    await get_tree().create_timer(0.1).timeout
    _sync_node_side_buttons(node, CardinalDirections.CardinalDirection.UP)

func _on_style_wall_in_front_pressed() -> void:
    _show_style_window(panel.look_direction)

func _show_style_window(direction: CardinalDirections.CardinalDirection) -> void:
    var grid_node: GridNode = panel.get_grid_node()
    var side: GridNodeSide = GridNodeSide.get_node_side(grid_node, direction)
    if side == null:
        return

    if _style_window != null:
        _style_window.queue_free()

    _style_window = Window.new()
    _style_window.close_requested.connect(
        func() -> void:
            _style_window.queue_free()
            _style_window = null
    )
    _style_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS
    _style_window.popup_window = true

    _style_window.title = "Style Wall"
    var scene: PackedScene = load("res://addons/grid_level_digger/controls/node_side_styler.tscn")
    var styler: GridLevelNodeSideStyler = scene.instantiate()

    _style_window.add_child(styler)

    styler.configure(side, panel)

    EditorInterface.popup_dialog_centered(_style_window, Vector2i(600, 800))

    print_debug("[GLD Manipulator] Created style window!")
