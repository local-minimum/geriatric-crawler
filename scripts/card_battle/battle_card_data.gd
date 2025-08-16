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

static func _card_category_name(category: CardCategory, enemy_variant_id: String = "") -> String:
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
    var key: String = _card_category_name(category, enemy_id)
    var cards: Dictionary[String, BattleCardData] = _ALL_CARD.get(key)

    var dir_path: String = _card_category_path(category, enemy_id)
    for file_name: String in DirAccess.get_files_at(dir_path):
        if file_name.get_extension() == "import":
            file_name = file_name.replace(".import", "")
            if file_name.get_extension() != "tres":
                continue
            var resource: Resource = ResourceLoader.load("%s%s" % [dir_path, file_name])

            if resource is BattleCardData:
                var card: BattleCardData = resource

                cards[card.id] = card as BattleCardData

    _ALL_CARD[key] = cards

static func get_card_by_id(category: CardCategory, card_id: String, enemy_id: String = "") -> BattleCardData:
    var key: String = _card_category_name(category, enemy_id)
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

@export var name: String

enum Owner { SELF, ALLY, ENEMY }

static func name_owner(owner: Owner) -> String:
    match owner:
        Owner.SELF:
            return "Self/Player"
        Owner.ALLY:
            return "Ally"
        Owner.ENEMY:
            return "Enemy"
        _:
            push_error("Owner %s not handled" % owner)
            return "Unknown (%s)" % owner


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
        SUIT_NONE: return "None"
        SUIT_ELECTRICITY: return "Electricity"
        SUIT_METAL: return "Metal"
        SUIT_DATA: return "Data"
        _:
            push_error("%s is not a battle card suite flag" % suit_flag)
            print_stack()
            return ""

@export var icon: Texture

@export var primary_effects: Array[BattleCardPrimaryEffect] = []

@export var secondary_effects: Array[SecondaryEffect] = []

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
        SecondaryEffect.SUITED_UP: return "Suited Up"
        SecondaryEffect.ACCELERATED: return "Accelerated"
        SecondaryEffect.SOLID: return "Solid"
        SecondaryEffect.BREAKING: return "Breaking"
        SecondaryEffect.IMPOSING: return "Imposing"
        _:
            push_error("%s doesn't have a name" % effect)
            print_stack()
            return ""

static func secondary_effect_tooltip(effect: SecondaryEffect) -> String:
    match effect:
        SecondaryEffect.SUITED_UP: return "Must be matching suits on both sides to not break bonus"
        SecondaryEffect.ACCELERATED: return "Keeping crit duplicates bonus, breaking causes negative bonus"
        SecondaryEffect.SOLID: return "Crit multiplier cannot break due to this card"
        SecondaryEffect.BREAKING: return "Forces crit multiplier to be set to negative"
        SecondaryEffect.IMPOSING: return "Secondary effects also trigger while card is in hand"
        _:
            push_error("%s doesn't have a name" % effect)
            print_stack()
            return ""
