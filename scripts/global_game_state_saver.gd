extends SaveExtension
class_name GlobalGameStateSaver

const _CREDITS_KEY: String = "credits"
const _LOANS_KEY: String = "loans"

const _INTEREST_RATE_KEY: String = "interest-rate"

const _RENT_KEY: String = "rent"

const _GAME_DAY_KEY: String = "day"


@export var _save_key: String = "globals"

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _INTEREST_RATE_KEY: __GlobalGameState._interest_rate_points,
        _CREDITS_KEY: __GlobalGameState._credits,
        _LOANS_KEY: __GlobalGameState._loans,
        _RENT_KEY: __GlobalGameState._rent,
        _GAME_DAY_KEY: __GlobalGameState._game_day
    }

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var credits: int = DictionaryUtils.safe_geti(extentsion_save_data, _CREDITS_KEY, 0, false)
    var loans: int = DictionaryUtils.safe_geti(extentsion_save_data, _LOANS_KEY, 0, false)
    __GlobalGameState.set_credits(credits, loans)

    var interest_rate: int = DictionaryUtils.safe_geti(extentsion_save_data, _INTEREST_RATE_KEY, GlobalGameState.BASE_INTEREST_RATE, false)
    __GlobalGameState.set_interest_rate(interest_rate)

    var game_day: int = DictionaryUtils.safe_geti(extentsion_save_data, _GAME_DAY_KEY, 0, false)
    __GlobalGameState.set_game_day(game_day)
