extends SaveExtension
class_name CreditsSaver

const _CREDITS_KEY: String = "value"
const _LOANS_KEY: String = "loans"

func get_key() -> String:
    return "credits"

func load_from_initial_if_save_missing() -> bool:
    return true

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _CREDITS_KEY: __GlobalGameState.total_credits,
        _LOANS_KEY: __GlobalGameState.loans
    }

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _CREDITS_KEY: 0,
        _LOANS_KEY: 0,
    }

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var credits: int = DictionaryUtils.safe_geti(extentsion_save_data, _CREDITS_KEY)
    var loans: int = DictionaryUtils.safe_geti(extentsion_save_data, _LOANS_KEY)
    __GlobalGameState.set_credits(credits, loans)
