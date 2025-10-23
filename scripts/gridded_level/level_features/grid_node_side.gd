extends Node3D
class_name GridNodeSide

@export var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN
@export var infer_direction_from_rotation: bool = true
@export var anchor: GridAnchor
@export var negative_anchor: GridAnchor
@export var illusory: bool

func is_two_sided() -> bool:
    return negative_anchor != null

func _ready() -> void:
    set_direction_from_rotation(self)

var _parent_node: GridNode
var _inverse_parent_node: GridNode

func update_anchor(new_anchor: GridAnchor) -> bool:
    if new_anchor.direction == direction:
        anchor = new_anchor
    elif new_anchor.direction == CardinalDirections.invert(direction):
        negative_anchor = anchor
    else:
        push_error("%s cannot be set as an anchor of %s because it has direction %s which isn't parallell to %s" % [
            new_anchor,
            self,
            CardinalDirections.name(new_anchor.direction),
            CardinalDirections.name(direction),
        ])
        return false

    return true


func get_side_parent_grid_node() -> GridNode:
    if _parent_node == null:
        _parent_node = GridNode.find_node_parent(self, false)
    return _parent_node

func _get_inverse_parent_node() -> GridNode:
    var parent_node: GridNode = get_side_parent_grid_node()
    if parent_node == null:
        push_warning("%s doesn't have a node parent" % name)
        print_tree()
        return null

    _inverse_parent_node = parent_node.neighbour(direction)

    return _inverse_parent_node

func get_grid_node(value: GridAnchor) -> GridNode:
    if value == anchor:
        return get_side_parent_grid_node()
    elif value == negative_anchor && negative_anchor != null:
        return _get_inverse_parent_node()

    push_error("%s of %s is not an anchor of %s" % [value.name, value.get_parent().name, name])
    print_stack()
    return null

static func find_node_side_parent(current: Node, inclusive: bool = true) -> GridNodeSide:
    if inclusive && current is GridNodeSide:
        return current as GridNodeSide

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridNodeSide:
        return parent as GridNodeSide

    return find_node_side_parent(parent, false)

static func set_direction_from_rotation(node_side: GridNodeSide) -> void:
    if !node_side.infer_direction_from_rotation || !CardinalDirections.is_planar_cardinal(node_side.direction):
        return

    node_side.direction = CardinalDirections.node_planar_rotation_to_direction(node_side)

    if node_side.anchor != null:
        node_side.anchor.direction = node_side.direction

    if node_side.negative_anchor != null:
        node_side.negative_anchor.direction = CardinalDirections.invert(node_side.direction)

static func get_node_side(node: GridNode, side_direction: CardinalDirections.CardinalDirection, warn_missing: bool = true) -> GridNodeSide:
    if node == null:
        if warn_missing:
            push_warning("Calling to get a node side of null element")
            print_stack()
        return null

    for side: GridNodeSide in node.find_children("", "GridNodeSide"):
        if side.direction == side_direction:
            return side

    return null

static func get_used_materials(side: GridNodeSide) -> Dictionary[String, String]:
    var ret: Dictionary[String, String]
    var root_path: NodePath = side.get_path()
    for child: Node in side.find_children("", "MeshInstance3D", true, true):
        if child is MeshInstance3D:
            var m_instance: MeshInstance3D = child
            var base_path: String = m_instance.get_path().slice(root_path.get_name_count())
            for surface_idx: int in range(m_instance.mesh.get_surface_count()):
                var mat: Material = m_instance.mesh.surface_get_material(surface_idx)
                ret["%s|%s" % [base_path, surface_idx]] = mat.resource_path

    return ret

static func get_meshinstance_from_override_path(side: GridNodeSide, path: String) -> MeshInstance3D:
    var real_path: String = path.split("|")[0]
    var child: Node = side.get_node(real_path)
    if child is MeshInstance3D:
        return child
    return null

static func get_meshinstance_surface_index_from_override_path(side: GridNodeSide, path: String) -> int:
    if !path.contains("|"):
        push_warning("Side %s has invalid override path %s" % [side, path])
        return -1

    var surface: String = path.split("|")[1]
    if !surface.is_valid_int():
        push_warning("Side %s has invalid surface index %s, must be an int" % [side, surface])
        return -1

    var value: int = surface.to_int()
    if value < 0:
        push_warning("Side %s has invalid surface index %s, must be zero ro positive" % [side, surface])
        return -1

    return value


static func revert_material_overrride(side: GridNodeSide, key: String, default: Material) -> void:
    var m_instance: MeshInstance3D = get_meshinstance_from_override_path(side, key)
    if m_instance == null:
        push_warning("Side %s has override for '%s' but this is not a mesh instance 3d" % [side, key])
        return

    var surface_idx: int = get_meshinstance_surface_index_from_override_path(side, key)
    if surface_idx < 0:
        return

    m_instance.mesh.surface_set_material(surface_idx, default)
