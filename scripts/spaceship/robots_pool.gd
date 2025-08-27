extends Node
class_name RobotsPool

@export var robots: Array[Robot]

func available_robots() -> Array[Robot]:
    return robots
