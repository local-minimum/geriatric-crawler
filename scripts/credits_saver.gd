extends SaveExtension
class_name CreditsSaver

const _CREDITS_KEY: String = "value"

func get_key() -> String:
    return "credits"

func load_from_initial_if_save_missing() -> bool:
    return true

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _CREDITS_KEY: Inventory.credits(),
    }

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {
        _CREDITS_KEY: 0
    }

func load_from_data(extentsion_save_data: Dictionary) -> void:
    var credits: int = DictionaryUtils.safe_geti(extentsion_save_data, _CREDITS_KEY)
    Inventory.set_credits(credits)
