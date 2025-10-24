extends Node
class_name TradingMarket

@export var _stockpiles: Array[Stockpile]
@export var _pre_simulate_ticks: int = 40
@export var _simulate_on_new_day: int = 10
@export var _tick_frequency: int = 4000

var _next_tick: int
var _lookup: Dictionary[String, Stockpile]

var live: bool:
    set(value):
        _next_tick = Time.get_ticks_msec() + _tick_frequency
        live = value

func _ready() -> void:
    if __SignalBus.on_increment_day.connect(_handle_increment_day) != OK:
        push_error("Failed to connect increment day")

    for pile: Stockpile in _stockpiles:
        if _lookup.has(pile.item_id):
            push_warning("Stockpile id '%s' is duplicated" % pile.item_id)

        _lookup[pile.item_id] = pile
        pile.reset_simulation()
        pile.pre_simulate(_pre_simulate_ticks)

    __SignalBus.on_market_updated.emit(self)

func _handle_increment_day(_day_of_month: int, _days_left_of_month: int) -> void:
    if _simulate_on_new_day > 0:
        for pile: Stockpile in _stockpiles:
            pile.pre_simulate(_simulate_on_new_day)

        __SignalBus.on_market_updated.emit(self)

func tick() -> void:
    for pile: Stockpile in _stockpiles:
        pile.tick()

    __SignalBus.on_market_updated.emit(self)

func get_stock(item_id: String) -> Stockpile:
    return _lookup.get(item_id)

func list_stock_ids() -> Array[String]:
    return Array(_lookup.keys(), TYPE_STRING, "", null)

func _process(_delta: float) -> void:
    if !live || Time.get_ticks_msec() < _next_tick:
        return

    tick()
    # print_debug("[Trading Market] Tick!")
    _next_tick = Time.get_ticks_msec() + _tick_frequency
