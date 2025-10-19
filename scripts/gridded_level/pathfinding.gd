extends Node
class_name Pathfinding

var _flying_enemy: DungeonAStar


func _ready() -> void:
    _flying_enemy = DungeonAStar.new()
