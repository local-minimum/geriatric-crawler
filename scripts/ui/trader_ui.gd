extends Control
class_name TraderUI

const _STOCKPILE_UI: String = "res://scenes/ui/stockplie_container.tscn"

@export var _ship: Spaceship
@export var _buy_and_sell: BuySellUI
@export var _stockpiles_container: Container
@export var _access_market_button: Button
@export var _trading_access_cost_factor: float = 0.005
@export var _trading_duration: int = 10
@export var _wait_tick_button: Button

var mode: TradingMode

var _on_close_callback: Variant
var _stocks: Dictionary[String, StockpileUI]
var _trading_ticks: int = 0
var _orders: Dictionary[String, float]
var _limited_stock: Dictionary[String, float]
var _categorized_ids: Dictionary[LootableManager.LootClass, Array]
var _categories: Dictionary[LootableManager.LootClass, Label]

const _SMALL_VALUE: float = 0.00001

enum TradingMode { BUY_AND_SELL, BUY, SELL }

func _ready() -> void:
    if __SignalBus.on_update_credits.connect(_handle_update_credits) != OK:
        push_error("Failed to connect update credits")

    if __SignalBus.on_market_updated.connect(_handle_market_updated) != OK:
        push_error("Failed to connect market update")

    if __SignalBus.on_change_room_complete.connect(_handle_room_change_coomplete) != OK:
        push_error("Failed to connect room change complete")

    hide()

func _handle_room_change_coomplete(_new_room: Spaceship.Room) -> void:
    if visible:
        hide()
        _buy_and_sell.hide()

func _handle_update_credits(credits: int, _loans: int) -> void:
    if visible:
        _sync_access_marked_button()

        for stock_ui: StockpileUI in _stocks.values():
            var stock: Stockpile = _ship.trading_market.get_stock(stock_ui.item_id)
            var limit: float = _limited_stock.get(stock.item_id, -1.0)

            if stock.item_id == null:
                stock_ui.set_buy_state()
            elif stock.minimum_price(limit) > credits && stock_ui.showing_buy():
                stock_ui.set_buy_state()

func _handle_market_updated(market: TradingMarket) -> void:
    if !visible:
        return

    if _trading_ticks < 0 && market.live:
        _trading_ticks += 1
        if _trading_ticks == 0:
            _sync_access_marked_button()
    elif _trading_ticks > 0:
        _trading_ticks -= 1
        _sync_wait_button()
        if _trading_ticks == 0:
            _end_market_access()

    if !_orders.is_empty():
        _process_orders(market)

    var buy_callback: Variant = _get_buy_callback()
    var sell_callback: Variant = _get_sell_callback()

    for stock_id: String in _stocks:
        var stock_ui: StockpileUI = _stocks[stock_id]
        if !stock_ui.visible || _orders.has(stock_id):
            continue

        var stock: Stockpile = _ship.trading_market.get_stock(stock_ui.item_id)
        var limit: float = _limited_stock.get(stock.item_id, -1.0)
        if stock.item_id == null:
            stock_ui.set_buy_state()
        elif stock.minimum_price(limit) > __GlobalGameState.total_credits || !_limited_stock.is_empty() && limit <= 0.0:
            stock_ui.set_buy_state()
        else:
            stock_ui.set_buy_state(buy_callback)
        stock_ui.set_sell_state(sell_callback)

func _process_orders(market: TradingMarket) -> void:
    var showed_out_of_stock: bool

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
            if !_limited_stock.is_empty():
                _limited_stock[stock_id] = remainder[0]
                var stock_ui: StockpileUI = _stocks.get(stock_id, null)
                if stock_ui != null:
                    stock_ui.update_limited_buy(remainder[0])
        else:
            @warning_ignore_start("return_value_discarded")
            _orders.erase(stock_id)
            @warning_ignore_restore("return_value_discarded")

            if !_limited_stock.is_empty() && _limited_stock.get(stock_id, 0.0) < _SMALL_VALUE:
                var stock_ui: StockpileUI = _stocks.get(stock_id, null)
                if stock_ui != null:
                    _remove_item_from_category(stock_ui)

                if !showed_out_of_stock && _limited_stock.values().all(func (value: float) -> bool: return absf(value) < _SMALL_VALUE):
                    UIUtils.clear_control(_stockpiles_container)
                    _add_header_label(LootableManager.LootClass.NONE, tr("ALL_COMMODITIES_BOUGHT"))
                    _end_market_access()

func _remove_item_from_category(stock_ui: StockpileUI) -> void:
    stock_ui.hide()

    for category: LootableManager.LootClass in _categorized_ids:
        var ids: Array[String] = _categorized_ids[category]
        if ids.has(stock_ui.item_id) && ids.all(
            func (id: String) -> bool:
                var stock: StockpileUI = _stocks.get(id, null)
                return stock == null || !stock.visible
        ):
            var label: Label = _categories.get(category, null)
            if label != null:
                label.hide()

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
    self._limited_stock = limited_stock
    self.mode = mode
    _on_close_callback = on_close

    _setup_stock()

    _ship.trading_market.live = _trading_ticks <= 0
    _sync_access_marked_button()
    _sync_wait_button()

    show()

