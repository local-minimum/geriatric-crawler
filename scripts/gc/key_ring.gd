extends KeyRingCore
class_name KeyRing

static func is_key(id: String) -> bool:
    return LootableManager.classify_loot(id) == LootableManager.LootClass.KEY
