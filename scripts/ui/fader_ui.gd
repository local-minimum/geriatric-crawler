extends Node
class_name FaderUI

enum FadeTarget { EXPLORATION_VIEW }

@export var target: FadeTarget = FadeTarget.EXPLORATION_VIEW

static func name_target(fade_target: FadeTarget) -> String:
    match fade_target:
        FadeTarget.EXPLORATION_VIEW: return "Exploration View"
        _:
            push_warning("Unknown target %s" % name_target)
            return "Unknown Target"

@export var ease_duration: float = 0.4

@export var faded_duration: float = 0.1

@export var color_rect: ColorRect

@export var solid_color: Color

@export var transparent_color: Color

static var _faders: Dictionary[FadeTarget, FaderUI] = {}

static func fade(
    fade_target: FadeTarget = FadeTarget.EXPLORATION_VIEW,
    on_midways: Variant = null,
    on_complete: Variant = null,
    color: Variant = null,
) -> void:
    var fader: FaderUI = _faders.get(fade_target)
    if fader == null:
        push_warning("Lacking fader %s" % name_target(fade_target))
    else:
        fader._fade(on_midways, on_complete, color)

var tween: Tween

func _ready() -> void:
    _faders[target] = self
    if color_rect != null:
        color_rect.visible = false
        color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fade(on_midways: Variant = null, on_complete: Variant = null, override_color: Variant = null) -> void:
    if tween != null:
        tween.kill()

    color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
    color_rect.color = transparent_color
    color_rect.visible = true

    var color: Color = solid_color
    if override_color is Color:
        color = override_color

    tween = create_tween()

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        color_rect,
        "color",
        color,
        ease_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

    tween.tween_property(
        color_rect,
        "color",
        color,
        faded_duration,
    )

    if on_midways != null && on_midways is Callable:
        var hack: Dictionary[int, bool] = { 0: false }

        tween.parallel().tween_method(
            func (_value: float) -> void:
                if hack[0]:
                    return

                hack[0] = true

                @warning_ignore_start("unsafe_cast")
                (on_midways as Callable).call()
                @warning_ignore_restore("unsafe_cast")
                ,
            0.0,
            1.0,
            faded_duration,
        )


    tween.tween_property(
        color_rect,
        "color",
        transparent_color,
        ease_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
    @warning_ignore_restore("return_value_discarded")

    if tween.connect("finished", func () -> void:
        color_rect.visible = false
        color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if on_complete != null && on_complete is Callable:
            @warning_ignore_start("unsafe_cast")
            (on_complete as Callable).call()
            @warning_ignore_restore("unsafe_cast")
    ) != OK:
        push_error("Failed to connect fade finished will panic and not tween")

        tween.kill()

        color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        color_rect.visible = false
        if on_complete != null && on_complete is Callable:
            @warning_ignore_start("unsafe_cast")
            (on_complete as Callable).call()
            @warning_ignore_restore("unsafe_cast")
