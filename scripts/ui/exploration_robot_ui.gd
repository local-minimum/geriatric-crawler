extends Control
class_name ExplorationRobotUI

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
    if _exploration_ui.level.on_change_player.connect(_handle_new_player) != OK:
        push_error("Failed to connect on new player")

    _connect_player(_exploration_ui.level.player, _exploration_ui.battle.battle_player)

func _gui_input(event: InputEvent) -> void:
    if !_hovered || !event.is_pressed() || event.is_echo():
        return

    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            _click_robot()

    if event is InputEventScreenTouch:
        _click_robot()

func _click_robot() -> void:
    _exploration_ui.inspect_robot()

func _handle_new_player() -> void:
    var grid_player: GridPlayer = _exploration_ui.level.player
    if grid_player.robot.on_robot_complete_fight.connect(_handle_on_complete_fight) != OK:
        push_error("Failed to connect on robot complete fight")

    if grid_player.robot.on_robot_loaded.connect(_handle_on_robot_loaded) != OK:
        push_error("Failed to connect on robot loaded")

    _sync_robot(grid_player.robot, _exploration_ui.battle.battle_player)

func _connect_player(grid_player: GridPlayer, battle_player: BattlePlayer, omit_connecting_robot: bool = false) -> void:
    if battle_player.on_heal.connect(_handle_on_heal) != OK:
        push_error("Failed to connect on heal")
    if battle_player.on_hurt.connect(_handle_on_hurt) != OK:
        push_error("Failed to connect on hurt")
    if battle_player.on_death.connect(_handle_on_death) != OK:
        push_error("Failed to connect on death")

    if !omit_connecting_robot:
        # sync robot also called from new player
        _handle_new_player()
    else:
        _sync_robot(grid_player.robot, battle_player)

func _sync_robot(robot: Robot, battle_player: BattlePlayer) -> void:
    _name_label.text = robot.given_name
    _model_label.text = robot.model.model_name

    _sync_level(robot)

    if battle_player == null:
        push_warning("Assuming full health because battle player not set")
        _health_label.text = "%s/%s HP" % [robot.model.max_hp, robot.model.max_hp]
    else:
        _sync_health(battle_player)

func _sync_level(robot: Robot) -> void:
    if robot.must_upgrade():
        _level_label.text = "UPGRADE!"
        return

    if robot.fully_upgraded():
        _level_label.text = "MAXED OUT"
        return

    var slots: int = robot.available_upgrade_slots()
    if slots == 0:
        _level_label.text ="%s UNTIL SLOT" % robot.get_fights_required_to_level()
    else:
        _level_label.text ="%s SLOTS (%s UNTIL NEXT)" % [slots, robot.get_fights_required_to_level()]

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

func _handle_on_robot_loaded(_robot: Robot) -> void:
    print_debug("Handling robot loaded %s (%s, %s)" % [_robot.given_name, _exploration_ui.level.player, _exploration_ui.battle.battle_player])
    _connect_player(_exploration_ui.level.player, _exploration_ui.battle.battle_player, true)

var _hovered: bool = false

func _on_mouse_entered() -> void:
    _hovered = true

func _on_mouse_exited() -> void:
    _hovered = false
