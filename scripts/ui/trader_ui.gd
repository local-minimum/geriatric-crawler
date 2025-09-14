extends Control
class_name TraderUI

const _STOCKPILE_UI: String = "res://scenes/ui/stockplie_container.tscn"

@export var ship: Spaceship
@export var stockpiles_container: Container

var limited_stock: Dictionary[String, float]
var mode: TradingMode
var on_close_callback: Variant

enum TradingMode { BUY_AND_SELL, BUY, SELL }

func _ready() -> void:
    hide()

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

    ship.trading_market.live = true

    show()

func _setup_stock() -> void:
    UIUtils.clear_control(stockpiles_container)
    var categorized: Dictionary[LootableManager.LootClass, Array]

    if limited_stock.is_empty():
        var ids: Array[String] = ship.trading_market.list_stock_ids()
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


        stockpiles_container.add_child(category_title)

        var buy_callback: Variant = _get_buy_callback()
        var sell_callback: Variant = _get_sell_callback()

        for stock_id: String in items:
            var stock: StockpileUI = scene.instantiate()

            # TODO: Add callbacks if sell / buy is allowed
            stock.track_stock(stock_id, ship.trading_market, buy_callback, sell_callback)

            stockpiles_container.add_child(stock)

func _on_close_trader_pressed() -> void:
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
    pass

func _handle_want_to_sell_stock(_item_id: String) -> void:
    pass
