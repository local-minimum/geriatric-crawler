extends Resource
class_name BattleCardData

const SUIT_NONE: int = 0
const SUIT_ELECTRICITY: int = 1
const SUIT_METAL: int = 2
const SUIT_DATA: int = 4

const ALL_SUITES: Array[int] = [SUIT_ELECTRICITY, SUIT_METAL, SUIT_DATA]
enum CardCategory {Player, Enemy, Punishment}

enum SecondaryEffect {
    ## There must be matching suit on both sides to not break crit
    SUITED_UP,
    ## Keeping crit multiplies it by x2, breaking causes negative crit
    ACCELERATED,
    ## Cannot break crit multipliers
    SOLID,
    ## Forces crit multipliers to be reset
    BREAKING,
    ## Secondary effects trigger while card is held in hand
    IMPOSING,
}

static var _ALL_CARD: Dictionary[String, Dictionary] = {}

static func _card_category_id(category: CardCategory, enemy_variant_id: String = "") -> String:
    match category:
        CardCategory.Player: return "player"
        CardCategory.Enemy:
            if enemy_variant_id != "":
                return "enemy-%s" % enemy_variant_id
            return "enemy"
        _: return "unknown"

static func _card_category_path(category: CardCategory, enemy_variant_id: String = "") -> String:
    match category:
        CardCategory.Player: return "res://resources/player_cards"
        CardCategory.Enemy:
            if enemy_variant_id != "" && !enemy_variant_id.contains("/") && !enemy_variant_id.contains("."):
                return "res://resources/enemy_cards/%s_cards" % enemy_variant_id

            return "res://resources/enemy_cards"
        CardCategory.Punishment:
            return "res://resources/punishment_cards"
        _: return "res://resources/other_cards"

static func _load_cards_cateogry(category: CardCategory, enemy_id: String = "") -> void:
    var key: String = _card_category_id(category, enemy_id)
    var cards: Dictionary = _ALL_CARD.get(key, {})

    var dir_path: String = _card_category_path(category, enemy_id)
    print_debug("Loading Cards in %s" % dir_path)

    for file_name: String in DirAccess.get_files_at(dir_path):
        # print_debug("Loading Cards considering %s" % file_name)

        if file_name.get_extension() != "tres":
            continue

        var resource: Resource = ResourceLoader.load("%s/%s" % [dir_path, file_name])

        if resource is BattleCardData:
            var card: BattleCardData = resource

            cards[card.id] = card as BattleCardData

            # print_debug("Loading Card %s" % card.id)

    _ALL_CARD[key] = cards

static func get_card_by_id(category: CardCategory, card_id: String, enemy_id: String = "") -> BattleCardData:
    var key: String = _card_category_id(category, enemy_id)
    if !_ALL_CARD.has(key):
        _load_cards_cateogry(category, enemy_id)

    var items: Dictionary = DictionaryUtils.safe_getd(_ALL_CARD, key)
    var item: Variant = items.get(card_id)
    if item is BattleCardData:
        return item

    return null

@export var id: String

func base_id() -> String:
    return id.substr(0, id.rfind("-"))

## Only gives the localization key for the card
@export var name: String

func localized_name() -> String: return tr(name)

enum Owner { SELF, ALLY, ENEMY }

static func name_owner(owner: Owner) -> String:
    match owner:
        Owner.SELF:
            return __GlobalGameState.tr("SELF")
        Owner.ALLY:
            return __GlobalGameState.tr("ALLY")
        Owner.ENEMY:
            return __GlobalGameState.tr("ENEMY")
        _:
            push_error("Owner %s not handled" % owner)
            return __GlobalGameState.tr("UNKNOWN_ID").format({"type": __GlobalGameState.tr("OWNER"), "id": owner})

@export var card_owner: Owner

@export var rank: int

@export_flags("Electricity", "Metal", "Data") var suit: int = 0

func suits() -> Array[int]:
    var flags: Array[int] = []

    for flag: int in ALL_SUITES:
        if has_suit(flag):
            flags.append(flag)

    return flags

func has_suit(flag: int) -> bool:
    return (suit & flag) == flag

func has_suit_intersection(other: BattleCardData) -> bool:
    return other != null && (suit & other.suit) != SUIT_NONE

func has_identical_suit(other: BattleCardData) -> bool:
    return other != null && suit != SUIT_NONE && (suit & other.suit) == suit

func suit_names() -> Array[String]:
    var flags: Array[String] = []
    for flag: int in ALL_SUITES:
        if has_suit(flag):
            flags.append(BattleCardData.suit_name(flag))

    return flags

static func suit_name(suit_flag: int) -> String:
    match suit_flag:
        SUIT_NONE: return __GlobalGameState.tr("SUIT_NONE")
        SUIT_ELECTRICITY: return __GlobalGameState.tr("SUIT_ELECTRICTY")
        SUIT_METAL: return __GlobalGameState.tr("SUITE_METAL")
        SUIT_DATA: return __GlobalGameState.tr("SUIT_DATA")
        _:
            push_error("%s is not a battle card suite flag" % suit_flag)
            print_stack()
            return __GlobalGameState.tr("UNKNOWN_ID").format({"type": __GlobalGameState.tr("SUIT"), "id": suit_flag})

@export var icon: Texture

@export var primary_effects: Array[BattleCardPrimaryEffect] = []

@export var secondary_effects: Array[SecondaryEffect] = []

## Returns the localized secondary effect names
func secondary_effect_names() -> Array[String]:
    var names: Array[String] = []
    for effect: SecondaryEffect in secondary_effects:
        names.append(secondary_effect_name(effect))

    return names

func secondary_effect_tooltips() -> Array[String]:
    var names: Array[String] = []
    for effect: SecondaryEffect in secondary_effects:
        names.append(secondary_effect_tooltip(effect))

    return names

static func secondary_effect_name(effect: SecondaryEffect) -> String:
    match effect:
        SecondaryEffect.SUITED_UP: return __GlobalGameState.tr("EFFECT_SUITED_UP")
        SecondaryEffect.ACCELERATED: return __GlobalGameState.tr("EFFECT_ACCELERATED")
        SecondaryEffect.SOLID: return __GlobalGameState.tr("EFFECT_SOLID")
        SecondaryEffect.BREAKING: return __GlobalGameState.tr("EFFECT_BREAKING")
        SecondaryEffect.IMPOSING: return __GlobalGameState.tr("EFFECT_IMPOSING")
        _:
            push_error("%s doesn't have a name" % effect)
            print_stack()
            return __GlobalGameState.tr("UNKNOWN_ID").format({"type": __GlobalGameState.tr("EFFECT"), "id": effect})

static func secondary_effect_tooltip(effect: SecondaryEffect) -> String:
    match effect:
        SecondaryEffect.SUITED_UP: return __GlobalGameState.tr("EFFECT_SUITED_UP_DESC")
        SecondaryEffect.ACCELERATED: return __GlobalGameState.tr("EFFECT_ACCELERATED_DESC")
        SecondaryEffect.SOLID: return __GlobalGameState.tr("EFFECT_SOLID_DESC")
        SecondaryEffect.BREAKING: return __GlobalGameState.tr("EFFECT_BREAKING_DESC")
        SecondaryEffect.IMPOSING: return __GlobalGameState.tr("EFFECT_IMPOSING_DESC")
        _:
            push_error("%s doesn't have a name" % effect)
            print_stack()
            return __GlobalGameState.tr("UNKNOWN_ID").format({"type": __GlobalGameState.tr("EFFECT"), "id": effect})
