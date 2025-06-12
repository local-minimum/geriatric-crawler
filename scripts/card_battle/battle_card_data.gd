extends Resource
class_name BattleCardData

const SUIT_NONE: int = 0
const SUIT_ELECTRICITY: int = 1
const SUIT_METAL: int = 2
const SUIT_DATA: int = 4

const ALL_SUITES: Array[int] = [SUIT_ELECTRICITY, SUIT_METAL, SUIT_DATA]

@export
var id: String

@export
var name: String

enum Owner { Self, Ally }

@export
var card_owner: Owner

@export
var rank: int

@export_flags("Electricity", "Metal", "Data")
var suit: int = 0

func suits() -> Array[int]:
    var flags: Array[int] = []

    for flag: int in ALL_SUITES:
        if has_suit(flag):
            flags.append(flag)

    return flags

func has_suit(flag: int) -> bool:
    return (suit & flag) == flag

func has_suit_intersection(other: BattleCardData) -> bool:
    return (suit & other.suit) != SUIT_NONE

func has_identical_suit(other: BattleCardData) -> bool:
    return (suit & other.suit) == suit

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

@export
var icon: Texture

@export
var primary_effects: Array[BattleCardPrimaryEffect] = []

enum SecondaryEffect {
    ## There must be matching suit on both sides to not break crit
    SuitedUp,
    ## Keeping crit multiplies it by x2, breaking causes negative crit
    Accelerated,
}

@export
var secondary_effects: Array[SecondaryEffect] = []

func secondary_effect_names() -> Array[String]:
    var names: Array[String] = []
    for effect: SecondaryEffect in secondary_effects:
        names.append(secondary_effect_name(effect))

    return names

static func secondary_effect_name(effect: SecondaryEffect) -> String:
    match effect:
        SecondaryEffect.SuitedUp: return "Suited Up"
        SecondaryEffect.Accelerated: return "Accelerated"
        _:
            push_error("%s doesn't have a name" % effect)
            print_stack()
            return ""
