extends Control
class_name RobotSelectOption

signal on_select_robot(robot: RobotsPool.SpaceshipRobot)
signal on_deselect_robot(robot: RobotsPool.SpaceshipRobot)

@export var given_name: Label
@export var model_name: Label
@export var button: Button

var _robot: RobotsPool.SpaceshipRobot
var _toggled: bool

var selected: bool:
    get(): return _toggled
    set(value):
        _toggled = value
        button.button_pressed = value

func sync(robot: RobotsPool.SpaceshipRobot) -> void:
    given_name.text = robot.given_name
    model_name.text = robot.model.model_name
    _robot = robot

func _on_select_button_toggled(toggled_on: bool) -> void:
    _toggled = toggled_on

    if toggled_on:
        on_select_robot.emit(_robot)
    else:
        on_deselect_robot.emit(_robot)

func sync_selection(selected_robot: RobotsPool.SpaceshipRobot) -> void:
    selected = _robot == selected_robot
