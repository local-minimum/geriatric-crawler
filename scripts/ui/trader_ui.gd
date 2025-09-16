extends Control
class_name TraderUI

const _STOCKPILE_UI: String = "res://scenes/ui/stockplie_container.tscn"

@export var _ship: Spaceship
@export var _stockpiles_container: Container
@export var _access_market_button: Button
@export var _trading_access_cost_factor: float = 0.005
@export var _trading_duration: int = 10
@export var _wait_tick_button: Button

var limited_stock: Dictionary[String, float]
var mode: TradingMode
var on_close_callback: Variant
var _stocks: Array[StockpileUI]
var _trading_ticks: int = 0
var _orders: Dictionary[String, float]

const _SMALL_VALUE: float = 0.00001

enum TradingMode { BUY_AND_SELL, BUY, SELL }

func _ready() -> void:
    if __SignalBus.on_update_credits.connect(_handle_update_credits) != OK:
        push_error("Failed to connect update credits")

    if __SignalBus.on_market_updated.connect(_handle_market_updated) != OK:
        push_error("Failed to connect market update")

    hide()

func _handle_update_credits(_credits: int, _loans: int) -> void:
    if visible:
        _sync_access_marked_button()

func _handle_market_updated(market: TradingMarket) -> void:
    if !visible || _trading_ticks <= 0 && _orders.is_empty():
        return

    _trading_ticks -= 1

    if _trading_ticks <= 0:
        _end_market_access()
    else:
        _sync_wait_button()

    for stock_id: String in _orders.keys():
        var stock: Stockpile = market.get_stock(stock_id)
        if stock == null:
            @warning_ignore_start("return_value_discarded")
            _orders.erase(stock_id)
            @warning_ignore_restore("return_value_discarded")
            continue

        var remainder: Array[float] = [0]
        var cost: int = stock.place_order(_orders[stock_id], __GlobalGameState.total_credits, remainder)
        if cost > 0:
            if __GlobalGameState.withdraw_credits(cost):
                var bought: float = _orders[stock_id] - remainder[0]
                if !_ship.inventory.add_to_inventory(stock_id, bought):
                    NotificationsManager.warn(tr("NOTICE_INVENTORY"), tr("FAILED_GAIN_ITEM").format({"item": LootableManager.translate(stock_id, ceili(bought))}))
                    remainder = [0]
        elif cost < 0:
            var sold: float = absf(_orders[stock_id] - remainder[0])
            if _ship.inventory.remove_from_inventory(stock_id, sold, false) != 0:
                __GlobalGameState.deposit_credits(cost)
            else:
                NotificationsManager.warn(tr("NOTICE_MARKET"), tr("FAILED_SELL_ITEM").format({"item": LootableManager.translate(stock_id, ceili(sold))}))
                remainder = [0]


        if absf(remainder[0]) > _SMALL_VALUE:
            _orders[stock_id] = remainder[0]
        else:
            @warning_ignore_start("return_value_discarded")
            _orders.erase(stock_id)
            @warning_ignore_restore("return_value_discarded")

var _access_market_cost: int:
    get():
        return ceili(__GlobalGameState.total_credits * _trading_access_cost_factor)

@warning_ignore_start("shadowed_variable")
func show_trader(
    limited_stock: Dictionary[String, float] = {},
    mode: TradingMode = TradingMode.BUY_AND_SELL,
    on_close: Variant = null
) -> void:
    @warning_ignore_restore("shadowed_variable")
    self.limited_stock = limited_stock
    self.mode = mode
    on_close_callback = on_close

    _setup_stock()

    _ship.trading_market.live = _trading_ticks <= 0
    _sync_access_marked_button()
    _sync_wait_button()

    show()

func _sync_access_marked_button() -> void:
    var access_cost: int = _access_market_cost
    _access_market_button.text = tr("ACCESS_TRADING_COST").format({"cost": GlobalGameState.credits_with_sign(access_cost)})
    _access_market_button.disabled = __GlobalGameState.total_credits <= access_cost || !_ship.trading_market.live

func _sync_wait_button() -> void:
    if _trading_ticks > 0:
        _wait_tick_button.visible = _trading_ticks > 0
        _wait_tick_button.text = tr("ACTION_WAIT_TIME").format({"time": _trading_ticks})
    else:
        _wait_tick_button.visible = false

func _setup_stock() -> void:
    UIUtils.clear_control(_stockpiles_container)
    var categorized: Dictionary[LootableManager.LootClass, Array]
    _stocks.clear()

    if limited_stock.is_empty():
        var ids: Array[String] = _ship.trading_market.list_stock_ids()
        categorized = LootableManager.categorize(ids)
    else:
        categorized = LootableManager.categorize(limited_stock.keys())

    var scene: PackedScene = load(_STOCKPILE_UI)

    for category: LootableManager.LootClass in categorized:
        var items: Array[String] = categorized[category]

        var category_title: Label = Label.new()
        category_title.text = LootableManager.translate_cateogry(category, 999)
        category_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        category_title.uppercase = true
        category_title.theme_type_variation = "HeaderMedium"


        _stockpiles_container.add_child(category_title)


        for stock_id: String in items:
            var stock: StockpileUI = scene.instantiate()

            stock.track_stock(stock_id, _ship.trading_market)
            _stocks.append(stock)

            _stockpiles_container.add_child(stock)

func _on_close_trader_pressed() -> void:
    _ship.trading_market.live = false
    hide()

    if on_close_callback is Callable:
        @warning_ignore_start("unsafe_cast")
        (on_close_callback as Callable).call()
        @warning_ignore_restore("unsafe_cast")

func _get_buy_callback() -> Variant:
    if mode != TradingMode.SELL:
        return _handle_want_to_buy_stock
    return null

func _get_sell_callback() -> Variant:
    if mode != TradingMode.BUY:
        return _handle_want_to_sell_stock
    return null

func _handle_want_to_buy_stock(_item_id: String) -> void:
    # TODO: Add callbacks if sell / buy is allowed
    pass

func _handle_want_to_sell_stock(_item_id: String) -> void:
    pass

func _place_order(stock_id: String, amount: float) -> void:
    if amount == 0 || stock_id.is_empty():
        return

    if _orders.has(stock_id):
        NotificationsManager.warn(tr("NOTICE_MARKET"), tr("CAN_NOT_BUY_AND_SELL"))
        return

    _orders[stock_id] = amount
    _ship.trading_market.tick()

func _end_market_access() -> void:
    for stock: StockpileUI in _stocks:
        stock.set_buy_state()
        stock.set_sell_state()

    _trading_ticks = 0
    _ship.trading_market.live = true

    _sync_access_marked_button()
    _sync_wait_button()

func _on_access_trading_button_pressed() -> void:
    _access_market_button.disabled = true

    if !__GlobalGameState.withdraw_credits(_access_market_cost):
        NotificationsManager.warn(tr("NOTICE_CREDITS"), tr("INSUFFICIENT_FUNDS"))
        return

    var buy_callback: Variant = _get_buy_callback()
    var sell_callback: Variant = _get_sell_callback()

    for stock: StockpileUI in _stocks:
        stock.set_buy_state(buy_callback)
        stock.set_sell_state(sell_callback)

    _trading_ticks = _trading_duration
    _ship.trading_market.live = _trading_ticks <= 0
    _sync_wait_button()

func _on_wait_button_pressed() -> void:
    if !_ship.trading_market.live:
        _ship.trading_market.tick()
