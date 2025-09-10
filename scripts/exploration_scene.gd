extends Node
class_name ExplorationScene

static var instance: ExplorationScene

@export var settings: GameSettings

@export var subviewport: Control
@export var exploration_ui: Control

var _view_split: float

var level: GridLevel
var level_ready: bool:
    get():
        return level != null

func _enter_tree() -> void:
    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null

func _ready() -> void:
    _view_split = subviewport.anchor_right

    if settings.accessibility.on_update_handedness.connect(_handle_handedness_change) != OK:
        push_error("Failed to connect on update handedness")

    _handle_handedness_change(AccessibilitySettings.handedness)

    if __SignalBus.on_robot_death.connect(_handle_robot_death) != OK:
        push_error("Failed to connect to robot death")

    _disable_robot_death_effect()

func _disable_robot_death_effect() -> void:
    var shader: ShaderMaterial = subviewport.material
    shader.set_shader_parameter("pixels", -1)
    # subviewport.set_instance_shader_parameter("pixels", -1)
    print_debug("[Exploration Scene] Disabled pixelating effect")

func _handle_robot_death(_robot: Robot) -> void:
    var shader: ShaderMaterial = subviewport.material
    print_debug("[Exploration Scene] Produce signal loss pixelating effect")
    shader.set_shader_parameter("pixels", 200)
    shader.set_shader_parameter("max_lerp", 0.1)

    var duration: float = 2.0

    var tween: Tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    tween.set_parallel()

    tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("max_lerp", progress)
            ,
        0.1,
        0.8,
        duration
    )

    tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("min_lerp", progress)
            ,
        0.0,
        0.6,
        duration
    )

    tween.tween_method(
        func (progress: int) -> void:
            shader.set_shader_parameter("pixels", progress)
            ,
        100,
        5,
        duration
    ).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    @warning_ignore_restore("return_value_discarded")

static func find_exploration_scene(current: Node, inclusive: bool = true) ->  ExplorationScene:
    if inclusive && current is ExplorationScene:
        return current as ExplorationScene

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is ExplorationScene:
        return parent as ExplorationScene

    return find_exploration_scene(parent, false)

func _handle_handedness_change(handedness: AccessibilitySettings.Handedness) -> void:
    match handedness:
        AccessibilitySettings.Handedness.LEFT:
            subviewport.anchor_left = 1 - _view_split
            subviewport.anchor_right = 1
            exploration_ui.anchor_left = 0
            exploration_ui.anchor_right = 1 - _view_split
        AccessibilitySettings.Handedness.RIGHT:
            subviewport.anchor_left = 0
            subviewport.anchor_right = _view_split
            exploration_ui.anchor_left = _view_split
            exploration_ui.anchor_right = 1
