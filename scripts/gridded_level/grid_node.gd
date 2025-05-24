extends Node3D
class_name GridNode

@export
var coordinates: Vector3i

var level: GridLevel

var _anchors: Dictionary[CardinalDirections.CardinalDirection, GridAnchor] = {}

func _ready() -> void:
    level = _find_level_parent(self)

func _find_level_parent(node: Node) -> GridLevel:
    var parent: Node = node.get_parent()

    if parent == null:
        push_warning("Node at %s not a child of a GridLevel" % coordinates)
        return null

    if parent is GridLevel:
        return parent as GridLevel

    return _find_level_parent(parent)

#
# Anchors
#

func _init_anchors() -> void:
    _anchors.clear()
    for anchor: GridAnchor in find_children("*", "GridAnchor"):
        if _anchors.has(anchor.direction):
            push_warning(
                "Node %s has duplicate anchors in the %s direction, skipping %s" % [name, anchor.direction, anchor],
            )
            continue

        _anchors[anchor.direction] = anchor

func remove_anchor(anchor: GridAnchor) -> bool:
    if !_anchors.has(anchor.direction):
        push_warning("Node %s has no anchor in the %s direction" % [name, anchor.direction])
        return false

    if _anchors[anchor.direction] == anchor:
        return _anchors.erase(anchor.direction)

    push_warning(
        "Node %s has another anchor %s in the %s direction" % [name, _anchors[anchor.direction], anchor.direction],
    )

    return false

func add_anchor(anchor: GridAnchor) -> bool:
    if _anchors.has(anchor.direction):
        push_warning(
            "Node %s already has an anchor %s in the %s direction - ignoring" % [name, _anchors[anchor.direction], anchor.direction],
        )

        return _anchors[anchor.direction] == anchor

    var success: bool = _anchors.set(anchor.direction, anchor)
    if (success):
        anchor.reparent(self, true)

    return success

func get_anchor(direction: CardinalDirections.CardinalDirection) -> GridAnchor:
    if _anchors.has(direction):
        return _anchors[direction]
    return null

#
# Navigation
#

func neighbour(direction: CardinalDirections.CardinalDirection) -> GridNode:
    if level == null:
        push_error("Node at %s not part of a level" % coordinates)
        return null

    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates, direction)

    if level.has_grid_node(neighbour_coords):
        return level.get_grid_node(neighbour_coords)

    return null

func may_enter(_entity: GridEntity, _move_direction: CardinalDirections.CardinalDirection) -> bool:
    return true

func may_exit(_entity: GridEntity, move_direction: CardinalDirections.CardinalDirection) -> bool:
    if (move_direction == CardinalDirections.CardinalDirection.DOWN):
        return false
    return true
