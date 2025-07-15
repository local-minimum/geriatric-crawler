extends Control
class_name RobotSkillLevelUI

@export
var _fights: RobotSkillLevelFightsUI

@export
var _level_title: Label

@export
var _skills: Array[RobotSkillUI]

func sync(
    level: int,
    abilities: Array[RobotAbility],
    selected_ability: RobotAbility,
    completed_fights: int,
    total_fights: int,
    credits: int,
) -> void:
    _fights.sync(completed_fights, total_fights)
    _level_title.text = "LEVEL %s" % IntUtils.to_roman(level)

    var bought: bool = selected_ability != null
    var ready_to_buy: bool = completed_fights >= total_fights && !bought
    for idx: int in range(_skills.size()):
        if idx < abilities.size():
            var ability: RobotAbility = abilities[idx]
            # TODO: Calculate cost somehow
            var cost: int  = 1000
            var state: RobotSkillUI.State = RobotSkillUI.State.Buyable if ready_to_buy && credits > cost else RobotSkillUI.State.Option
            if bought:
                state = RobotSkillUI.State.Bought if selected_ability == ability else RobotSkillUI.State.NotBought
            _skills[idx].sync(abilities[idx], state)
            _skills[idx].visible = true
        else:
            _skills[idx].visible = false

    if _skills.size() < abilities.size():
        push_error("Cannot show all %s abilities because we only have %s slots" % [abilities.size(), _skills.size()])