func _sync_access_marked_button() -> void:
    var access_cost: int = _access_market_cost
    _access_market_button.text = tr("ACCESS_TRADING_COST").format({"cost": GlobalGameState.credits_with_sign(access_cost)})
    _access_market_button.disabled =  _trading_ticks < 0 || __GlobalGameState.total_credits <= access_cost || !_ship.trading_market.live

func _sync_wait_button() -> void:
    if _trading_ticks > 0:
        _wait_tick_button.visible = _trading_ticks > 0
        _wait_tick_button.text = tr("ACTION_WAIT_TIME").format({"time": _trading_ticks})
    else:
        _wait_tick_button.visible = false

func _add_header_label(category: LootableManager.LootClass, text: String) -> void:
    var category_title: Label = Label.new()
    category_title.text = text
    category_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    category_title.uppercase = true
    category_title.theme_type_variation = "HeaderMedium"

    _stockpiles_container.add_child(category_title)
    _categories[category] = category_title

func _setup_stock() -> void:
    UIUtils.clear_control(_stockpiles_container)
    _stocks.clear()
    _categorized_ids.clear()

    if _limited_stock.is_empty():
        var ids: Array[String] = _ship.trading_market.list_stock_ids()
        _categorized_ids = LootableManager.categorize(ids)
    else:
        _categorized_ids = LootableManager.categorize(_limited_stock.keys())

    var scene: PackedScene = load(_STOCKPILE_UI)

    if _categorized_ids.is_empty():
        _add_header_label(LootableManager.LootClass.NONE, tr("NO_COMMODITIES_AVAILABLE"))

    for category: LootableManager.LootClass in _categorized_ids:
        var items: Array[String] = _categorized_ids[category]

        _add_header_label(category, LootableManager.translate_cateogry(category, 999))

        for stock_id: String in items:
            var stock: StockpileUI = scene.instantiate()

            var limit: float = -1 if _limited_stock.is_empty() else _limited_stock.get(stock_id, 0.0)
            stock.track_stock(stock_id, _ship.trading_market, limit)
            _stocks[stock_id] = stock

            _stockpiles_container.add_child(stock)

func _on_close_trader_pressed() -> void:
    _ship.trading_market.live = false
    _trading_ticks = 0

    hide()

    if _on_close_callback is Callable:
        @warning_ignore_start("unsafe_cast")
        (_on_close_callback as Callable).call()
        @warning_ignore_restore("unsafe_cast")

func _get_buy_callback() -> Variant:
    if mode != TradingMode.SELL:
        return _handle_want_to_buy_stock
    return null

func _get_sell_callback() -> Variant:
    if mode != TradingMode.BUY:
        return _handle_want_to_sell_stock
    return null

func _handle_want_to_buy_stock(item_id: String) -> void:
    @warning_ignore_start("unsafe_cast")
    var limit: float = _limited_stock.get(item_id, -1.0) as float
    @warning_ignore_restore("unsafe_cast")
    _buy_and_sell.buy(
        _ship.trading_market.get_stock(item_id),
        _place_buy_order,
        limit,
    )

func _place_buy_order(stock_id: String, amount: float) -> void:
    _place_order(stock_id, amount)

func _handle_want_to_sell_stock(item_id: String) -> void:
    _buy_and_sell.sell(_ship.trading_market.get_stock(item_id), _place_sell_order)

func _place_sell_order(stock_id: String, amount: float) -> void:
    _place_order(stock_id, -amount)

func _place_order(stock_id: String, amount: float) -> void:
    if amount == 0 || stock_id.is_empty():
        return

    if _orders.has(stock_id):
        NotificationsManager.warn(tr("NOTICE_MARKET"), tr("CAN_NOT_BUY_AND_SELL"))
        return

    _orders[stock_id] = amount
    var stock_ui: StockpileUI = _stocks.get(stock_id, null)

    if amount > 0 && _limited_stock.has(stock_id):
        _limited_stock[stock_id] -= amount
        print_debug("[Trader] %s has %s remaining stock" % [stock_id, _limited_stock[stock_id]])

        if stock_ui != null:
            if __GlobalGameState.total_credits == 0 || _limited_stock.values().all(func (value: float) -> bool: return value <= 0):
                print_debug("[Trader] Nothing more to do on the market")
                _end_market_access()


    if stock_ui != null:
        stock_ui.set_need_text(tr("PROCESSING_ORDER"))
        stock_ui.set_buy_state()
        stock_ui.set_sell_state()

    _ship.trading_market.tick()

func _end_market_access() -> void:
    for stock: StockpileUI in _stocks.values():
        stock.set_buy_state()
        stock.set_sell_state()

    _trading_ticks = -10
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

    for stock_ui: StockpileUI in _stocks.values():
        if !stock_ui.visible:
            continue

        var stock: Stockpile = _ship.trading_market.get_stock(stock_ui.item_id)
        var limit: float = _limited_stock.get(stock.item_id, -1.0)
        if stock.item_id == null:
            stock_ui.set_buy_state()
        elif stock.minimum_price(limit) > __GlobalGameState.total_credits || !_limited_stock.is_empty() && limit <= -1.0:
            stock_ui.set_buy_state()
        else:
            stock_ui.set_buy_state(buy_callback)
        stock_ui.set_sell_state(sell_callback)

    _trading_ticks = _trading_duration
    _ship.trading_market.live = _trading_ticks <= 0
    _sync_wait_button()

func _on_wait_button_pressed() -> void:
    if !_ship.trading_market.live:
        _ship.trading_market.tick()
