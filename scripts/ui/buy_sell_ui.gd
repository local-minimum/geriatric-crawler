extends Control
class_name BuySellUI

@export var _comodity: Label
@export var _current_price: Label
@export var _volume: LineEdit
@export var _total_price: Label
@export var _buy_sell_button: Button

static var _numeric: RegEx

func _ready() -> void:
    if _numeric == null:
        _numeric = RegEx.new()
        if _numeric.compile("-?[0-9]+\\.?[0-9]*") != OK:
            push_error("Failed to compile numeric regex")
    hide()


var _stock: Stockpile
var _callback: Callable
var _cancel_callback: Variant
var _volume_value: float

func _common_setup(stock: Stockpile, callback: Callable, fixed_amount: float, cancel_callback: Variant) -> void:
    _stock = stock
    _callback = callback
    _cancel_callback = cancel_callback

    _comodity.text = LootableManager.translate(stock.item_id)

    _current_price.text = "%s / %s" % [
        GlobalGameState.credits_with_sign(stock.price),
        LootableManager.unit(stock.item_id, true),
    ]

    _volume.text = ""
    _volume_value = stock.min_unit if fixed_amount <= 0 else fixed_amount
    _volume.placeholder_text = "%s" % _volume_value
    _volume.editable = fixed_amount <= 0

    _total_price.text = GlobalGameState.credits_with_sign(total)
    show()


func buy(stock: Stockpile, callback: Callable, fixed_amount: float = -1, cancel_callback: Variant = null) -> void:
    if stock == null:
        hide()
        return

    _buy_sell_button.text = tr("ACTION_BUY")
    _common_setup(stock, callback, fixed_amount, cancel_callback)

func sell(stock: Stockpile, callback: Callable, cancel_callback: Variant = null) -> void:
    if stock == null:
        hide()
        return

    _buy_sell_button.text = tr("ACTION_SELL")
    _common_setup(stock, callback, -1, cancel_callback)


var total: int:
    get():
        if _stock == null:
            return 0
        return ceili(_stock.price * _volume_value)


func _on_cancel_pressed() -> void:
    if _cancel_callback is Callable:
        @warning_ignore_start("unsafe_cast")
        (_cancel_callback as Callable).call()
        @warning_ignore_restore("unsafe_cast")

    hide()

func _on_buy_sell_pressed() -> void:
    _callback.call(_stock.item_id, _volume_value)
    hide()

func _on_line_edit_text_changed(new_text: String) -> void:
    var match: RegExMatch = _numeric.search(new_text)
    if match == null:
        _volume_value = _stock.min_unit
        _volume.text = ""
    else:
        _volume_value = maxf(match.get_string().to_float(), _stock.min_unit)
        var new_volume_text: String = "%s" % _volume_value
        if new_text != new_volume_text:
            _volume.text = new_volume_text


    _total_price.text = GlobalGameState.credits_with_sign(total)
