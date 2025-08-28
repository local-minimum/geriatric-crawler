extends Resource
class_name RobotModel

@export var id: String

@export var model_name: String

@export var innate_abilities: Array[RobotAbility]

@export var level_1_options: Array[RobotAbility]

@export var level_2_options: Array[RobotAbility]

@export var level_3_options: Array[RobotAbility]

@export var level_4_options: Array[RobotAbility]

@export_range(1, 6) var level_1_steps: int = 3

@export_range(1, 6) var level_2_steps: int = 4

@export_range(1, 6) var level_3_steps: int = 5

@export_range(1, 6) var level_4_steps: int = 6

@export var starter_deck: Array[BattleCardData]

@export var max_hp: int = 20

@export var production: RobotProductionCost

func get_level(steps: int) -> int:
    if steps < level_1_steps:
        return 1
    steps -= level_1_steps

    if steps < level_2_steps:
        return 2
    steps -= level_2_steps

    if steps < level_3_steps:
        return 3
    steps -= level_3_steps

    if steps < level_4_steps:
        return 4

    return 5

func get_completed_level(steps: int) -> int:
    if steps < level_1_steps:
        return 0
    steps -= level_1_steps

    if steps < level_2_steps:
        return 1
    steps -= level_2_steps

    if steps < level_3_steps:
        return 2
    steps -= level_3_steps

    if steps < level_4_steps:
        return 3

    return 4

func get_level_required_steps(level: int) -> int:
    match level:
        0: return 0
        1: return level_1_steps
        2: return level_2_steps
        3: return level_3_steps
        4: return level_4_steps
        _: return -1

func get_completed_steps_on_level(steps: int, level: int) -> int:
    if level <= 1:
        return steps

    steps -= level_1_steps
    if level == 2:
        return steps

    steps -= level_2_steps
    if level == 3:
        return steps

    steps -= level_3_steps
    return steps

func get_completed_steps_on_current_level(steps: int) -> int:
    if steps <= level_1_steps:
        return steps

    steps -= level_1_steps
    if steps <= level_2_steps:
        return steps

    steps -= level_2_steps
    if steps <= level_3_steps:
        return steps

    steps -= level_3_steps
    if steps <= level_4_steps:
        return steps

    return steps - level_4_steps

func get_remaining_steps_on_current_level(steps: int) -> int:
    if steps <= level_1_steps:
        return level_1_steps - steps

    steps -= level_1_steps
    if steps <= level_2_steps:
        return level_2_steps - steps

    steps -= level_2_steps
    if steps <= level_3_steps:
        return level_3_steps - steps

    steps -= level_3_steps
    if steps <= level_4_steps:
        return level_4_steps - steps

    return 99

func get_level_options(level: int) -> Array[RobotAbility]:
    match level:
        0: return innate_abilities
        1: return level_1_options
        2: return level_2_options
        3: return level_3_options
        4: return level_4_options

    return []

func find_skill_level(ability: RobotAbility) -> int:
    if innate_abilities.has(ability): return 0
    if level_1_options.has(ability): return 1
    if level_2_options.has(ability): return 2
    if level_3_options.has(ability): return 3
    if level_4_options.has(ability): return 4

    return -1

func find_skill(full_id: String) -> RobotAbility:
    var filter: Callable = func (option: RobotAbility) -> bool: return option.full_id() == full_id

    for options: Array in [innate_abilities, level_1_options, level_2_options, level_3_options, level_4_options]:
        var idx: int = innate_abilities.find_custom(filter)
        if idx >= 0:
            return innate_abilities[idx]

    return null

func count_available_options(max_level: int, aquired: Array[RobotAbility]) -> int:
    var count: int = 0
    var filt: Callable = func (option: RobotAbility) -> bool: return !aquired.has(option)

    if max_level >= 1:
        count += level_1_options.filter(filt).size()

    if max_level >= 2:
        count += level_2_options.filter(filt).size()

    if max_level >= 3:
        count += level_3_options.filter(filt).size()

    if max_level >= 4:
        count += level_4_options.filter(filt).size()

    return count
