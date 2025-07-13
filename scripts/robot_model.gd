extends Resource
class_name RobotModel

@export
var innate_abilities: Array[RobotAbility]

@export
var level_1_options: Array[RobotAbility]

@export
var level_2_options: Array[RobotAbility]

@export
var level_3_options: Array[RobotAbility]

@export
var level_4_options: Array[RobotAbility]

@export_range(1, 6)
var level_1_steps: int = 3

@export_range(1, 6)
var level_2_steps: int = 4

@export_range(1, 6)
var level_3_steps: int = 5

@export_range(1, 6)
var level_4_steps: int = 6

func get_level(steps: int) -> int:
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

func get_level_options(level: int) -> Array[RobotAbility]:
    match level:
        0: return innate_abilities
        1: return level_1_options
        2: return level_2_options
        3: return level_3_options
        4: return level_4_options

    return []

func get_skill(full_id: String, level: int) -> RobotAbility:
    var options: Array[RobotAbility] = get_level_options(level)
    var idx: int = options.find_custom(func (option: RobotAbility) -> bool: return option.full_id() == full_id)
    if idx < 0:
        return null
    return options[idx]
