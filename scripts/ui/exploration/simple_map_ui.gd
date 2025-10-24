extends Control
class_name SimpleMapUI

@export var line_color: Color
@export var player_color: Color
@export var ground_color: Color
@export var no_floor_color: Color
@export var feature_color: Color
@export var illusion_color: Color
@export var wall_color: Color

@export var cell_padding: float = 1
@export var player_marker_padding: float = 4

@export_range(4, 20) var wanted_columns: int = 10
@export_range(4, 20) var wanted_rows: int = 8

var _player: GridPlayerCore
var _seen: Array[Vector3i]
var _show_features: bool

func trigger_redraw(player: GridPlayerCore, seens_coordinates: Array[Vector3i], show_features: bool) -> void:
    _player = player
    _seen = seens_coordinates
    _show_features = show_features

    queue_redraw()

func _draw() -> void:
    if _player == null:
        return

    var area: Rect2 = get_rect()
    var center: Vector2 = area.get_center()

    var cell_length: float = min(area.size.x / wanted_columns, area.size.y / wanted_rows)
    var columns: int = floori(area.size.x / cell_length)
    var rows: int = floori(area.size.y / cell_length)
    var center_coords_position: Vector2 = Vector2(columns * 0.5, rows * 0.5)
    var cell: Vector2 = Vector2(cell_length - cell_padding * 2, cell_length - cell_padding * 2)

    var up_direction: CardinalDirections.CardinalDirection = _player.look_direction
    var right_direction: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(_player.look_direction, _player.down)[0]
    @warning_ignore_start("integer_division")
    var center_map_coords: Vector2i = Vector2i(columns / 2, rows / 2)
    @warning_ignore_restore("integer_division")

    var level: GridLevelCore = _player.get_level()

    var map_x_min: float = center.x - center_coords_position.x * cell_length
    var map_x_max: float = center.x + (columns - center_coords_position.x) * cell_length

    for row: int in range(1, rows):
        var map_y: float = center.y + (row - center_coords_position.y) * cell_length
        draw_line(Vector2(map_x_min, map_y), Vector2(map_x_max, map_y), line_color, 1)

    var map_y_min: float = center.y - center_coords_position.y * cell_length
    var map_y_max: float = center.y + (rows - center_coords_position.y) * cell_length

    for col: int in range(1, columns):
        var map_x: float = center.x + (col - center_coords_position.x) * cell_length
        draw_line(Vector2(map_x, map_y_min), Vector2(map_x, map_y_max), line_color, 1)

    var map_directions: Array[CardinalDirections.CardinalDirection] = CardinalDirections.orthogonals(_player.down)

    for row: int in range(rows):
        for col: int in range(columns):
            var game_coords: Vector3i = CardinalDirections.translate(
                CardinalDirections.translate(_player.coordinates(), up_direction, center_map_coords.y - row),
                right_direction,
                center_map_coords.x - col
            )
            if !_seen.has(game_coords):
                continue

            var node: GridNode = level.get_grid_node(game_coords)
            if node == null:
                continue

            var floor_state: GridNode.NodeSideState = node.has_side(_player.down) if node != null else GridNode.NodeSideState.NONE
            var color: Color
            var filled: bool = true
            match floor_state:
                GridNode.NodeSideState.SOLID:
                    color = ground_color
                GridNode.NodeSideState.ILLUSORY:
                    var seen_other_side: bool = _seen.has(CardinalDirections.translate(game_coords, _player.down))
                    color = illusion_color if seen_other_side else ground_color
                GridNode.NodeSideState.DOOR:
                    var floor_door: GridDoorCore = node.get_door(_player.down)
                    var open: bool = floor_door == null || floor_door.lock_state == GridDoorCore.LockState.OPEN
                    if _show_features:
                        color = no_floor_color if open else feature_color
                    else:
                        color = no_floor_color if open else wall_color
                _:
                    color = no_floor_color

            var rect: Rect2 = Rect2(
                Vector2(
                    center.x + (col - center_coords_position.x) * cell_length + cell_padding,
                    center.y + (row - center_coords_position.y) * cell_length + cell_padding,
                ),
                cell,
            )

            draw_rect(rect, color, filled, 2)

            var c1: Vector2 = rect.position
            var c2: Vector2 = rect.position + Vector2(cell.x, 0)
            var c3: Vector2 = rect.position + cell
            var c4: Vector2 = rect.position + Vector2(0, cell.y)
            var tile_center: Vector2 = rect.get_center()

            if _show_features:

                var ramp: GridRampCore = node.get_ramp(_player.down)
                var floor_below_ramp: bool = false
                if floor_state == GridNode.NodeSideState.NONE:
                    var down_neighbour: GridNode = level.get_grid_node(CardinalDirections.translate(game_coords, _player.down))
                    if down_neighbour != null:
                        ramp = down_neighbour.get_ramp(_player.down)
                        floor_below_ramp = true

                if ramp != null:
                    if ramp.upper_exit_direction == _player.look_direction:
                        draw_primitive(
                            [c4, c1, c2] if floor_below_ramp else [c2, c4, c3],
                            [feature_color],
                            [Vector2.ZERO],
                        )
                    elif ramp.upper_exit_direction == CardinalDirections.invert(_player.look_direction):
                        draw_primitive(
                            [c2, c4, c3] if floor_below_ramp else [c4, c1, c2],
                            [feature_color],
                            [Vector2.ZERO],
                        )
                    elif ramp.upper_exit_direction == CardinalDirections.yaw_ccw(_player.look_direction, _player.down)[0]:
                        draw_primitive(
                            [c3, c4, c1] if floor_below_ramp else [c1, c3, c2],
                            [feature_color],
                            [Vector2.ZERO],
                        )
                    else:
                        draw_primitive(
                            [c1, c3, c2] if floor_below_ramp else [c3, c4, c1],
                            [feature_color],
                            [Vector2.ZERO],
                        )

                var teleporter: GridTeleporter = node.get_active_teleporter(_player.down)
                if teleporter != null:
                    var offset: Vector2 = cell * 0.25
                    print_debug("Teleporter at %s with radius %s" % [tile_center, offset])

                    draw_polyline(
                        [
                            tile_center + offset,
                            tile_center + offset.rotated(-2 * PI * 1 / 5),
                            tile_center + offset.rotated(-2 * PI * 2 / 5),
                            tile_center + offset.rotated(-2 * PI * 3 / 5),
                            tile_center + offset.rotated(-2 * PI * 4 / 5),
                            tile_center + offset,
                        ],
                        feature_color,
                        3,
                    )

            for direction: CardinalDirections.CardinalDirection in map_directions:
                if _show_features:
                    var wall_door: GridDoorCore = node.get_door(direction)

                    if wall_door != null:
                        var open: bool = wall_door.lock_state == GridDoorCore.LockState.OPEN
                        const open_fraction: float = 0.15
                        if _player.look_direction == direction:
                            if open:
                                draw_line(c1, c1.lerp(c2, open_fraction), feature_color, 2)
                                draw_line(c2.lerp(c1, open_fraction), c2, feature_color, 2)
                            else:
                                draw_line(c1, c2, feature_color, 2)
                        elif _player.look_direction == CardinalDirections.invert(direction):
                            if open:
                                draw_line(c3, c3.lerp(c4, open_fraction), feature_color, 2)
                                draw_line(c4.lerp(c3, open_fraction), c4, feature_color, 2)
                            else:
                                draw_line(c3, c4, feature_color, 2)
                        elif _player.look_direction == CardinalDirections.yaw_ccw(direction, _player.down)[0]:
                            if open:
                                draw_line(c2, c2.lerp(c3, open_fraction), feature_color, 2)
                                draw_line(c3.lerp(c2, open_fraction), c3, feature_color, 2)
                            else:
                                draw_line(c2, c3, feature_color, 2)
                        else:
                            if open:
                                draw_line(c1, c1.lerp(c4, open_fraction), feature_color, 2)
                                draw_line(c4.lerp(c1, open_fraction), c4, feature_color, 2)
                            else:
                                draw_line(c1, c4, feature_color, 2)

                match node.has_side(direction):
                    GridNode.NodeSideState.SOLID:
                        if _player.look_direction == direction:
                            draw_line(c1, c2, wall_color, 2)
                        elif _player.look_direction == CardinalDirections.invert(direction):
                            draw_line(c3, c4, wall_color, 2)
                        elif _player.look_direction == CardinalDirections.yaw_ccw(direction, _player.down)[0]:
                            draw_line(c2, c3, wall_color, 2)
                        else:
                            draw_line(c1, c4, wall_color, 2)
                    GridNode.NodeSideState.ILLUSORY:
                        var seen_other_side: bool = _seen.has(CardinalDirections.translate(game_coords, direction))
                        if _player.look_direction == direction:
                            draw_line(c1, c2, illusion_color if seen_other_side else wall_color, 2)
                        elif _player.look_direction == CardinalDirections.invert(direction):
                            draw_line(c3, c4, illusion_color if seen_other_side else wall_color, 2)
                        elif _player.look_direction == CardinalDirections.yaw_ccw(direction, _player.down)[0]:
                            draw_line(c2, c3, illusion_color if seen_other_side else wall_color, 2)
                        else:
                            draw_line(c1, c4, illusion_color if seen_other_side else wall_color, 2)

            var door: GridDoorCore = node.get_door(_player.down)
            if door != null && door.lock_state == GridDoorCore.LockState.OPEN && _show_features:
                draw_polyline(
                    [
                        c1.lerp(tile_center, 0.15),
                        c2.lerp(tile_center, 0.15),
                        c3.lerp(tile_center, 0.15),
                        c4.lerp(tile_center, 0.15),
                        c1.lerp(tile_center, 0.15),
                    ],
                    feature_color,
                    2,
                )

            if game_coords == _player.coordinates():
                var player_marker_rect: Rect2 = RectUtils.shrink(rect, player_marker_padding, player_marker_padding, true)
                var player_center: Vector2 = player_marker_rect.get_center()
                var top: Vector2 = player_center - Vector2(0, player_marker_rect.size.y * 0.5)
                var lower_left: Vector2 = player_center + player_marker_rect.size * 0.5
                var lower_right: Vector2 = lower_left - Vector2(player_marker_rect.size.x, 0)
                draw_polyline([
                    top,
                    lower_right,
                    lower_left,
                    top,
                    player_center,
                    lower_right,
                    lower_left,
                    player_center,
                ], player_color, 1)

func zoom_in() -> void:
    wanted_columns = clamp(wanted_columns - 1, 4, 20)
    @warning_ignore_start("integer_division")
    wanted_rows = wanted_columns * 8 / 10
    print_debug("zoom in to: %s x %s" % [wanted_columns, wanted_rows])
    queue_redraw()

func zoom_out() -> void:
    wanted_columns = clamp(wanted_columns + 1, 4, 20)
    wanted_rows = wanted_columns * 8 / 10
    print_debug("zoom out to: %s x %s" % [wanted_columns, wanted_rows])
    @warning_ignore_restore("integer_division")
    queue_redraw()
