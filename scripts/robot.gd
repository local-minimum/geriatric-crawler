extends Node
class_name Robot

signal on_robot_death(robot: Robot)
signal on_robot_complete_fight(robot: Robot)
signal on_robot_loaded(robot: Robot)

@export var _player: GridPlayer

var _data: RobotData

@export var model: RobotModel:
    get(): return _data.model if _data != null else model

var given_name: String:
    get(): return _data.given_name if _data != null else "Robbie"

@export var robot_id: String:
    get():
        if _data != null:
            return _data.id
        return robot_id
    set(value):
        if _data == null:
            robot_id = value

func _ready() -> void:
    _sync_player_transportation_mode()

    var battle_mode: BattleMode = BattleMode.instance
    var battle_player: BattlePlayer = battle_mode.battle_player if battle_mode != null else null
    if battle_player != null:
        battle_player.use_robot(self)

func is_alive() -> bool: return _data.alive

func obtained_upgrades() -> int: return _data.obtained_upgrades.size()

func available_upgrade_slots() -> int:
    var level: int = model.get_completed_level(_data.fights)
    if get_skill_level(RobotAbility.SKILL_UPGRADES) >= 4:
        return model.count_available_options(level, _data.obtained_upgrades)
    return level - obtained_upgrades()

func get_obtained_abilities(level: int) -> Array[RobotAbility]:
    return _data.obtained_upgrades.filter(func (ability: RobotAbility) -> bool: return model.find_skill_level(ability) == level)

func keys() -> KeyRing:
    return _player.key_ring

## Number of fights completed on the current level
func get_fights_done_on_current_level() -> int:
    return model.get_completed_steps_on_current_level(_data.fights)

## Number of fights completed on the level
func get_fights_done_on_level(level: int) -> int:
    return model.get_completed_steps_on_level(_data.fights, level)

## Number of fights needed to complete the level
func get_fights_required_to_level() -> int:
    return model.get_remaining_steps_on_current_level(_data.fights)

func fully_upgraded() -> bool:
    return model.get_level(_data.fights) == 5 && available_upgrade_slots() == 0

func must_upgrade() -> bool:
    return get_skill_level(RobotAbility.SKILL_UPGRADES) == 0 && model.get_remaining_steps_on_current_level(_data.fights) == 0

func get_active_abilities() -> Array[RobotAbility]:
    var abilites: Dictionary[String, RobotAbility] = {}
    for ability: RobotAbility in model.innate_abilities + _data.obtained_upgrades:
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

func get_active_skill_level(skill: String) -> RobotAbility:
    var lvl: int = get_skill_level(skill)
    return ArrayUtils.first(
        get_active_abilities(),
        func (ability: RobotAbility) -> bool: return ability.id == skill && lvl == ability.skill_level,
    )

func obtain_upgrade(reward_full_id: String) -> void:
    var reward: RobotAbility = model.find_skill(reward_full_id)
    if reward == null:
        push_error("Reward %s not present in model %s" % [reward_full_id, model])
    else:
        _data.obtained_upgrades.append(reward)

func gain_card(card: BattleCardData) -> void:
    _data.obtained_cards.append(card)

func remove_one_punishment_card() -> BattleCardData:
    var idx: int = _data.obtained_cards.find_custom(func (card: BattleCardData) -> bool: return PunishmentDeck.instance.has(card))
    if idx >= 0:
        var card: BattleCardData = _data.obtained_cards[idx]
        _data.obtained_cards.erase(card)
        return card
    return null

func remove_all_punishment_cards() -> void:
    while remove_one_punishment_card() != null:
        pass

func collect_save_data() -> Dictionary:
    return _data.to_save()

func load_from_save(data: Dictionary) -> void:
    _data = RobotData.from_save(data)

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
    if _data.alive:
        var can_progress_without_upgrade: bool = get_skill_level(RobotAbility.SKILL_UPGRADES) >= 1
        var current_level: int = model.get_level(_data.fights)
        if current_level < 5:
            var required: int = model.get_level_required_steps(current_level)
            var done: int = model.get_completed_steps_on_level(_data.fights, current_level)
            if can_progress_without_upgrade || done < required:
                _data.fights += 1
        on_robot_complete_fight.emit(self)

func killed_in_fight() -> void:
    if _data.alive:
        _data.alive = false
        on_robot_death.emit(self)

func get_deck() -> Array[BattleCardData]:
    return model.starter_deck + _data.obtained_cards
