extends CanvasLayer
class_name RobotInspectionUI

@export
var _name_label: Label

@export
var _model_label: Label

@export
var _health_label: Label

@export
var _credits_label: Label

@export
var _tab_bar: TabBar

@export
var _tabs: Array[Control]

@export
var _active_skills_parent: Control

@export
var _robot_skill_tree: RobotSkillTreeUI

@export
var _exploration_inventory: ExplorationInventoryUI

func _ready() -> void:
    visible = false

func inspect(robot: Robot, battle_player: BattlePlayer, credits: int) -> void:
    _name_label.text = robot.given_name
    _model_label.text = "Model: %s" % robot.model.model_name

    if battle_player.is_alive():
        _health_label.text = "%s/%s HP" % [battle_player.get_health(), battle_player.max_health]
    else:
        _health_label.text = "DISEASED"

    _credits_label.text = "₳%s" % credits

    visible = true

    _sync_active_abilities(robot)

    _exploration_inventory.list_inventory()
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
                label.text = "%s: %s" % [ability.full_skill_name(), ability.description]

                continue

        if ability == null:
            continue

        label = Label.new()
        label.text = "%s: %s" % [ability.full_skill_name(), ability.description]

        _active_skills_parent.add_child(label)


func _on_tab_bar_tab_changed(tab:int) -> void:
    for idx: int in range(_tabs.size()):
        _tabs[idx].visible = tab == idx


func _on_close_button_pressed() -> void:
    visible = false
