extends Resource
class_name RobotProductionCost

@export var credits: int
@export_range(1, 10) var days: int = 1
@export var materials: Dictionary[String, float]
