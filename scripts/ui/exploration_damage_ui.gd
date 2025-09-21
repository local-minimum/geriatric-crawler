extends Control
class_name ExplorationDamageUI

@export var stencil_fade_in_duration: float = 0.3
@export var stencil_fade_out_duration: float = 0.2
@export var noise_fade_in_duration: float = 0.4
@export var noise_fade_out_duration: float = 0.6

var _stencil_tween: Tween
var _noise_tween: Tween

func _enter_tree() -> void:
    if __SignalBus.on_robot_exploration_damage.connect(_handle_robot_exploration_damage) != OK:
        push_error("Failed to connect robot exploration damage")

func _ready() -> void:
    visible = false

func _handle_robot_exploration_damage(_robot: Robot, _damage: int) -> void:
    visible = true
    var shader: ShaderMaterial = material
    shader.set_shader_parameter("stencil_progress", 0.0)
    shader.set_shader_parameter("noise_bias", 1.0)

    if _stencil_tween != null && _stencil_tween.is_running():
        _stencil_tween.kill()
    if _noise_tween != null && _noise_tween.is_running():
        _noise_tween.kill()

    _stencil_tween = get_tree().create_tween()
    _noise_tween = _stencil_tween.parallel()

    @warning_ignore_start("return_value_discarded")
    _stencil_tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("stencil_progress", progress)
            ,
        0.0,
        1.0,
        stencil_fade_in_duration,
    ).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

    _stencil_tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("stencil_progress", progress)
            ,
        1.0,
        0.0,
        stencil_fade_out_duration,
    ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)

    _noise_tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("noise_bias", progress)
            ,
        1.0,
        0.9,
        noise_fade_in_duration,
    ).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

    _noise_tween.tween_method(
        func (progress: float) -> void:
            shader.set_shader_parameter("noise_bias", progress)
            ,
        0.9,
        1.0,
        noise_fade_out_duration,
    ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


    if noise_fade_in_duration + noise_fade_out_duration > stencil_fade_in_duration + stencil_fade_out_duration:
        _noise_tween.connect(
            "finished",
            func () -> void:
                visible = false
        )
    else:
        _stencil_tween.connect(
            "finished",
            func () -> void:
                visible = false
        )

    @warning_ignore_restore("return_value_discarded")
    _stencil_tween.play()
