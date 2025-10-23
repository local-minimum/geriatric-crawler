extends Node
class_name GlobalGameStateCore

const _BASE_DAY: int = 10244
const _MONTS_PER_YEAR: int = 10
const _DAYS_PER_MONTH: int = 24

#region Credits
var _credits: int

var total_credits: int:
    get: return _credits

static func credits_with_sign(amount: int) -> String:
    return "%03d" % amount

func can_afford(amount: int) -> bool:
    return amount <= _credits

func withdraw_credits(amount: int) -> bool:
    if amount < 0:
        return false

    if amount <= _credits:
        _credits -= amount

        __SignalBus.on_update_credits.emit(_credits)
        NotificationsManager.info(tr("NOTICE_CREDITS"), tr("LOST_ITEM").format({"item": credits_with_sign(amount)}), 5000)
        return true

    return false

func deposit_credits(amount: int) -> void:
    if amount <= 0:
        return

    _credits += amount
    __SignalBus.on_update_credits.emit(_credits)

    NotificationsManager.info(tr("NOTICE_CREDITS"), tr("GAINED_ITEM").format({"item": credits_with_sign(amount)}), 5000)
    return

func set_credits(new_credits: int) -> void:
    _credits = new_credits
    __SignalBus.on_update_credits.emit(_credits)

#endregion Credits

#region Calendar
var game_day: int = 0

var day_of_month: int:
    get: return posmod(game_day + _BASE_DAY, _DAYS_PER_MONTH) + 1

var days_until_end_of_month: int:
    get: return _DAYS_PER_MONTH - posmod(game_day + _BASE_DAY, _DAYS_PER_MONTH)

@warning_ignore_start("integer_division")
var month: int:
    get: return posmod((game_day + _BASE_DAY) / _DAYS_PER_MONTH, _MONTS_PER_YEAR) + 1

var is_first_month: bool:
    get: return month == _BASE_DAY / _DAYS_PER_MONTH

var year: int:
    get: return (game_day + _BASE_DAY) / (_DAYS_PER_MONTH * _MONTS_PER_YEAR)
@warning_ignore_restore("integer_division")

## Note that setting game day this way doesn't notify anything
func set_game_day(new_game_day: int) -> void:
    game_day = new_game_day

func go_to_next_day(days: int = 1) -> void:
    if days <= 0:
        return

    game_day += days
    __SignalBus.on_increment_day.emit(day_of_month, days_until_end_of_month)
    __SignalBus.on_update_day.emit(year, month, day_of_month, days_until_end_of_month)
#endregion
