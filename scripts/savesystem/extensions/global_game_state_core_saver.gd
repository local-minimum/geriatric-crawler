extends SaveExtension
class_name GlobalGameStateCoreSaver

const _CREDITS_KEY: String = "credits"
const _GAME_DAY_KEY: String = "day"

@export var _save_key: String = "globals"

func get_key() -> String:
    return _save_key



func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _CREDITS_KEY: __GlobalGameState._credits,
        _GAME_DAY_KEY: __GlobalGameState.game_day
    }

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var credits: int = DictionaryUtils.safe_geti(extentsion_save_data, _CREDITS_KEY, 0, false)
    __GlobalGameState.set_credits(credits)

    var game_day: int = DictionaryUtils.safe_geti(extentsion_save_data, _GAME_DAY_KEY, 0, false)
    __GlobalGameState.set_game_day(game_day)
