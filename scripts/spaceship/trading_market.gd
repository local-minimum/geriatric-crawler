extends Node
class_name TradingMarket

@export var stockpiles: Array[Stockpile]
@export var _pre_simulate_ticks: int = 40
@export var _simulate_on_new_day: int = 10
@export var _tick_frequency: int = 4000

var _next_tick: int

var live: bool:
    set(value):
        _next_tick = Time.get_ticks_msec() + _tick_frequency

func _ready() -> void:
    if __SignalBus.on_increment_day.connect(_handle_increment_day) != OK:
        push_error("Failed to connect increment day")

    for pile: Stockpile in stockpiles:
        pile.reset_simulation()
        pile.pre_simulate(_pre_simulate_ticks)

    __SignalBus.on_market_updated.emit(self)

func _handle_increment_day(_day_of_month: int, _days_left_of_month: int) -> void:
    if _simulate_on_new_day > 0:
        for pile: Stockpile in stockpiles:
            pile.pre_simulate(_simulate_on_new_day)

        __SignalBus.on_market_updated.emit(self)

func tick() -> void:
    for pile: Stockpile in stockpiles:
        pile.tick()

    __SignalBus.on_market_updated.emit(self)

func _process(_delta: float) -> void:
    if !live || Time.get_ticks_msec() < _next_tick:
        return

    tick()

    _next_tick = Time.get_ticks_msec() + _tick_frequency
