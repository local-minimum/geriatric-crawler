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
    selected_abilities: Array[RobotAbility],
    completed_fights: int,
    total_fights: int,
    credits: int,
    can_buy_multiple: bool,
    available_slots: int,
) -> void:
    _fights.sync(completed_fights, total_fights)
    _level_title.text = "TIER %s" % IntUtils.to_roman(level)

    var bought_for_level: bool = !selected_abilities.is_empty()
    var ready_to_buy: bool = completed_fights >= total_fights && available_slots > 0 && (!bought_for_level || can_buy_multiple)
    for idx: int in range(_skills.size()):
        if idx < abilities.size():
            var ability: RobotAbility = abilities[idx]
            # TODO: Calculate cost somehow
            var cost: int  = 100
            var state: RobotSkillUI.State = RobotSkillUI.State.Bought if selected_abilities.has(ability) else RobotSkillUI.State.NotBought
            if !bought_for_level || can_buy_multiple:
                state = RobotSkillUI.State.Buyable if ready_to_buy && cost < credits else RobotSkillUI.State.Option
            _skills[idx].sync(abilities[idx], state)
            _skills[idx].visible = true
        else:
            _skills[idx].visible = false

    if _skills.size() < abilities.size():
        push_error("Cannot show all %s abilities because we only have %s slots" % [abilities.size(), _skills.size()])
