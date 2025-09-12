class_name LootableManager

enum LootClass {
    GENERAL,
    HACKING,
    ELEMENT,
    SUBSTANCE,
    COMPONENT,
    KEY,
}

const _PREFIX: String = "ITEM_"

const _ITEM_HACKING_PREFIX: String = "HACKING_"
const ITEM_HACKING_WORM: String = "WORM"
const ITEM_HACKING_BOMB: String = "BOMB"
const ITEM_HACKING_PROXY: String = "PROXY"

const _GENERAL_PREFIX: String = "GENERAL_"

static func translation_key(item_id: String) -> String:
    match item_id.to_upper():
        ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY:
            return "%s%s%s" % [_PREFIX, _ITEM_HACKING_PREFIX, item_id.to_upper()]
        _: return "%s%s%s" % [_PREFIX, _GENERAL_PREFIX, item_id.to_upper()]

static func classify_loot(item_id: String) -> LootClass:
    match item_id:
        ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY:
            return LootClass.HACKING
        _: return LootClass.GENERAL


static func translate(item_id: String, count: int = 1) -> String:
    var key: String = translation_key(item_id)
    return __GlobalGameState.tr_n(key, "%s_PL" % key, count)
