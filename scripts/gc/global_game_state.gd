extends GlobalGameStateCore
class_name GlobalGameState

const BASE_INTEREST_RATE: int = 10

var _loans: int
var _interest_rate_points: int = 10
var _rent: int

var _interest_rate: float:
    get: return _interest_rate_points / 100.0

var interest_rate_points: int:
    get: return _interest_rate_points

var loans: int:
    get: return _loans

var rent: int:
    get: return _rent

static func credits_with_sign(amount: int) -> String:
    return "₳ %03d" % amount

func set_loans(new_loans: int) -> void:
    _loans = new_loans
    __SignalBus.on_update_loans.emit(_loans)

func set_interest_rate(rate: int) -> void:
    _interest_rate_points = maxi(rate, BASE_INTEREST_RATE)
    __SignalBus.on_update_interest_rate.emit(_interest_rate_points)

func take_out_loan(amount: int) -> void:
    if amount <= 0:
        return

    _loans += amount
    _credits += amount

    __SignalBus.on_update_credits.emit(_credits)
    __SignalBus.on_update_loans.emit(_loans)
    NotificationsManager.info(tr("NOTICE_CREDITS"), tr("TOOK_OUT_LOAN_AMOUNT").format({"amount": credits_with_sign(amount)}), 5000)

func calculate_interest() -> int:
    return ceili(loans * _interest_rate)

func calculate_balance() -> int:
    return _credits - (calculate_interest() + _rent)

func set_rent(new_rent: int) -> void:
    _rent = new_rent
    __SignalBus.on_update_rent.emit(_rent)
