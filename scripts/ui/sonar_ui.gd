extends Control
class_name SonarUI

@export
var sonar_root: Control

@export
var sonar_label: Label

@export
var exploration_ui: ExplorationUI

@export_range(4, 128)
var bars: int = 12

@export_range(0, 20)
var bar_width: float = 1

@export
var bar_color: Color

@export_range(0, 10)
var detection_range: int = 5

@export
var update_frequency_msec: int = 200

@export_range(0, 20)
var signal_bar_progress: float = 5

@export_range(0, 20)
var look_direction_signal_bar_progress: float = 11

@export_range(0, 1)
var signal_speed: float = 0.001

@export_range(0, 1)
var look_direction_signal_speed: float = 0.03

var _astar: AStar3D
var _astar_lookup: Dictionary[Vector3i, int]

func _ready() -> void:
    # TODO: Handle upgrade skills
    var skill_level: int = exploration_ui.level.player.robot.get_skill_level(RobotAbility.SKILL_SONAR)
    sonar_root.visible = skill_level > 0
    sonar_label.text = "SNR-100 Mk %s" % IntUtils.to_roman(skill_level)
    _astar = AStar3D.new()
    _populate_astar()

func _populate_astar() -> void:
    var level: GridLevel = exploration_ui.level
    var player: GridEntity = exploration_ui.level.player

    for g_node: GridNode in level.nodes():
        var coords: Vector3i = g_node.coordinates
        var id: int = _get_or_add_astar_id(coords)

        for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
            if g_node.may_exit(player, direction):
                var neighbour_coords: Vector3i = CardinalDirections.translate(coords, direction)
                var neighbour: GridNode = level.get_grid_node(neighbour_coords)
                if neighbour == null || !neighbour.may_enter(player, g_node, direction, CardinalDirections.CardinalDirection.NONE, true):
                    continue

                var neighbour_id: int = _get_or_add_astar_id(neighbour_coords)
                _astar.connect_points(id, neighbour_id, false)

func _get_or_add_astar_id(coords: Vector3i) -> int:
    if _astar_lookup.has(coords):
        return _astar_lookup[coords]

    var id: int = _astar.get_available_point_id()
    _astar.add_point(id, coords)
    _astar_lookup[coords] = id
    return id

func _draw() -> void:
    var r: Rect2 = get_rect()
    var height: float = r.size.y * -1
    var base_y: float = r.end.y
    var start_x: float = r.position.x
    var width: float = r.size.x

    for bar: int in range(bars):
        var progress: float = (bar as float) / bars
        var x: float = start_x + bar_width * 0.5 + progress * width
        draw_line(
            Vector2(x, base_y),
            Vector2(x, base_y + height * _get_signal_strength(progress)),
            bar_color,
            bar_width)


    next_update = Time.get_ticks_msec() + update_frequency_msec

var next_update: int

func _process(_delta: float) -> void:
    if is_visible_in_tree() && Time.get_ticks_msec() > next_update:
        _calculate_detection()
        queue_redraw()

var detect_dist: int
var facing_detected: bool

func _calculate_detection() -> void:
    var level: GridLevel = exploration_ui.level
    var player_coords: Vector3i = level.player.coordinates()
    var look_vector: Vector3i = CardinalDirections.direction_to_look_vector(level.player.look_direction)

    detect_dist = -1

    for entity: GridEntity in level.grid_entities:
        if entity == level.player || !entity.visible:
            continue

        var coords: Vector3i = entity.coordinates()

        if coords == player_coords:
            detect_dist = 0
            facing_detected = true
            break

        if VectorUtils.manhattan_distance(player_coords, coords) > detection_range:
            continue

        var d: int = _astar.get_point_path(_get_or_add_astar_id(player_coords), _get_or_add_astar_id(coords)).size()
        if d > detection_range:
            continue

        if detect_dist < 0 || d < detect_dist:
            detect_dist = d
            facing_detected = look_vector == VectorUtils.primary_direction(coords - player_coords)

    if exploration_ui.level.player.robot.get_skill_level(RobotAbility.SKILL_SONAR) < 2:
        return

    # TODO: Detect secrets if lvl 2

const BASE_SIGNAL_HEIGHT: float = 0.1
const SIGNAL_BASE_NOISE: float = 0.02
const DISTANS_SIGNAL_MAGNITUDE: float = 0.5
const LOOK_SIGNAL_MAGNITUDE: float = 0.3


func _get_signal_strength(progress: float) -> float:
    var noise: float = randf_range(-SIGNAL_BASE_NOISE, SIGNAL_BASE_NOISE)
    if detect_dist < 0:
        return max(0, BASE_SIGNAL_HEIGHT + noise)

    var s: float = max(0, BASE_SIGNAL_HEIGHT + noise)
    var r: float = detection_range
    s += max(0, sin(progress * signal_bar_progress + Time.get_ticks_msec() * signal_speed) * (r - detect_dist) / r * DISTANS_SIGNAL_MAGNITUDE)
    if facing_detected:
        s *= sin(progress * look_direction_signal_bar_progress + Time.get_ticks_msec() * look_direction_signal_speed) * LOOK_SIGNAL_MAGNITUDE + 1

    return clamp(s, 0, 1)
