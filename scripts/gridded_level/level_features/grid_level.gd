extends Node3D
class_name GridLevel

const LEVEL_GROUP: String = "grid-level"

@export
var node_size: Vector3 = Vector3(3, 3, 3)

@export
var node_spacing: Vector3 = Vector3.ZERO

@export
var player: GridPlayer

var _nodes: Dictionary[Vector3i, GridNode] = {}

func _init() -> void:
    add_to_group(LEVEL_GROUP)

func _ready() -> void:
    _sync_nodes()

    if _nodes.size() == 0:
        push_warning("Level %s is empty" % name)
    else:
        print_debug("Level %s has %s nodes" % [name, _nodes.size()])

func get_grid_node(coordinates: Vector3i) -> GridNode:
    if _nodes.has(coordinates):
        return _nodes[coordinates]

    push_warning("No node at %s" % coordinates)
    print_stack()

    return null

func has_grid_node(coordinates: Vector3i) -> bool:
    return _nodes.has(coordinates)

func _sync_nodes() -> void:
    _nodes.clear()

    for node: Node in find_children("*", "GridNode"):
        if node is GridNode:
            sync_node(node as GridNode)

func remove_node(node: GridNode) -> bool:
    if _nodes.has(node.coordinates):
        if _nodes[node.coordinates] == node:
            return _nodes.erase(node.coordinates)
        return false
    return false

func sync_node(node: GridNode) -> void:
    _nodes[node.coordinates] = node

    node.position = node_position_from_coordinates(self, node.coordinates)

static func find_level_parent(current: Node, inclusive: bool = true) ->  GridLevel:
    if inclusive && current is GridLevel:
        return current as GridLevel

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridLevel:
        return parent as GridLevel

    return find_level_parent(parent, false)

static func node_coordinates_from_position(level: GridLevel, grid_node: GridNode) -> Vector3i:
    var relative_pos: Vector3 = grid_node.global_position - level.global_position
    var size: Vector3 = level.node_size + level.node_spacing
    var raw_coords: Vector3 = relative_pos / size
    return Vector3i(roundi(raw_coords.x), roundi(raw_coords.y), roundi(raw_coords.z))

static func node_position_from_coordinates(level: GridLevel, coordinates: Vector3i) -> Vector3:
    var pos: Vector3 = Vector3(coordinates)
    return level.global_position + (level.node_size + level.node_spacing) * pos

static func node_center(level: GridLevel, coordintes: Vector3i) -> Vector3:
    return node_position_from_coordinates(level, coordintes) + Vector3.UP * level.node_size * 0.5
