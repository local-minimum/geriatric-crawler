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

const _HACKING_PREFIX: String = "HACKING_"
const ITEM_HACKING_WORM: String = "WORM"
const ITEM_HACKING_BOMB: String = "BOMB"
const ITEM_HACKING_PROXY: String = "PROXY"

const _GENERAL_PREFIX: String = "GENERAL_"

const _KEY_PREFIX: String = ""
const ITEM_PURPLE_KEY: String = "KEY_PURPLE"
const ITEM_GENERIC_KEY: String = "KEY_GENERIC"

static func _translation_key_prefix(item_id: String) -> String:
    match item_id.to_upper():
        ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY:
            return _HACKING_PREFIX

        ITEM_PURPLE_KEY:
            return _KEY_PREFIX

        _: return _GENERAL_PREFIX

static func translation_key(item_id: String) -> String:
    return "%s%s%s" % [_PREFIX, _translation_key_prefix(item_id), item_id.to_upper()]

static func classify_loot(item_id: String) -> LootClass:
    match item_id:
        ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY:
            return LootClass.HACKING

        ITEM_PURPLE_KEY:
            return LootClass.KEY

        _: return LootClass.GENERAL

static func translate(item_id: String, count: int = 1) -> String:
    var key: String = translation_key(item_id)
    return __GlobalGameState.tr_n(key, "%s_PL" % key, count)

static func unit(id: String) -> String:
    match LootableManager.classify_loot(id):
        LootableManager.LootClass.SUBSTANCE, LootableManager.LootClass.ELEMENT:
            return __GlobalGameState.tr("UNIT_KG")
        _:
            return __GlobalGameState.tr("UNIT_COUNT")
