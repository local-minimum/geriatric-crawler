extends Node3D
class_name GridAnchor

@export var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export var required_transportation_mode: TransportationMode

## If an entity cannot anchor, does it mean it should pass through the anchor.
## Example if the anchor is the down (or up) direction and is a water surface
## and the entity cannot swim, it should sink through the anchor.
@export var pass_through_on_refuse: bool

## If it is possible to pass through the anchor into the node
@export var pass_through_reverse: bool

var _node_side: GridNodeSide

func get_node_side() -> GridNodeSide:
    if _node_side == null:
        _node_side = GridNodeSide.find_node_side_parent(self)
    return _node_side

func get_grid_node() -> GridNode:
    var side: GridNodeSide = get_node_side()
    if side == null:
        return null
    return side.get_grid_node(self)


func _ready() -> void:
    var node_side: GridNodeSide = get_node_side()
    if node_side == null:
        push_error("%s doesn't have a GridNodeSide parent" % name)
    elif !CardinalDirections.is_parallell(direction, node_side.direction):
        # TODO: Something is fishy here
        GridNodeSide.set_direction_from_rotation(node_side)
        # push_error("%s's direction %s isn't parallell to the GridNodeSide direction %s" % [name, direction, node_side.direction])

    # _draw_debug_edges()

func _draw_debug_edges() -> void:
    for edge: CardinalDirections.CardinalDirection in CardinalDirections.orthogonals(direction):
        _draw_debug_sphere(get_edge_position(edge, false), 0.1)

func can_anchor(entity: GridEntity) -> bool:
    return (
        entity.transportation_abilities.has_all(required_transportation_mode.get_flags()) &&
        !get_grid_node().any_event_blocks_anchorage(entity, direction)
    )

func get_edge_position(edge_direction: CardinalDirections.CardinalDirection, local: bool = false) -> Vector3:
    var node: GridNode = get_grid_node()
    if node == null:
        return global_position

    if direction == edge_direction || CardinalDirections.invert(direction) == edge_direction:
        push_warning("%s is anchor %s, it doesn't have an edge %s, using it's center" % [
            name,
            CardinalDirections.name(direction),
            CardinalDirections.name(edge_direction)])
        return global_position

    var offset: Vector3 = node.get_level().node_size * 0.5 * Vector3(CardinalDirections.direction_to_vectori(edge_direction))

    if local:
        return offset

    return global_position + offset

func _draw_debug_sphere(location: Vector3, size: float) -> void:
    # Create sphere with low detail of size.
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radial_segments = 4
    sphere.rings = 4
    sphere.radius = size
    sphere.height = size * 2
    # Bright red material (unshaded).
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0, 0, 0.5)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sphere.surface_set_material(0, material)

    # Add to meshinstance in the right place.
    var node: MeshInstance3D = MeshInstance3D.new()
    add_child(node)
    node.mesh = sphere
    node.global_position = location

static func find_anchor_parent(current: Node, inclusive: bool = true) ->  GridAnchor:
    if inclusive && current is GridAnchor:
        return current as GridAnchor

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridAnchor:
        return parent as GridAnchor

    return find_anchor_parent(parent, false)
