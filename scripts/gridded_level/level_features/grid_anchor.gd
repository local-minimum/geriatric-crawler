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
    # print_debug("%s is anchor in direction %s" % [name, CardinalDirections.name(direction)])


func can_anchor(entity: GridEntity) -> bool:
    return entity.transportation_abilities.has_all(required_transportation_mode.get_flags())

func get_edge_position(edge_direction: CardinalDirections.CardinalDirection) -> Vector3:
    var node: GridNode = get_grid_node()
    if node == null:
        return global_position

    if direction == edge_direction || CardinalDirections.invert(direction) == edge_direction:
        push_error("%s is anchor %s, it doesn't have an edge %s" % [
            name,
            CardinalDirections.name(direction),
            CardinalDirections.name(edge_direction)])
        print_stack()
        return global_position

    var size: Vector3 = node.level.node_size * Vector3(CardinalDirections.direction_to_ortho_plane(direction))
    return global_position + size * 0.5 * Vector3(CardinalDirections.direction_to_vector(edge_direction))
