extends SaveVersionMigration

@export var applies_to: Version
@export var global_state_saver: GlobalGameStateSaver

const _CREDITS_SAVE: String = "credits"
const _CREDITS_VALUE_KEY: String = "value"

func applicable(save_version: Version) -> bool:
    return applies_from.higher_or_equal(save_version) && applies_to.lower_or_equal(save_version)

func migrate_save(save_data: Dictionary) -> Dictionary:
    if global_state_saver == null || save_data.has(global_state_saver.get_key()) || !save_data.has(_CREDITS_SAVE):
        return save_data

    var credits_save: Dictionary = DictionaryUtils.safe_getd(save_data, _CREDITS_SAVE)
    var credits: int = DictionaryUtils.safe_geti(credits_save, _CREDITS_VALUE_KEY)

    @warning_ignore_start("return_value_discarded")
    save_data.erase(_CREDITS_SAVE)
    @warning_ignore_restore("return_value_discarded")

    save_data[global_state_saver.get_key()] = {
        GlobalGameStateSaver._CREDITS_KEY: credits,
        GlobalGameStateSaver._LOANS_KEY: 0,
        GlobalGameStateSaver._RENT_KEY: 0,
        GlobalGameStateSaver._GAME_DAY_KEY: 0,
        GlobalGameStateSaver._INTEREST_RATE_KEY: GlobalGameState.BASE_INTEREST_RATE
    }

    return save_data
