extends Control
class_name RobotSelectOption

signal on_select_robot(robot: RobotData)
signal on_deselect_robot(robot: RobotData)

@export var given_name: Label
@export var model_name: Label
@export var button: Button

var _robot: RobotData
var _toggled: bool

var selected: bool:
    get(): return _toggled
    set(value):
        _toggled = value
        button.button_pressed = value

func sync(robot: RobotData) -> void:
    given_name.text = robot.given_name
    model_name.text = robot.model.model_name
    _robot = robot

func _on_select_button_toggled(toggled_on: bool) -> void:
    _toggled = toggled_on

    if toggled_on:
        on_select_robot.emit(_robot)
    else:
        on_deselect_robot.emit(_robot)

func sync_selection(selected_robot: RobotData) -> void:
    selected = _robot == selected_robot
