extends Control
class_name RobotSkillTreeUI

@export
var _levels: Array[RobotSkillLevelUI]

func sync(robot: Robot, credits: int) -> void:
    for level_idx: int in range(_levels.size()):
        var level_number: int = level_idx + 1
        var level: RobotSkillLevelUI = _levels[level_idx]
        var options: Array[RobotAbility] = robot.model.get_level_options(level_number)
        var selected_option: RobotAbility = robot.get_obtained_ability(level_number)
        var completed_fights: int = robot.get_fights_done_on_level(level_number)
        var total_fights: int = robot.model.get_level_required_steps(level_number)

        level.sync(level_number, options, selected_option, completed_fights, total_fights, credits)
