extends Node3D
class_name GridLevel

static var active_level: GridLevel

const LEVEL_GROUP: String = "grid-level"
const UNKNOWN_LEVEL_ID: String = "--unknown--"

@export var level_id: String = UNKNOWN_LEVEL_ID

@export var node_size: Vector3 = Vector3(3, 3, 3)

@export var node_spacing: Vector3 = Vector3.ZERO

@export var player: GridPlayer:
    set(value):
        player = value
        __SignalBus.on_change_player.emit(self, value)

var grid_entities: Array[GridEntity]

@export var level_geometry: Node3D

@export var punishments: PunishmentDeck

@export var primary_entry_portal: LevelPortal
@export var level_portals: Array[LevelPortal]

@export var zones_parent: Node
@export var zones: Array[LevelZone]


var corpse: Corpse

var entry_portal: LevelPortal:
    get():
        if entry_portal == null:
            return primary_entry_portal
        return entry_portal

var activated_exit_portal: LevelPortal


var paused: bool:
    set(value):
        paused = value
        if value:
            player.disable_player()
        else:
            player.enable_player()

var _nodes: Dictionary[Vector3i, GridNode] = {}

func _init() -> void:
    add_to_group(LEVEL_GROUP)

var emit_loaded: bool = true

func _ready() -> void:
    entry_portal = primary_entry_portal
    emit_loaded = true

    _sync_nodes()

    if _nodes.size() == 0:
        push_warning("Level %s is empty" % name)
    else:
        print_debug("Level %s has %s nodes" % [name, _nodes.size()])

    var exploration: ExplorationScene = ExplorationScene.find_exploration_scene(self)
    if exploration != null:
        exploration.level = self

func _enter_tree() -> void:
    if active_level != null && active_level != self:
        active_level.queue_free()

    active_level = self

func _exit_tree() -> void:
    if active_level == self:
        active_level = null

func illusory_sides() -> Array[GridNodeSide]:
    if _nodes.is_empty():
        return []

    var illusions: Array[GridNodeSide] = []
    _nodes.values().reduce(
        func (_acc: Variant, node: GridNode) -> int:
            if node == null:
                return 0

            for side: GridNodeSide in node.illusory_sides():
                illusions.append(side)

            return 0,
        0,
    )

    return illusions

var _doors: Array[GridDoor] = []
func doors() -> Array[GridDoor]:
    if _doors.is_empty():
        for door: GridDoor in find_children("", "GridDoor"):
            _doors.append(door)
    return _doors

var _teleporters: Array[GridTeleporter] = []
func teleporters() -> Array[GridTeleporter]:
    if _teleporters.is_empty():
        for teleporter: GridTeleporter in find_children("", "GridTeleporter"):
            _teleporters.append(teleporter)
    return _teleporters

func alive_enemies() -> Array[BattleEnemy]:
    var enemies: Array[BattleEnemy]

    for entity: GridEntity in grid_entities:
        if entity is GridEncounter:
            var encounter: GridEncounter = entity
            if !encounter.can_trigger():
                continue

            if encounter.effect is BattleModeTrigger:
                var battle_trigger: BattleModeTrigger = encounter.effect

                for enemy: BattleEnemy in battle_trigger.enemies:
                    if enemy.is_alive_and_has_health():
                        enemies.append(enemy)

    return enemies

## Find the node which the position is inside if any.
func get_grid_node_by_position(pos: Vector3) -> GridNode:
    pos /= node_size
    pos += 0.5 * node_size * (
        CardinalDirections.direction_to_ortho_plane(CardinalDirections.CardinalDirection.UP) as Vector3
    )
    var coords: Vector3i = pos.floor() as Vector3i
    return get_grid_node(coords)

func get_grid_node(coordinates: Vector3i, warn_missing: bool = false) -> GridNode:
    if _nodes.has(coordinates):
        return _nodes[coordinates]

    if warn_missing:
        push_warning("No node at %s" % coordinates)
        print_stack()

    return null

func has_grid_node(coordinates: Vector3i) -> bool:
    return _nodes.has(coordinates)

func nodes() -> Array[GridNode]:
    return _nodes.values()

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

func get_closest_grid_node_side_by_position(pos: Vector3) -> CardinalDirections.CardinalDirection:
    pos -= (pos / node_size).floor() * node_size
    # TODO: Check why this is negative offsetting, but it seems to work this way!
    pos -= node_size.y * Vector3.UP * 0.5
    # print_debug("%s -> %s" % [pos, CardinalDirections.name(CardinalDirections.principal_direction(pos))])
    return CardinalDirections.principal_direction(pos)

func has_active_zone_for(coordintes: Vector3i, predicate: Callable) -> bool:
    return zones.any(
        func (zone: LevelZone) -> bool:
            return zone.visible && zone.covers(coordintes) && predicate.call(zone)
    )

func get_active_zones(coordinates: Vector3i) -> Array[LevelZone]:
    return zones.filter(
        func (zone: LevelZone) -> bool:
            return zone.covers(coordinates)
    )

func _process(_delta: float) -> void:
    if emit_loaded:
        emit_loaded = false
        print_debug("Level %s loaded" % level_id)
        __SignalBus.on_level_loaded.emit(self)

static func find_level_parent(current: Node, inclusive: bool = true) ->  GridLevel:
    if inclusive && current is GridLevel:
        return current as GridLevel

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridLevel:
        active_level = parent
        return parent as GridLevel

    return find_level_parent(parent, false)

static func node_coordinates_from_position(level: GridLevel, grid_node: GridNode) -> Vector3i:
    var relative_pos: Vector3 = grid_node.global_position - level.global_position
    var size: Vector3 = level.node_size + level.node_spacing
    var raw_coords: Vector3 = relative_pos / size
    return Vector3i(roundi(raw_coords.x), roundi(raw_coords.y), roundi(raw_coords.z))

static func node_position_from_coordinates(level: GridLevel, coordinates: Vector3i) -> Vector3:
    if level == null:
        push_error("Called without a level")
        print_stack()
        return Vector3.ZERO
    var pos: Vector3 = Vector3(coordinates)
    return level.global_position + (level.node_size + level.node_spacing) * pos

static func node_center(level: GridLevel, coordintes: Vector3i) -> Vector3:
    if level == null:
        push_error("Called without a level")
        print_stack()
        return Vector3.ZERO
    return node_position_from_coordinates(level, coordintes) + Vector3.UP * level.node_size * 0.5

static func get_level_geometry_root(level: GridLevel) -> Node3D:
    if level.level_geometry != null:
        return level.level_geometry
    return level
