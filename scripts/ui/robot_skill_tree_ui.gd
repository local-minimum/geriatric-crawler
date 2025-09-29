extends Control
class_name RobotSkillTreeUI

@export var _levels: Array[RobotSkillLevelUI]

func sync(robot: Robot, credits: int) -> void:
    var ability_lvl: int = robot.get_skill_level(RobotAbility.SKILL_UPGRADES)
    var can_buy_multiple: bool = ability_lvl >= 3
    var can_skip_buy_tier: bool = ability_lvl >= 2

    var prev_lvl_bought: bool = true

    for level_idx: int in range(_levels.size()):
        var level_number: int = level_idx + 1
        var level: RobotSkillLevelUI = _levels[level_idx]
        var options: Array[RobotAbility] = robot.model.get_level_options(level_number) if robot.model != null else []
        var selected_option: Array[RobotAbility] = robot.get_obtained_abilities(level_number) if robot.model != null else []
        var completed_fights: int = robot.get_fights_done_on_level(level_number)
        var total_fights: int = robot.model.get_level_required_steps(level_number)

        level.sync(
            level_number,
            options,
            selected_option,
            completed_fights,
            total_fights,
            credits,
            can_buy_multiple,
            robot.available_upgrade_slots() if prev_lvl_bought || can_skip_buy_tier else -1,
            robot.obtain_upgrade,
        )

        prev_lvl_bought = !selected_option.is_empty()
