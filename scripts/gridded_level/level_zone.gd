extends Node
class_name LevelZone

@export var nodes: Array[GridNode]

func get_level() -> GridLevel:
    if nodes.is_empty():
        return GridLevel.find_level_parent(self, false)
    return nodes[0].get_level()
