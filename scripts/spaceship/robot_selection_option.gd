extends Control
class_name RobotSelectOption

@export var given_name: Label
@export var model_name: Label

func sync(robot: RobotsPool.SpaceshipRobot) -> void:
    given_name.text = robot.given_name
    model_name.text = robot.model.model_name
