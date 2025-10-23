class_name GCLootableManager

enum LootClass {
    NONE,
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

const _ELEMENT_PREFIX: String = "ELEM_"
const ITEM_ELEM_IRON: String = "FE"
const ITEM_ELEM_ALUMINUM: String = "AL"
const ITEM_ELEM_GOLD: String = "AU"
const ITEM_ELEM_COPPER: String = "CU"
const ITEM_ELEM_HYDROGEN: String = "H"
const ITEM_ELEM_CARBON: String = "C"
const ITEM_ELEM_SILICON: String = "SI"
const ITEM_ELEM_TIN: String = "SN"
const ITEM_ELEM_TITANIUM: String = "TI"

const _COMPONENT_PREFIX: String = "COMP_"
const ITEM_COMP_CPU: String = "CPU"
const ITEM_COMP_MEMORY: String = "MEM"

const _SUBSTANCE_PREFIX: String = "SUB_"
const ITEM_SUB_PLASTIC: String = "PLASTIC"
const ITEM_SUB_RUBBER: String = "RUBBER"

static func _translation_key_prefix(item_id: String) -> String:
    return _translation_cateogry_prefix(classify_loot(item_id))

static func _translation_cateogry_prefix(category: LootClass) -> String:
    match category:
        LootClass.HACKING: return _HACKING_PREFIX
        LootClass.KEY: return _KEY_PREFIX
        LootClass.ELEMENT: return _ELEMENT_PREFIX
        LootClass.COMPONENT: return _COMPONENT_PREFIX
        LootClass.SUBSTANCE: return _SUBSTANCE_PREFIX

        _: return _GENERAL_PREFIX

static func _translation_key(item_id: String) -> String:
    return "%s%s%s" % [_PREFIX, _translation_key_prefix(item_id), item_id.to_upper()]

static func _translation_category_key(category: LootClass) -> String:
    return "%s%sCATEGORY" % [_PREFIX, _translation_cateogry_prefix(category)]

static func classify_loot(item_id: String) -> LootClass:
    match item_id.to_upper():
        ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY:
            return LootClass.HACKING

        ITEM_PURPLE_KEY, ITEM_GENERIC_KEY:
            return LootClass.KEY

        ITEM_ELEM_ALUMINUM, ITEM_ELEM_IRON, ITEM_ELEM_CARBON, ITEM_ELEM_COPPER, ITEM_ELEM_GOLD, ITEM_ELEM_HYDROGEN, ITEM_ELEM_SILICON, ITEM_ELEM_TIN, ITEM_ELEM_TITANIUM:
            return LootClass.ELEMENT

        ITEM_COMP_CPU, ITEM_COMP_MEMORY:
            return LootClass.COMPONENT

        ITEM_SUB_PLASTIC, ITEM_SUB_RUBBER:
            return LootClass.SUBSTANCE

        _: return LootClass.GENERAL

static func list_item_ids(category: LootClass) -> Array[String]:
    match category:
        LootClass.HACKING:
            return [ITEM_HACKING_BOMB, ITEM_HACKING_WORM, ITEM_HACKING_PROXY]

        LootClass.KEY:
            return [ITEM_PURPLE_KEY, ITEM_GENERIC_KEY]

        LootClass.ELEMENT:
            return [ITEM_ELEM_ALUMINUM, ITEM_ELEM_IRON, ITEM_ELEM_CARBON, ITEM_ELEM_COPPER, ITEM_ELEM_GOLD, ITEM_ELEM_HYDROGEN, ITEM_ELEM_SILICON, ITEM_ELEM_TIN, ITEM_ELEM_TITANIUM]

        LootClass.COMPONENT:
            return [ITEM_COMP_CPU, ITEM_COMP_MEMORY]

        LootClass.SUBSTANCE:
            return [ITEM_SUB_PLASTIC, ITEM_SUB_RUBBER]

        _:
            return []

static func translate(item_id: String, count: int = 1) -> String:
    var key: String = _translation_key(item_id)
    return __GlobalGameState.tr_n(key, "%s_PL" % key, count)

static func translate_cateogry(category: LootClass, count: int = 1) -> String:
    var key: String = _translation_category_key(category)
    return __GlobalGameState.tr_n(key, "%s_PL" % key, count)

static func unit(id: String, use_alt: bool = false) -> String:
    match classify_loot(id):
        LootClass.SUBSTANCE, LootClass.ELEMENT:
            return __GlobalGameState.tr("UNIT_KG")
        _:
            if use_alt:
                return __GlobalGameState.tr("UNIT_COUNT_ALT")
            return ""

static func categorize(item_ids: Array[String]) -> Dictionary[LootClass, Array]:
    var results: Dictionary[LootClass, Array] = {}

    for item_id: String in item_ids:
        var category: LootClass = classify_loot(item_id)
        if results.has(category):
            results[category].append(item_id)
        else:
            var category_items: Array[String] = [item_id]
            results[category] = category_items

    return results
