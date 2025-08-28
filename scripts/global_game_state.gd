extends Node
class_name GlobalGameState

const _BASE_DAY: int = 10244
const _MONTS_PER_YEAR: int = 10
const _DAYS_PER_MONTH: int = 24

const BASE_INTEREST_RATE: int = 10

var _credits: int
var _loans: int
var game_day: int = 0
var _interest_rate_points: int = 10
var _rent: int

var _interest_rate: float:
    get: return _interest_rate_points / 100.0

var interest_rate_points: int:
    get: return _interest_rate_points

var day_of_month: int:
    get: return posmod(game_day + _BASE_DAY, _DAYS_PER_MONTH)

var days_until_end_of_month: int:
    get: return _DAYS_PER_MONTH - posmod(game_day + _BASE_DAY, _DAYS_PER_MONTH)

@warning_ignore_start("integer_division")
var month: int:
    get: return (game_day + _BASE_DAY) / _DAYS_PER_MONTH

var is_first_month: bool:
    get: return month == _BASE_DAY / _DAYS_PER_MONTH

var year: int:
    get: return (game_day + _BASE_DAY) / (_DAYS_PER_MONTH * _MONTS_PER_YEAR)
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
        NotificationsManager.info(tr("NOTICE_CREDITS"), tr("GAINED_ITEM").format({"item": credits_with_sign(amount)}), 5000)
        return true

    return false

func deposit_credits(amount: int) -> void:
    if amount <= 0:
        return

    _credits += amount

    __SignalBus.on_update_credits.emit(_credits, _loans)
    NotificationsManager.info(tr("NOTICE_CREDITS"), tr("LOST_ITEM").format({"item": credits_with_sign(amount)}), 5000)

func set_credits(new_credits: int, new_loans: int) -> void:
    _credits = new_credits
    _loans = new_loans
    __SignalBus.on_update_credits.emit(_credits, _loans)

func set_interest_rate(rate: int) -> void:
    _interest_rate_points = maxi(rate, BASE_INTEREST_RATE)
    __SignalBus.on_update_interest_rate.emit(_interest_rate_points)

func take_out_loan(amount: int) -> void:
    if amount <= 0:
        return

    _loans += amount
    _credits += amount

    __SignalBus.on_update_credits.emit(_credits, _loans)
    NotificationsManager.info(tr("NOTICE_CREDITS"), tr("TOOK_OUT_LOAN_AMOUNT").format({"amount": credits_with_sign(amount)}), 5000)

func calculate_interest() -> int:
    return ceili(loans * _interest_rate)

func calculate_balance() -> int:
    return _credits - (calculate_interest() + _rent)

func set_rent(new_rent: int) -> void:
    _rent = new_rent
    __SignalBus.on_update_rent.emit(_rent)

func set_game_day(new_game_day: int) -> void:
    game_day = new_game_day
    __SignalBus.on_update_day.emit(year, month, day_of_month, days_until_end_of_month)
