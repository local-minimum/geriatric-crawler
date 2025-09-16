extends Resource
class_name Stockpile

const MAX_HISTORY: int = 256

@export var item_id: String
@export var _baseline_price: int = 100
@export_range(0, 1) var _min_price_factor: float = 0.5
@export_range(1, 10) var _max_price_factor: float = 4.0
@export_range(0, 1) var _volatility: float = 0.4
@export var _min_range_tick_volume: float = 1
@export var _max_range_tick_volume: float = 10
@export var min_unit: float = 1

var history: Array[int]
var price: int
var _hidden_price: float
var _derivative: float
var _trend_duration: int

func average() -> int:
    match history.size():
        0:
            return -1
        1:
            return price
        _:
            return roundi(ArrayUtils.sumi(history) / float(history.size()))

func trend(window_size: int = 1) -> float:
    if history.size() < 2:
        return 0

    var step: int = mini(history.size() - 1, window_size)
    var prev: int = history[-(1 + step)]
    var current: int = history[-1]
    var change: float = (current - prev) / (prev as float)
    # print_debug("[Stockpile %s] (%s - %s)/%s = %s" % [item_id, current, prev, prev, change])
    return change

func reset_simulation() -> void:
    history.clear()
    _derivative = _get_derivative()

    var value: float = randfn(_baseline_price, _volatility * (1.0 / maxf(0.1, _min_price_factor) + _max_price_factor) / 2)
    _hidden_price = clampf(value, _baseline_price * _min_price_factor, _baseline_price * _max_price_factor)
    price = roundi(_hidden_price)
    history.append(price)

func _get_derivative() -> float:
    var magnitude: float = _get_change_magnitude()
    if _trend_duration > 0:
        return clampf(_derivative + magnitude, -_baseline_price * _volatility ** 2, _baseline_price * _volatility ** 2)
    elif randf() < 0.05:
        _trend_duration = randi_range(3, 10)

    if _hidden_price > _baseline_price:
        if randf() < 0.3:
            return clampf(_derivative + magnitude, -_baseline_price * _volatility ** 2, _baseline_price * _volatility ** 2)
        elif randf() > 0.5:
            return magnitude
        else:
            return -absf(magnitude)

    if randf() < 0.3:
        return clampf(_derivative + magnitude, -_baseline_price * _volatility ** 2, _baseline_price * _volatility ** 2)
    elif randf() > 0.5:
        return magnitude
    else:
        return absf(magnitude)

func _get_change_magnitude() -> float:
    return _baseline_price * _volatility * randf_range(-_volatility, _volatility)

func tick() -> void:
    _derivative = _get_derivative()
    var _raw_price: float = _hidden_price + _derivative
    # print_debug("[Stock %s] Price %s Delta %s" % [item_id, _hidden_price, _derivative])

    if _raw_price < _baseline_price * _min_price_factor:
        _raw_price = _baseline_price * _min_price_factor
        if _derivative < 0:
            _derivative = absf(_get_change_magnitude())
        # print_debug("[Stock %s] Capped Min Price %s Delta %s" % [item_id, _hidden_price, _derivative])
    elif _raw_price > _baseline_price * _max_price_factor:
        _raw_price = _baseline_price * _max_price_factor
        if _derivative > 0:
            _derivative = -absf(_get_change_magnitude())
        # print_debug("[Stock %s] Capped Max Price %s Delta %s" % [item_id, _hidden_price, _derivative])

    _hidden_price = _raw_price
    price = roundi(_hidden_price)
    history.append(price)
    if history.size() > MAX_HISTORY:
        history = history.slice(-MAX_HISTORY)

func pre_simulate(ticks: int) -> void:
    for _tick: int in range(ticks):
        tick()

func minimum_price() -> int:
    return ceili(price * min_unit)

func place_order(volume: float, price_cap: int, remainder: Array[float]) -> int:
    remainder.clear()

    if volume == 0 || volume > 0 && price_cap <= 0:
        remainder.append(volume)
        return 0

    var tick_total_volume: float = randf_range(_min_range_tick_volume, _max_range_tick_volume)
    var traded_volume: float = clampf(volume, -tick_total_volume, tick_total_volume)

    var cost: int = maxi(1, ceili(traded_volume * price))
    if cost > price_cap:
        traded_volume = price_cap / float(price)
        cost = mini(maxi(1, ceili(traded_volume * cost)), price_cap)

    remainder.append(volume - traded_volume)

    return cost
