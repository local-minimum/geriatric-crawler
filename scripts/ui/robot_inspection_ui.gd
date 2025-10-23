extends CanvasLayer
class_name RobotInspectionUI

@export var _name_label: Label
@export var _model_label: Label
@export var _health_label: Label
@export var _credits_label: Label

@export var _tab_bar: TabBar

@export var _tabs: Array[Control]

@export var _active_skills_parent: Control

@export var _inspect_deck: InspectBattleDeckUI

@export var _robot_skill_tree: RobotSkillTreeUI

@export var _exploration_inventory: ExplorationInventoryUI
@export var _exploration_keys: ExplorationKeysUI

var _player: GridPlayer
var _toggled_cinematic: bool

func _ready() -> void:
    if __SignalBus.on_robot_gain_ability.connect(_handle_robot_gain_ability) != OK:
        push_error("Failed to connect robot gain ability")

    if __SignalBus.on_update_credits.connect(_handle_update_credits) != OK:
        push_error("Failed to connect update credits")

    if __SignalBus.on_robot_complete_fight.connect(_handle_robot_complete_fight) != OK:
        push_error("Failed to connect robot complete fight")

    visible = false

func _handle_robot_complete_fight(robot: Robot) -> void:
    if visible:
        _robot_skill_tree.sync(robot, __GlobalGameState.total_credits)

func _handle_update_credits(credits: int) -> void:
    if visible:
        _credits_label.text = GlobalGameState.credits_with_sign(credits)
        if _player != null:
            _robot_skill_tree.sync(_player.robot, credits)

func _handle_robot_gain_ability(robot: Robot, _ability: RobotAbility) -> void:
    _sync_active_abilities(robot)

func inspect(player: GridPlayer, robot: Robot, battle_player: BattlePlayer, credits: int) -> void:
    _player = player
    if player.cinematic:
        _toggled_cinematic = false
    else:
        _toggled_cinematic = true
        player.cinematic = true

    _name_label.text = robot.given_name
    _model_label.text = "%s: %s" % [tr("MODEL"), robot.model.model_name if robot.model.model_name else RobotModel.UNKNOWN_MODEL]

    if battle_player.is_alive_and_has_health():
        _health_label.text = "%s/%s %s" % [battle_player.get_health(), battle_player.get_max_health(), tr("HEALTH_POINTS")]
    else:
        _health_label.text = tr("DISEASED").to_upper()

    _credits_label.text = GlobalGameState.credits_with_sign(credits)

    visible = true

    _sync_active_abilities(robot)

    _inspect_deck.list_cards(robot.get_deck())

    _exploration_inventory.list_inventory()
    _exploration_keys.list_keys(robot.keys())

    _robot_skill_tree.sync(robot, credits)
    _on_tab_bar_tab_changed(_tab_bar.current_tab)

func _sync_active_abilities(robot: Robot) -> void:
    var abilites: Array[RobotAbility] = robot.get_active_abilities()
    var n_children: int = _active_skills_parent.get_child_count()
    for idx: int in range(maxi(n_children, abilites.size())):
        var ability: RobotAbility = null
        var label: Label = null

        if idx < abilites.size():
            ability = abilites[idx]

        if idx < n_children:
            var child: Node = _active_skills_parent.get_child(idx)
            if ability == null:
                if child is Control:
                    var control: Control = child
                    control.visible = false

                continue

            if child is Label:
                label = child
                label.text = "%s: %s" % [ability.full_skill_name(), tr(ability.description)]

                continue

        if ability == null:
            continue

        label = Label.new()
        label.text = "%s: %s" % [ability.full_skill_name(), tr(ability.description)]
        label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED

        _active_skills_parent.add_child(label)


func _on_tab_bar_tab_changed(tab:int) -> void:
    for idx: int in range(_tabs.size()):
        _tabs[idx].visible = tab == idx


func _on_close_button_pressed() -> void:
    visible = false

    if _player != null && _toggled_cinematic:
        _player.cinematic = false
