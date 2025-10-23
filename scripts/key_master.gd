extends KeyMasterCore
class_name KeyMaster

func get_description(key: String) -> String:
    return _key_descriptions.get(key, GCLootableManager.translate(GCLootableManager.ITEM_GENERIC_KEY))
