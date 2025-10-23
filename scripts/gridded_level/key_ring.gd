extends KeyRingCore
class_name KeyRing

static func is_key(id: String) -> bool:
    return GCLootableManager.classify_loot(id) == GCLootableManager.LootClass.KEY
