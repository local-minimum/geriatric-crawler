extends Node3D
class_name GridNode

@export
var coordinates: Vector3i

func may_enter(_entity: GridEntity, _move_direction: CardinalDirections.CardinalDirection) -> bool:
    return true

func may_exit(_entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    if (move_direction == CardinalDirections.CardinalDirection.DOWN):
        return false
    return true

func neighbour(_direction: CardinalDirections.CardinalDirection) -> GridNode:
    return null
