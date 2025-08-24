extends Node
class_name GlobalGameState

const _BASE_DAY: int = 10244
const _MONTS_PER_YEAR: int = 10
const _DAYS_PER_MONTH: int = 24

var _credits: int
var _loans: int
var _game_day: int = 1
var _interest_rate: float = 0.1
var _rent: int

var day_of_month: int:
    get: return posmod(_game_day + _BASE_DAY, _DAYS_PER_MONTH)

var days_until_end_of_month: int:
    get: return _DAYS_PER_MONTH - posmod(_game_day + _BASE_DAY, _DAYS_PER_MONTH)

@warning_ignore_start("integer_division")
var month: int:
    get: return (_game_day + _BASE_DAY) / _DAYS_PER_MONTH

var year: int:
    get: return (_game_day + _BASE_DAY) / (_DAYS_PER_MONTH * _MONTS_PER_YEAR)
@warning_ignore_restore("integer_division")

var total_credits: int:
    get: return _credits

var loans: int:
    get: return _loans

var rent: int:
    get: return _rent

static func credits_with_sign(amount: int) -> String:
    return "₳ %03d" % amount

func withdraw_credits(amount: int) -> bool:
    if amount < 0:
        return false

    if amount <= _credits:
        _credits -= amount

        __SignalBus.on_update_credits.emit(_credits, _loans)
        NotificationsManager.info("Lost", credits_with_sign(amount), 5000)
        return true

    return false

func deposit_credits(amount: int) -> void:
    if amount <= 0:
        return

    _credits += amount

    __SignalBus.on_update_credits.emit(_credits, _loans)
    NotificationsManager.info("Gained", credits_with_sign(amount), 5000)

func set_credits(new_credits: int, new_loans: int) -> void:
    _credits = new_credits
    _loans = new_loans

func take_out_loan(amount: int) -> void:
    if amount <= 0:
        return

    _loans += amount
    _credits += amount

    __SignalBus.on_update_credits.emit(_credits, _loans)
    NotificationsManager.info("Loaned", credits_with_sign(amount), 5000)

func calculate_interest() -> int:
    return ceili(loans * _interest_rate)

func calculate_balance() -> int:
    return _credits - (calculate_interest() + rent)
