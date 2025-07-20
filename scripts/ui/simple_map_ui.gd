extends Control
class_name SimpleMapUI

@export
var line_color: Color

@export
var ground_color: Color

@export
var no_floor_color: Color

@export
var exploration_ui: ExplorationUI

@export
var cell_padding: float = 1

@export
var player_marker_padding: float = 4

@export_range(4, 20)
var wanted_columns: int = 10

@export_range(4, 20)
var wanted_rows: int = 8

@export_range(5, 100)
var memory_size: int = 30

var _seen: Array[Vector3i]
var _player: GridPlayer
var _last_seen_idx: int

func _draw() -> void:
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

    var level: GridLevel = _player.get_level()

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
            var color: Color = ground_color if node != null && node.get_grid_anchor(_player.down) != null else no_floor_color
            var rect: Rect2 = Rect2(
                Vector2(
                    center.x + (col - center_coords_position.x) * cell_length + cell_padding,
                    center.y + (row - center_coords_position.y) * cell_length + cell_padding,
                ),
                cell,
            )

            draw_rect(rect, color, true)

            if game_coords == _player.coordinates():
                draw_rect(RectUtils.shrink(rect, player_marker_padding, player_marker_padding, true), line_color, false, 1)

    print_debug("Map redrawn")


func _ready() -> void:
    if exploration_ui.level.on_change_player.connect(_connect_new_player) != OK:
        push_error("Failed to connect new player")

    _connect_new_player()
    _handle_move_end(_player)

func _connect_new_player() -> void:
    _player = exploration_ui.level.player
    if _player.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect on move end")

    print_debug("Connected %s to map" % _player)

func _handle_move_end(_entity: GridEntity) -> void:
    var coords: Vector3i = _entity.coordinates()
    _enter_new_coordinates(coords)

    if _player.get_grid_node().may_exit(_player, _player.look_direction):
        coords = CardinalDirections.translate(coords, _player.look_direction)
        _enter_new_coordinates(coords)

    queue_redraw()

func _enter_new_coordinates(coords: Vector3i) -> void:
    if !_seen.has(coords):
        if _seen.size() < memory_size:
            _seen.append(coords)
            _last_seen_idx = _seen.size() - 1
        else:
            _last_seen_idx += 1
            _last_seen_idx %= mini(memory_size, _seen.size())
            _seen[_last_seen_idx] = coords
