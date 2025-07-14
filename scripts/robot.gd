extends Node
class_name Robot

signal on_robot_death(robot: Robot)
signal on_robot_complete_fight(robot: Robot)

@export
var _player: GridPlayer

@export
var model: RobotModel

@export
var given_name: String

var _obtained_cards: Array[BattleCardData]
var _obtained_level_abilities: Array[RobotAbility]

var _fights: int
var _alive: bool = true

func _ready() -> void:
    _sync_player_transportation_mode()

func is_alive() -> bool: return _alive

func obtained_level() -> int: return _obtained_level_abilities.size()

func can_level_up() -> bool: return model.get_level(_fights) > obtained_level()

func get_skill_level(skill: String) -> int:
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
const _ALIVE_KEY: String = "alive"
const _OBTAINED_CARDS_KEY: String = "bonus-cards"

func collect_save_data() -> Dictionary:
    return {
        _NAME_KEY: given_name,
        _FIGHTS_KEY: _fights,
        _ALIVE_KEY: _alive,
        _ABILITIES_KEY: _obtained_level_abilities.map(func (ability: RobotAbility) -> String: return ability.full_id()),
        _OBTAINED_CARDS_KEY: _obtained_cards.map(func (card: BattleCardData) -> String: return card.id),
    }

func load_from_save(data: Dictionary) -> void:
    given_name = DictionaryUtils.safe_gets(data, _NAME_KEY, "Sad roboto noname")
    _fights = DictionaryUtils.safe_geti(data, _FIGHTS_KEY)
    _alive = DictionaryUtils.safe_getb(data, _ALIVE_KEY, true)

    _obtained_level_abilities.clear()
    var level: int = 1
    for ability_id: Variant in DictionaryUtils.safe_geta(data, _ABILITIES_KEY):
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

    _obtained_cards.clear()
    for card_id: Variant in DictionaryUtils.safe_geta(data, _OBTAINED_CARDS_KEY):
        if card_id is String:
            # TODO: Actually load card from resource
            pass
        else:
            push_warning("%s is not a string value (expected on %s in %s)" % [card_id, _OBTAINED_CARDS_KEY, data])

    _sync_player_transportation_mode()


func _sync_player_transportation_mode() -> void:
    if _player == null:
        return

    var climbing: int = get_skill_level(GridPlayer.CLIMBING_SKILL)
    match climbing:
        0:
            _player.transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
        1:
            _player.transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
        2:
            _player.transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)
        _:
            push_error("We don't know of the %s climbing skill level" % climbing)

func complete_fight() -> void:
    _fights += 1
    on_robot_complete_fight.emit(self)


func killed_in_fight() -> void:
    _alive = false
    on_robot_death.emit(self)

func get_deck() -> Array[BattleCardData]:
    return model.starter_deck + _obtained_cards
