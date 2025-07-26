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

func _ready() -> void:
    # TODO: Handle upgrade skills
    var skill_level: int = exploration_ui.level.player.robot.get_skill_level(RobotAbility.SKILL_SONAR)
    sonar_root.visible = skill_level > 0
    sonar_label.text = "SNR-100 Mk %s" % IntUtils.to_roman(skill_level)

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
        _calculate_detections()
        queue_redraw()

var detect_dist: int
var facing_detected: bool

func _calculate_detections() -> void:
    var level: GridLevel = exploration_ui.level
    var player_coords: Vector3i = level.player.coordinates()

    for entity: GridEntity in level.grid_entities:
        if entity == level.player:
            continue

        var coords: Vector3i = entity.coordinates()

        if VectorUtils.manhattan_distance(player_coords, coords) > detection_range:
            continue


const BASE_SIGNAL_HEIGHT: float = 0.2
const SIGNAL_BASE_NOISE: float = 0.1

func _get_signal_strength(progress: float) -> float:
    if detect_dist < 0:
        return max(0, BASE_SIGNAL_HEIGHT + randf_range(-SIGNAL_BASE_NOISE, SIGNAL_BASE_NOISE))
    return 0
