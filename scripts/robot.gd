extends Node
class_name Robot

signal on_robot_death(robot: Robot)
signal on_robot_complete_fight(robot: Robot)
signal on_robot_loaded(robot: Robot)

@export
var _player: GridPlayer

@export
var model: RobotModel

@export
var given_name: String

var _obtained_cards: Array[BattleCardData]
var _obtained_upgrades: Array[RobotAbility]

var _fights: int
var _alive: bool = true

func _ready() -> void:
    _sync_player_transportation_mode()

    var battle_mode: BattleMode = BattleMode.instance
    var battle_player: BattlePlayer = battle_mode.battle_player if battle_mode != null else null
    if battle_player != null:
        battle_player.use_robot(self)

func is_alive() -> bool: return _alive

func obtained_upgrades() -> int: return _obtained_upgrades.size()

func available_upgrade_slots() -> int:
    var level: int = model.get_completed_level(_fights)
    if get_skill_level(RobotAbility.SKILL_UPGRADES) >= 4:
        return model.count_available_options(level, _obtained_upgrades)
    return level - obtained_upgrades()

func get_obtained_abilities(level: int) -> Array[RobotAbility]:
    return _obtained_upgrades.filter(func (ability: RobotAbility) -> bool: return model.find_skill_level(ability) == level)

func keys() -> KeyRing:
    return _player.key_ring

## Number of fights completed on the current level
func get_fights_done_on_current_level() -> int:
    return model.get_completed_steps_on_current_level(_fights)

## Number of fights completed on the level
func get_fights_done_on_level(level: int) -> int:
    return model.get_completed_steps_on_level(_fights, level)

## Number of fights needed to complete the level
func get_fights_required_to_level() -> int:
    return model.get_remaining_steps_on_current_level(_fights)

func fully_upgraded() -> bool:
    return model.get_level(_fights) == 5 && available_upgrade_slots() == 0

func must_upgrade() -> bool:
    return get_skill_level(RobotAbility.SKILL_UPGRADES) == 0 && model.get_remaining_steps_on_current_level(_fights) == 0

func get_active_abilities() -> Array[RobotAbility]:
    var abilites: Dictionary[String, RobotAbility] = {}
    for ability: RobotAbility in model.innate_abilities + _obtained_upgrades:
        if !abilites.has(ability.id):
            abilites[ability.id] = ability
            continue

        if ability.skill_level > abilites[ability.id].skill_level:
            abilites[ability.id] = ability

    return abilites.values()

func get_skill_level(skill: String) -> int:
    return ArrayUtils.maxi(
        get_active_abilities().filter(func (ability: RobotAbility) -> bool: return ability.id == skill),
        func (item: RobotAbility) -> int: return item.skill_level,
    )

func obtain_upgrade(reward_full_id: String) -> void:
    var reward: RobotAbility = model.find_skill(reward_full_id)
    if reward == null:
        push_error("Reward %s not present in model %s" % [reward_full_id, model])
    else:
        _obtained_upgrades.append(reward)


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
        _ABILITIES_KEY: _obtained_upgrades.map(func (ability: RobotAbility) -> String: return ability.full_id()),
        _OBTAINED_CARDS_KEY: _obtained_cards.map(func (card: BattleCardData) -> String: return card.id),
    }

func load_from_save(data: Dictionary) -> void:
    given_name = DictionaryUtils.safe_gets(data, _NAME_KEY, "Sad roboto noname")
    _fights = DictionaryUtils.safe_geti(data, _FIGHTS_KEY)
    _alive = DictionaryUtils.safe_getb(data, _ALIVE_KEY, true)

    _obtained_upgrades.clear()
    for ability_id: Variant in DictionaryUtils.safe_geta(data, _ABILITIES_KEY):
        if ability_id is String:
            @warning_ignore_start("unsafe_call_argument")
            var ability: RobotAbility = model.find_skill(ability_id)
            @warning_ignore_restore("unsafe_call_argument")
            if ability != null:
                _obtained_upgrades.append(ability)
            else:
                push_warning("%s is not a known ability of %s" % [ability_id, model])
        else:
            push_warning("%s is not a string value (expected on %s in %s)" % [ability_id, _ABILITIES_KEY, data])

    _obtained_cards.clear()

    for card_id: Variant in DictionaryUtils.safe_geta(data, _OBTAINED_CARDS_KEY):
        if card_id is String:
            @warning_ignore_start("unsafe_call_argument")
            var card: BattleCardData = BattleCardData.get_card_by_id(BattleCardData.CardCategory.Player, card_id)
            @warning_ignore_restore("unsafe_call_argument")
            if card == null:
                push_warning("%s couldn't be found among player cards" % card_id)
            else:
                _obtained_cards.append(card)
        else:
            push_warning("%s is not a string value (expected on %s in %s)" % [card_id, _OBTAINED_CARDS_KEY, data])

    _sync_player_transportation_mode()

    var battle_player: BattlePlayer = BattleMode.instance.battle_player if BattleMode.instance != null else null
    if battle_player != null:
        battle_player.use_robot(self)
    else:
        push_warning("Cannot configure battle robot for battle since there's none in scene")

    on_robot_loaded.emit(self)

func _sync_player_transportation_mode() -> void:
    if _player == null:
        return

    var climbing: int = get_skill_level(RobotAbility.SKILL_CLIMBING)
    match climbing:
        0:
            _player.transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
        1:
            # TODO: When we have stairs, allow on this level
            _player.transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
        2:
            _player.transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
        3:
            _player.transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            _player.transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)
        _:
            push_error("We don't know of the %s climbing skill level" % climbing)

func complete_fight() -> void:
    if _alive:
        var can_progress_without_upgrade: bool = get_skill_level(RobotAbility.SKILL_UPGRADES) >= 1
        var current_level: int = model.get_level(_fights)
        if current_level < 5:
            var required: int = model.get_level_required_steps(current_level)
            var done: int = model.get_completed_steps_on_level(_fights, current_level)
            if can_progress_without_upgrade || done < required:
                _fights += 1
        on_robot_complete_fight.emit(self)

func killed_in_fight() -> void:
    if _alive:
        _alive = false
        on_robot_death.emit(self)

func get_deck() -> Array[BattleCardData]:
    return model.starter_deck + _obtained_cards
