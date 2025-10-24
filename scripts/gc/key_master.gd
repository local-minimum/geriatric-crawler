extends KeyMasterCore
class_name KeyMaster

func get_description(key: String) -> String:
    return _key_descriptions.get(key, LootableManager.translate(LootableManager.ITEM_GENERIC_KEY))
