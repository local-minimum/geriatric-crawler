extends Node
class_name Robot

@export
var model: RobotModel

@export
var given_name: String

var _obtained_level_abilities: Array[RobotAbility]

var _fights: int

func obtained_level() -> int: return _obtained_level_abilities.size()

func can_level_up() -> bool: return model.get_level(_fights) > obtained_level()

func get_highest_level(skill: String) -> int:
    var level: int = ArrayUtils.maxi(
        _obtained_level_abilities.filter(func (ability: RobotAbility) -> bool: return ability.id == skill),
        func (item: RobotAbility) -> int: return item.skill_level,
    )

    if model == null:
        return level


    return ArrayUtils.maxi(
        model.innate_abilities.filter(func (ability: RobotAbility) -> bool: return ability.id == skill),
        func (item: RobotAbility) -> int: return item.skill_level,
        level
    )

func set_level_reward(reward_full_id: String) -> void:
    var reward_level: int = obtained_level() + 1
    var reward: RobotAbility = model.get_skill(reward_full_id, reward_level)
    if reward == null:
        push_error("Reward %s not a proper level %s reward for %s" % [reward_full_id, reward_level, model])
    else:
        _obtained_level_abilities.append(reward)


const _NAME_KEY: String = "name"
const _FIGHTS_KEY: String = "fights"
const _ABILITIES_KEY: String = "abilites"

func collect_save_data() -> Dictionary:
    return {
        _NAME_KEY: given_name,
        _FIGHTS_KEY: _fights,
        _ABILITIES_KEY: _obtained_level_abilities.map(func (ability: RobotAbility) -> String: return ability.full_id()),
    }

func load_from_save(data: Dictionary) -> void:
    given_name = "Sad roboto noname"
    if data.has(_NAME_KEY):
        if data[_NAME_KEY] is String:
            given_name = data[_NAME_KEY]
        else:
            push_warning("Save value %s on %s isn't a string in %s" % [data[_NAME_KEY], _NAME_KEY, data])
    else:
        push_warning("Save lacks name on %s for robot %s" % [_NAME_KEY, data])

    _fights = 0
    if data.has(_FIGHTS_KEY):
        if data[_FIGHTS_KEY] is int:
            _fights = data[_FIGHTS_KEY]
        else:
            push_warning("Save value %s on %s expected to be integer in %s" % [data[_FIGHTS_KEY], _FIGHTS_KEY, data])
    else:
        push_warning("Save lacks fights on %s for robot %s" % [_FIGHTS_KEY, data])

    _obtained_level_abilities.clear()
    if data.has(_ABILITIES_KEY):
        var arr: Variant = data[_ABILITIES_KEY]
        if arr is Array:
            var level: int = 1
            for ability_id: Variant in arr:
                if ability_id is String:
                    @warning_ignore_start("unsafe_call_argument")
                    var ability: RobotAbility = model.get_skill(ability_id, level)
                    @warning_ignore_restore("unsafe_call_argument")
                    if ability != null:
                        _obtained_level_abilities.append(ability)
                    else:
                        push_warning("%s is not a known level %s ability of %s" % [ability_id, level, model])
                else:
                    push_warning("%s is not a string value (expected on %s in %s)" % [ability_id, _ABILITIES_KEY, data])

                level += 1
        else:
            push_warning("Save doesn't have an array on %s in %s" % [_ABILITIES_KEY, data])
    else:
        push_warning("Save lacks abilities on %s for robot %s" % [_FIGHTS_KEY, data])
