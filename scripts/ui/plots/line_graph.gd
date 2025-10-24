extends Control
class_name LineGraph

@export var _include_zero: bool = true

@export var _min_y_span: float = 1
@export var _wanted_guides: int = 4

@export var _line_color: Color = Color.WHITE_SMOKE
@export var _guides_color: Color = Color.SLATE_GRAY

@export var _guide_width: float = 1.0
@export var _zero_guide_width: float = 1.5
@export var _line_width: float = 2.5

var _draw_empty: bool

var _y_max: float
var _y_min: float
var _y_span: float
var _series: Array[float]

var _guide_y_step: float
var _guide_y_anchor: float

func show_series(series: Array) -> void:
    if series.is_empty():
        _draw_empty = true
        return

    _series = Array(series, TYPE_FLOAT, "", null)

    _y_max = _series.reduce(func (acc: float, value: float) -> float: return maxf(acc, value), series[0])
    _y_min = _series.reduce(func (acc: float, value: float) -> float: return minf(acc, value), series[0])

    if _include_zero:
        _y_max = maxf(_y_max, 0.0)
        _y_min = minf(_y_min, 0.0)

    _y_span = _y_max - _y_min

    if _y_span < _min_y_span:
        _y_span = _min_y_span
        _y_max = _y_min + _y_span

    _guide_y_step = _calculate_guide_y_step()
    _guide_y_anchor = _calculate_guide_y_anchor()

    # print_debug("[Line Graph] Wants %s guides, got step %s with anchor %s for a span of %s - %s" % [
    #    _wanted_guides,
    #    _guide_y_step,
    #    _guide_y_anchor,
    #    _y_min,
    #    _y_max,
    #])
    queue_redraw()

func _calculate_guide_y_step() -> float:
    var step: float = floorf(_y_span / _wanted_guides)
    var ten_power: float = floorf(log(step) / log(10))
    var rounded: float = pow(10, ten_power) if ten_power >= 0 else 0.1

    # print_debug("[Line Graph] Step calculation step %s is 10^%s gives rounded %s" % [step, ten_power, rounded])
    if step / rounded > 4:
        return rounded * 5
    elif step / rounded > 2:
        return rounded * 2.5

    return rounded

func _calculate_guide_y_anchor() -> float:
    return floorf(_y_min / _guide_y_step) * _guide_y_step

func _draw() -> void:
    var area: Rect2 = get_rect()
    var min_area_x: float = 0
    var max_area_x: float = area.size.x
    var area_x_span: float = area.size.x

    # Guides
    var guide_y: float = _guide_y_anchor
    while guide_y < _y_max:
        if _visible_y(guide_y):
            var area_y: float = _transform_y_to_area(guide_y, area)

            draw_line(Vector2(min_area_x, area_y), Vector2(max_area_x, area_y), _guides_color, _guide_width if _is_zero_guide(guide_y) else _zero_guide_width)

        guide_y += _guide_y_step

    if _series.size() < 2:
        return

    # Series
    var _series_length: float = _series.size()
    var counter: Array[int] = [-1]
    draw_polyline(
        PackedVector2Array(
            _series.map(
                func (y_data: float) -> Vector2:
                    counter[0] += 1
                    return Vector2(
                        counter[0] * area_x_span / _series_length + min_area_x,
                        _transform_y_to_area(y_data, area),
                    )
                    ,
            )
        ),
        _line_color,
        _line_width,
    )

func _is_zero_guide(value: float) -> bool:
    return abs(value) / _guide_y_step < 0.01

func _visible_y(value: float) -> bool:
    return value >= _y_min && value <= _y_max

func _transform_y_to_area(value: float, area: Rect2) -> float:
    return area.size.y - (value - _y_min) * area.size.y / _y_span
