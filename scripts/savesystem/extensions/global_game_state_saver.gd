extends GlobalGameStateCoreSaver
class_name GlobalGameStateSaver

const _LOANS_KEY: String = "loans"

const _INTEREST_RATE_KEY: String = "interest-rate"

const _RENT_KEY: String = "rent"


func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return super.retrieve_data(_extentsion_save_data).merged({
        _INTEREST_RATE_KEY: __GlobalGameState._interest_rate_points,
        _LOANS_KEY: __GlobalGameState._loans,
        _RENT_KEY: __GlobalGameState._rent,
    }, true)

func load_from_data(extentsion_save_data: Dictionary) -> void:
    super.load_from_data(extentsion_save_data)

    var loans: int = DictionaryUtils.safe_geti(extentsion_save_data, _LOANS_KEY, 0, false)
    __GlobalGameState.set_loans(loans)

    var interest_rate: int = DictionaryUtils.safe_geti(extentsion_save_data, _INTEREST_RATE_KEY, GlobalGameState.BASE_INTEREST_RATE, false)
    __GlobalGameState.set_interest_rate(interest_rate)

    var rent: int = DictionaryUtils.safe_geti(extentsion_save_data, _RENT_KEY, 0, false)
    __GlobalGameState.set_rent(rent)
