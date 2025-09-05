extends Node
class_name NavManager

@export var designed_destinations: Array[DestinationData]

func get_current_destination() -> DestinationData:
    return designed_destinations[0]
