extends Resource
class_name Stockpile

const MAX_HISTORY: int = 256

@export var item_id: String
@export var _baseline_price: int = 100
@export_range(0, 1) var _min_price_factor: float = 0.5
@export_range(1, 10) var _max_price_factor: float = 4.0
@export_range(0, 1) var _volatility: float = 0.4

var history: Array[int]
var price: int
var _hidden_price: float
var _derivative: float

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
    return (history[-1] - prev) / (prev as float)

func reset_simulation() -> void:
    history.clear()
    _derivative = _get_derivative_change()

    var value: float = randfn(_baseline_price, _volatility * (1.0 / maxf(0.1, _min_price_factor) + _max_price_factor) / 2)
    _hidden_price = clampf(value, _baseline_price * _min_price_factor, _baseline_price * _max_price_factor)
    price = roundi(_hidden_price)
    history.append(price)

func _get_derivative_change() -> float:
    var mean: float = _baseline_price * _volatility
    return mean - randfn(mean, _volatility)

func tick() -> void:
    _derivative += _get_derivative_change()
    var _raw_price: float = _hidden_price + _derivative
    # print_debug("[Stock %s] Price %s Delta %s" % [item_id, _hidden_price, _derivative])

    if _raw_price < _baseline_price * _min_price_factor:
        _raw_price = _baseline_price * _min_price_factor
        if _derivative < 0:
            _derivative = _get_derivative_change()
        # print_debug("[Stock %s] Capped Min Price %s Delta %s" % [item_id, _hidden_price, _derivative])
    elif _raw_price > _baseline_price * _max_price_factor:
        _raw_price = _baseline_price * _max_price_factor
        if _derivative > 0:
            _derivative = _get_derivative_change()
        # print_debug("[Stock %s] Capped Max Price %s Delta %s" % [item_id, _hidden_price, _derivative])

    _hidden_price = _raw_price
    price = roundi(_hidden_price)
    history.append(price)
    if history.size() > MAX_HISTORY:
        history = history.slice(-MAX_HISTORY)

func pre_simulate(ticks: int) -> void:
    for _tick: int in range(ticks):
        tick()
