extends Resource
class_name BattleCardPrimaryEffect

enum EffectMode {Damage, Defence, Heal}

@export
var mode: EffectMode

func mode_name() -> String:
    match mode:
        EffectMode.Damage: return "⚔" # "DMG"
        EffectMode.Defence: return "🛡" # "DEF"
        EffectMode.Heal: return "♥" # HEAL"
        _:
            push_error("%s not known mode" % mode)
            print_stack()
            return ""

const TARGET_NOTHING: int = 0
const TARGET_ENEMIES: int = 1
const TARGET_ALLIES: int = 2
const TARGET_ONE: int = 4
const TARGET_TWO: int = 8
const TARGET_THREE: int = 16
const TARGET_ALL: int = 32
const TARGET_RANDOM: int = 64

const TARGET_RANGE_ALL_VALUE: int = 999

@export_flags("Enemies", "Allies", "One", "Two", "Three", "All", "Random")
var target: int

func targets_random() -> bool:
    return (target & TARGET_RANDOM) == TARGET_RANDOM

func targets_enemies() -> bool:
    return (target & TARGET_ENEMIES) == TARGET_ENEMIES

func targets_allies() -> bool:
    return (target & TARGET_ALLIES) == TARGET_ALLIES

func get_target_range() -> Array[int]:
    var target_range: Array[int] = [0, 0]

    if (target & TARGET_ONE) == TARGET_ONE:
        target_range[0] = 1
        target_range[1] = 1

    if (target & TARGET_TWO) == TARGET_TWO:
        target_range[0] = 2 if target_range[0] == 0 else target_range[0]
        target_range[1] = 2

    if (target & TARGET_THREE) == TARGET_THREE:
        target_range[0] = 3 if target_range[0] == 0 else target_range[0]
        target_range[1] = 3

    if (target & TARGET_ALL) == TARGET_ALL:
        target_range[0] = TARGET_RANGE_ALL_VALUE if target_range[0] == 0 else target_range[0]
        target_range[1] = TARGET_RANGE_ALL_VALUE

    return target_range

func get_single_target() -> bool:
    return (
        (target & TARGET_ONE) == TARGET_ONE &&
        (target & TARGET_TWO) == TARGET_NOTHING &&
        (target & TARGET_THREE) == TARGET_NOTHING &&
        (target & TARGET_ALL) == TARGET_NOTHING
)

static func target_range_text(target_range: Array[int]) -> String:
    if target_range[0] == target_range[1]:
        if target_range[0] == TARGET_RANGE_ALL_VALUE:
            return "all"

        return str(target_range[0])

    return "%s - %s" % [
        target_range[0],
        "all" if target_range[1] == TARGET_RANGE_ALL_VALUE else str(target_range[1]),
    ]

func target_type_text() -> String:
    var allies: bool = targets_allies()
    var enemies: bool = targets_enemies()
    # var single: bool = get_single_target()

    if targets_random():
        if allies && enemies:
            return "🎲🧍👾" # "anyone, random"
        elif allies:
            return "🎲🧍" # "allies, random" if !single else "ally, random"
        elif enemies:
            return "🎲👾" # "enemies, random" if !single else "enemy, random"
        return "no-one"
    else:
        if allies && enemies:
            return "🧍👾" # "anyone"
        elif allies:
            return "🧍" # "allies" if !single else "ally"
        elif enemies:
            return "👾" # "enemies" if !single else "enemy"
        return "no-one"



@export
var min_effect: int

@export
var max_effect: int

@export
var effect_crit_base: int

@export
var crits_on_allies: bool = true

@export
var crits_on_enemies: bool = true

func can_crit() -> bool:
    return effect_crit_base != 0 && (crits_on_allies || crits_on_enemies)

func get_effect_range(crit_multiplyer: int) -> Array[int]:
    var crit: int = effect_crit_base * crit_multiplyer
    return [max(0, min_effect + min_effect * crit), max(0, max_effect + max_effect * crit)]

func calculate_effect(crit_multiplyer: int, ally: bool) -> int:
    var allow_crit: bool = ally && crits_on_allies || !ally && crits_on_enemies
    var effect_range: Array[int] = get_effect_range(crit_multiplyer if allow_crit else 0)
    return randi_range(effect_range[0], effect_range[1])
