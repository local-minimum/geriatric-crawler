extends Node
class_name RobotExplorationMapper

static var active_mapper: RobotExplorationMapper

@export_range(5, 200) var _memory_size: int = 100

@export var _2d_map_ui: SimpleMapUI

@export var _3d_map_ui: IsometricMapUI

@export var map_controls: MapControlsUI

@export var _mapping_area: Control

@export var _detect_area: bool = true

var prefer_2d: bool:
    set(value):
        prefer_2d = value
        _update_map()

var _level: GridLevel
var _player: GridPlayer

var _level_id: String
var _seen: Array[Vector3i]
var _last_seen_idx: int

func history() -> Array[Vector3i]:
    var hist: Array[Vector3i]
    var size: int = mini(_seen.size(), _memory_size)
    for hist_idx: int in range(size):
        hist.append(_seen[(_last_seen_idx + hist_idx) % size])
    return hist

func level_id() -> String: return _level.level_id if _level != null else GridLevel.UNKNOWN_LEVEL_ID

func load_history(history_level_id: String, new_history: Array[Vector3i]) -> void:
    _level_id = history_level_id
    _seen = new_history
    _last_seen_idx = new_history.size() - 1
    _after_load_history.call_deferred()

func _after_load_history() -> void:
    if _level_id != level_id():
        _level_id = level_id()
        _seen.clear()

    _handle_move_end(_player)

func _ready() -> void:
    _setup.call_deferred()

func _enter_tree() -> void:
    if active_mapper != null && active_mapper != self:
        active_mapper.queue_free()

    active_mapper = self

func _exit_tree() -> void:
    if active_mapper == self:
        active_mapper = null

func _setup() -> void:
    _level = GridLevel.active_level

    if _level.on_change_player.connect(_connect_new_player) != OK:
        push_error("Failed to connect new _player")

    if _level.on_level_loaded.connect(_level_loaded) != OK:
        push_error("Failed to connect level loaded")

    _connect_new_player()
    _handle_move_end(_player)

func _level_loaded() -> void:
    for door: GridDoor in _level.doors():
        if !door.on_door_state_chaged.is_connected(_update_map) && door.on_door_state_chaged.connect(_update_map) != OK:
            push_error("Failed to connect door state change")

    for teleporter: GridTeleporter in _level.teleporters():
        if !teleporter.on_arrive_entity.is_connected(_handle_teleport) && teleporter.on_arrive_entity.connect(_handle_teleport) != OK:
            push_error("Failed to connect teleporter")

func _handle_teleport(_teleporter: GridTeleporter, entity: GridEntity) -> void:
    if entity == _player:
        _handle_move_end(entity)

func _connect_new_player() -> void:
    _player = _level.player
    if !_player.on_move_end.is_connected(_handle_move_end):
        if _player.on_move_end.connect(_handle_move_end) != OK:
            push_error("Failed to connect on move end")

    print_debug("Connected %s to map" % _player)

func _handle_move_end(entity: GridEntity) -> void:
    if entity != _player || entity == null:
        return

    var coords: Vector3i = entity.coordinates()
    _enter_new_coordinates(coords)

    var level:GridLevel = _player.get_level()

    var left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(_player.look_direction, _player.down)[0]
    var right: CardinalDirections.CardinalDirection = CardinalDirections.invert(left)

    if _player.get_grid_node().may_exit(_player, _player.look_direction, true, true):
        coords = CardinalDirections.translate(coords, _player.look_direction)
        var node: GridNode = level.get_grid_node(coords)

        if node != null:
            _enter_new_coordinates(coords)

            if node.may_exit(_player, left, true, true):
                var next_coords: Vector3i = CardinalDirections.translate(coords, left)

                if level.has_grid_node(next_coords):
                    _enter_new_coordinates(next_coords)

            if node.may_exit(_player, right, true, true):
                var next_coords: Vector3i = CardinalDirections.translate(coords, right)

                if level.has_grid_node(next_coords):
                    _enter_new_coordinates(next_coords)


    if _detect_area:
        if _player.get_grid_node().may_exit(_player, left, true, true):
            coords = CardinalDirections.translate(_player.coordinates(), left)

            var node: GridNode = level.get_grid_node(coords)

            if node != null:
                _enter_new_coordinates(coords)

                if node.may_exit(_player, _player.look_direction, true, true):
                    coords = CardinalDirections.translate(coords, _player.look_direction)

                    if level.has_grid_node(coords):
                        _enter_new_coordinates(coords)


        if _player.get_grid_node().may_exit(_player, right, true, true):
            coords = CardinalDirections.translate(_player.coordinates(), right)
            var node: GridNode = level.get_grid_node(coords)

            if node != null:
                _enter_new_coordinates(coords)

                if node.may_exit(_player, _player.look_direction, true, true):
                    coords = CardinalDirections.translate(coords, _player.look_direction)

                    if level.has_grid_node(coords):
                        _enter_new_coordinates(coords)

    _update_map()

func _update_map() -> void:
    var skill_level: int = _player.robot.get_skill_level(RobotAbility.SKILL_MAPPING)

    map_controls.sync(self, skill_level, prefer_2d)

    if skill_level == 2 || skill_level > 2 && prefer_2d:
        _mapping_area.visible = true

        _3d_map_ui.visible = false

        _2d_map_ui.visible = true
        _2d_map_ui.trigger_redraw(_player, _seen, skill_level >= 4)
    elif skill_level > 2:
        _mapping_area.visible = true

        _2d_map_ui.visible = false

        _3d_map_ui.visible = true
        _3d_map_ui.trigger_redraw(_player, _seen, skill_level >= 4)
    else:
        _mapping_area.visible = false
        _2d_map_ui.visible = false
        _3d_map_ui.visible = false

func _enter_new_coordinates(coords: Vector3i) -> void:
    if !_seen.has(coords):
        if _seen.size() < _memory_size:
            _seen.append(coords)
            _last_seen_idx = _seen.size() - 1
        else:
            _last_seen_idx += 1
            _last_seen_idx %= mini(_memory_size, _seen.size())
            _seen[_last_seen_idx] = coords

func zoom_in() -> void:
    var only_2d: bool = _player.robot.get_skill_level(RobotAbility.SKILL_MAPPING) == 2
    if prefer_2d || only_2d:
        _2d_map_ui.zoom_in()
    else:
        _3d_map_ui.zoom_in()

func zoom_out() -> void:
    var only_2d: bool = _player.robot.get_skill_level(RobotAbility.SKILL_MAPPING) == 2
    if prefer_2d || only_2d:
        _2d_map_ui.zoom_out()
    else:
        _3d_map_ui.zoom_out()
