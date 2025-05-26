extends GridNodeFeature
class_name GridAnchor

@export
var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export
var required_transportation_mode: TransportationMode

## If an entity cannot anchor, does it mean it should pass through the anchor.
## Example if the anchor is the down (or up) direction and is a water surface
## and the entity cannot swim, it should sink through the anchor.
@export
var pass_through_on_refuse: bool

## If it is possible to pass through the anchor into the node
@export
var pass_through_reverse: bool

@export
var set_rotation_from_parent: bool

func _ready() -> void:
    super()
    if set_rotation_from_parent:
        _set_rotation_from_parent()

func _set_rotation_from_parent() -> void:
    var parent: Node3D = get_parent()
    if parent == null:
        return

    direction = CardinalDirections.node_planar_rotation_to_direction(parent)
    print_debug("%s is anchor in direction %s" % [name, direction])


func can_anchor(entity: GridEntity) -> bool:
    return entity.transportation_abilities.has_all(required_transportation_mode.get_flags())
