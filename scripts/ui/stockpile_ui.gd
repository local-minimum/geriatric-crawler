extends Container
class_name StockpileUI

@export var _title: Label
@export var _average: Label
@export var _trend: Label
@export var _trend_arrow: TextureRect
@export var _price: Label
@export var _graph: LineGraph

@export var _trend_window: int = 6
@export var _zero_trend_tolerance: float = 0.01

@export var _up_arrow: Texture2D
@export var _steady_arrow: Texture2D
## If left empty will use H-flipped up arrow
@export var _down_arrow: Texture2D

@export var _up_color: Color = Color.GREEN
@export var _steady_color: Color = Color.WHITE_SMOKE
@export var _down_color: Color = Color.RED

var _item_id: String
var _market: TradingMarket

func _ready() -> void:
    if __SignalBus.on_market_updated.connect(_handle_market_tick) != OK:
        push_error("Failed to connect marked updated")

func track_stock(item_id: String, market: TradingMarket) -> void:
    _market = market
    _item_id = item_id

    _title.text = LootableManager.translate(item_id).to_upper()

    _handle_market_tick(market)

func _handle_market_tick(market: TradingMarket) -> void:
    if _market != market:
        return

    var stock: Stockpile = market.get_stock(_item_id)

    if stock == null:
        _show_stock_missing()
        return

    _average.text = tr("AVERAGE_VALUE").format({"value": GlobalGameState.credits_with_sign(stock.average())})

    var trend: float = stock.trend(_trend_window)

    if trend > _zero_trend_tolerance:
        _trend_arrow.texture = _up_arrow
        _trend_arrow.flip_v = false
        _trend_arrow.self_modulate = _up_color
    elif trend < -_zero_trend_tolerance:
        if _down_arrow != null:
            _trend_arrow.texture = _down_arrow
            _trend_arrow.flip_v = false
        else:
            _trend_arrow.texture = _up_arrow
            _trend_arrow.flip_v = true
        _trend_arrow.self_modulate = _down_color
    else:
        _trend_arrow.texture = _steady_arrow
        _trend_arrow.flip_v = false
        _trend_arrow.self_modulate = _steady_color

    _trend.text = tr("HOUR_TREND_VALUE".format({"trend": "%2.1f%%" % (trend * 100)}))

    _price.text = GlobalGameState.credits_with_sign(stock.price)

    _graph.show_line(stock.history)

func _show_stock_missing() -> void:
    pass
