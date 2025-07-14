extends Node

@export
var _exploration_ui: ExplorationUI

@export
var _name_label: Label

@export
var _model_label: Label

@export
var _health_label: Label

@export
var _level_label: Label

func _ready() -> void:
    _connect_player(_exploration_ui.level.player, _exploration_ui.battle.battle_player)

func _connect_player(grid_player: GridPlayer, battle_player: BattlePlayer) -> void:
    if battle_player.on_heal.connect(_handle_on_heal) != OK:
        push_error("Failed to connect on heal")
    if battle_player.on_hurt.connect(_handle_on_hurt) != OK:
        push_error("Failed to connect on hurt")
    if battle_player.on_death.connect(_handle_on_death) != OK:
        push_error("Failed to connect on death")

    if grid_player.robot.on_robot_complete_fight.connect(_handle_on_complete_fight) != OK:
        push_error("Failed to connect on robot complete fight")

    _sync_robot(grid_player.robot, battle_player)

func _sync_robot(robot: Robot, battle_player: BattlePlayer) -> void:
    _name_label.text = robot.given_name
    _model_label.text = robot.model.model_name

    _sync_level(robot)

    if battle_player == null || !_exploration_ui.battle.get_battling():
        _health_label.text = "%s/%s HP" % [robot.model.max_hp, robot.model.max_hp]
    else:
        _sync_health(battle_player)

func _sync_level(robot: Robot) -> void:
    var lvl: int = robot.obtained_level()

    if lvl == 4:
        _level_label.text = "LVL %s (MAX)" % lvl
    else:
        var required: int = robot.get_fights_required_to_level()
        var done: int = robot.get_fights_to_next_level()

        if done >= required:
            _level_label.text = "LVL %s (LVL UP!)" % [lvl]
        else:
            _level_label.text = "LVL %s (%s/%s)" % [lvl, done, required]

func _sync_health(battle_player: BattleEntity) -> void:
    if battle_player == null:
        return

    if battle_player.is_alive():
        _health_label.text = "%s/%s HP" % [battle_player.get_health(), battle_player.max_health]
    else:
        _health_label.text = "DISEASED"

func _handle_on_heal(entity: BattleEntity, _amount: int, _new_health: int, _overheal: bool) -> void:
    _sync_health(entity)

func _handle_on_hurt(entity: BattleEntity, _amount: int, _new_health: int) -> void:
    _sync_health(entity)

func _handle_on_death(entity: BattleEntity) -> void:
    _sync_health(entity)

func _handle_on_complete_fight(robot: Robot) -> void:
    _sync_level(robot)
