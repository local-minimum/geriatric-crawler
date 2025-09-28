extends Control
class_name LinearGaugeUI

enum GraphMode { ONLY_VALUE, ONLY_LINES, BOX_RANGE, BOX_RANGE_FROM_ZERO }

var current_value: float:
    set(value):
        current_value = value
        queue_redraw()

var min_value: float:
    set(value):
        min_value = value
        queue_redraw()

var max_value: float:
    set(value):
        max_value = value
        queue_redraw()

@export var mode: GraphMode:
    set(value):
        mode = value
        queue_redraw()

@export var axis_min: float:
    set(value):
        axis_min = value
        queue_redraw()

@export var axis_max: float:
    set(value):
        axis_max = value
        queue_redraw()

@export var axis_min_padding: float = 0:
    set(value):
        axis_min_padding = value
        queue_redraw()

@export var axis_max_padding: float = 0:
    set(value):
        axis_max_padding = value
        queue_redraw()

@export var box_vertical_padding: float = 0:
    set(value):
        box_vertical_padding = value
        queue_redraw()

@export var linear_latency_threshold: float = 0.1:
    set(value):
        linear_latency_threshold = value
        queue_redraw()

@export var linear_latency_step_factor: float = 2:
    set(value):
        linear_latency_step_factor = value
        queue_redraw()

@export var latency_seconds: float = 1.0:
    set(value):
        latency_seconds = value
        queue_redraw()

## Only valid in modes only lines and box anchored at zero
@export var show_min: bool = true:
    set(value):
        show_min = value
        queue_redraw()

## Only valid in modes only lines and box anchored at zero
@export var show_max: bool = true:
    set(value):
        show_max = value
        queue_redraw()

@export var value_color: Color = Color.HOT_PINK:
    set(value):
        value_color = value
        queue_redraw()

## Not used when drawing box range
@export var min_value_color: Color = Color.AQUA:
    set(value):
        min_value_color = value
        queue_redraw()

## Also for min to max range when drawing box range
@export var max_value_color: Color = Color.BLUE_VIOLET:
    set(value):
        max_value_color = value
        queue_redraw()

@export var tick_color: Color = Color.WHITE_SMOKE:
    set(value):
        tick_color = value
        queue_redraw()

var _hidden_current_value: float = 0
var _hidden_max_value: float = 0
var _hidden_min_value: float = 0
var _last_update_values_msec: int = 0
var _axis_min: float
var _axis_max: float
var _axis_span: float

func _draw() -> void:
    _update_hidden_values()

    var area_size: Vector2 = get_rect().size
    # print_debug("[Linear Gauge UI] Size: %s; %s (%s - %s) (%s - %s)" % [area_size, _hidden_current_value, min_value, max_value, _axis_min, _axis_max])

    match mode:
        GraphMode.BOX_RANGE_FROM_ZERO:
            if show_max:
                _draw_value_rect(maxf(0, _axis_min), _hidden_max_value, area_size, max_value_color)
            if show_min:
                _draw_value_rect(maxf(0, _axis_min), _hidden_min_value, area_size, min_value_color)

        GraphMode.BOX_RANGE:
            _draw_value_rect(_hidden_min_value, _hidden_max_value, area_size, max_value_color)

        GraphMode.ONLY_LINES:
            if show_max:
                _draw_line(_hidden_max_value, area_size, max_value_color)
            if show_min:
                _draw_line(_hidden_min_value, area_size, min_value_color)

    _draw_line(_hidden_current_value, area_size, value_color, 2)

func _draw_line(value: float, area_size: Vector2, color: Color, thickness: float = 1, from: float = 0.0, to: float = 1.0) -> void:
    var x: float = _get_draw_x_value(value, area_size)
    draw_line(
        Vector2(x, area_size.y * from),
        # Need to remove the padding from the start too ofc
        Vector2(x, area_size.y * (to - from)),
        color,
        thickness
    )

func _draw_value_rect(from: float, to: float, area_size: Vector2, color: Color) -> void:
    var from_x: float = _get_draw_x_value(from, area_size)
    draw_rect(
        Rect2(
            Vector2(from_x, area_size.y * box_vertical_padding),
            # Need to double the padding to include the padding on the start?
            Vector2(_get_draw_x_value(to, area_size) - from_x, area_size.y * (1.0 - box_vertical_padding * 2)),
        ),
        color,
    )

func _get_draw_x_value(value: float, area_size: Vector2) -> float:
    return area_size.x * (clampf(value, _axis_min, _axis_max) - _axis_min) / _axis_span

func _update_hidden_values() -> void:
    var delta_time: int = Time.get_ticks_msec() - _last_update_values_msec
    var progress: float = clampf(delta_time / (latency_seconds * 1000.0), 0.0, 1.0)
    if progress == 1.0:
        _hidden_current_value = current_value
        _hidden_min_value = min_value
        _hidden_max_value = max_value
    else:
        _hidden_current_value = _update_value(_hidden_current_value, current_value, progress)
        _hidden_max_value = _update_value(_hidden_max_value, max_value, progress)
        _hidden_min_value = _update_value(_hidden_min_value, min_value, progress)

    _last_update_values_msec = Time.get_ticks_msec()

    _axis_min = axis_min - axis_min_padding
    _axis_max = axis_max + axis_max_padding
    _axis_span = _axis_max - _axis_min

func _update_value(from: float, towards: float, progress: float) -> float:
    if from == towards:
        return towards

    var next: float = lerpf(from, towards, progress)

    if absf(next - from) < linear_latency_threshold:
        var step: float = minf(progress * linear_latency_threshold * linear_latency_step_factor, absf(from - towards))
        if from > towards:
            return from - step
        return from + step

    return next
