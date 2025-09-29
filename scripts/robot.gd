extends Node
class_name Robot

@export var _player: GridPlayer

var _has_data: bool

var _data: RobotData:
    get():
        if _data == null:
            _data = RobotData.new(_fallback_model, "Robbie", robot_id)
            _has_data = true
        return _data
    set(value):
        _has_data = value != null
        _data = value


@export var _fallback_model: RobotModel

var model: RobotModel:
    get(): return _data.model

var given_name: String:
    get(): return _data.given_name

## Unique identifier of this particular robot
@export var robot_id: String:
    get():
        if _has_data:
            return _data.id
        return robot_id
    set(value):
        if !_has_data:
            robot_id = value

var health: int:
    get(): return _data.health
    set(value):
        _data.health = clamp(value, 0, model.max_hp)

var alive: bool:
    get():
        return _data.alive
    set(value):
        if value:
            _data.alive = true
        else:
            _data.alive = false
            _data.health = 0

var accumulated_damage: int:
    get(): return _data.accumulated_damage
    set(value):
        _data.accumulated_damage = value

func _ready() -> void:
    _sync_player_transportation_mode()

    var battle_mode: BattleMode = BattleMode.instance
    var battle_player: BattlePlayer = battle_mode.battle_player if battle_mode != null else null
    if battle_player != null:
        battle_player.use_robot(self)

func is_alive() -> bool: return _data.alive && _data.health > 0

func obtained_upgrades() -> int: return _data.obtained_upgrades.size()

func available_upgrade_slots() -> int:
    if model == null:
        return 0

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
    return model.get_completed_steps_on_current_level(_data.fights) if model != null else 0

## Number of fights completed on the level
func get_fights_done_on_level(level: int) -> int:
    return model.get_completed_steps_on_level(_data.fights, level) if model != null else 0

## Number of fights needed to complete the level
func get_fights_required_to_level() -> int:
    return model.get_remaining_steps_on_current_level(_data.fights) if model != null else -1

func fully_upgraded() -> bool:
    return model != null && model.get_level(_data.fights) == 5 && available_upgrade_slots() == 0

func must_upgrade() -> bool:
    return model != null && get_skill_level(RobotAbility.SKILL_UPGRADES) == 0 && model.get_remaining_steps_on_current_level(_data.fights) == 0

func get_active_abilities() -> Array[RobotAbility]:
    if model == null:
        return []

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
    if model == null:
        push_error("Robot has no model")
        return

    var reward: RobotAbility = model.find_skill(reward_full_id)
    if reward == null:
        push_error("Reward %s not present in model %s" % [reward_full_id, model])
    else:
        _data.obtained_upgrades.append(reward)
        __SignalBus.on_robot_gain_ability.emit(self, reward)

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

func load_from_data(data: RobotData) -> void:
    _data = data

    _sync_player_transportation_mode()

    var battle_player: BattlePlayer = BattleMode.instance.battle_player if BattleMode.instance != null else null
    if battle_player != null:
        battle_player.use_robot(self)
    else:
        push_warning("Cannot configure battle robot for battle since there's none in scene")

    __SignalBus.on_robot_loaded.emit(self)

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
    if _data.alive && model != null:
        var can_progress_without_upgrade: bool = get_skill_level(RobotAbility.SKILL_UPGRADES) >= 1
        var current_level: int = model.get_level(_data.fights)
        if current_level < 5:
            var required: int = model.get_level_required_steps(current_level)
            var done: int = model.get_completed_steps_on_level(_data.fights, current_level)
            if can_progress_without_upgrade || done < required:
                _data.fights += 1
        __SignalBus.on_robot_complete_fight.emit(self)

func kill() -> void:
    if _data.alive:
        _data.health = 0
        _data.alive = false
        print_debug("[Robot] Robot is dead")
        __SignalBus.on_robot_death.emit(self)

func get_deck() -> Array[BattleCardData]:
    if model == null:
        return _data.obtained_cards

    return model.starter_deck + _data.obtained_cards
