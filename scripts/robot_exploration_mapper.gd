extends Node
class_name RobotExplorationMapper

static var active_mapper: RobotExplorationMapper

@export_range(5, 200)
var _memory_size: int = 100

@export
var _simple_map_ui: SimpleMapUI

@export
var _mapping_area: Control

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
    active_mapper = self
    _setup.call_deferred()

func _setup() -> void:
    _level = GridLevel.active_level

    if _level.on_change_player.connect(_connect_new_player) != OK:
        push_error("Failed to connect new _player")

    _connect_new_player()
    _handle_move_end(_player)

func _connect_new_player() -> void:
    _player = _level.player
    if _player.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect on move end")

    print_debug("Connected %s to map" % _player)

func _handle_move_end(entity: GridEntity) -> void:
    if entity != _player || entity == null:
        return

    var coords: Vector3i = entity.coordinates()
    _enter_new_coordinates(coords)

    if _player.get_grid_node().may_exit(_player, _player.look_direction, true):
        coords = CardinalDirections.translate(coords, _player.look_direction)
        _enter_new_coordinates(coords)

    var skill_level: int = _player.robot.get_skill_level(RobotAbility.SKILL_MAPPING)
    _mapping_area.visible = skill_level > 1

    if skill_level == 2:
        _simple_map_ui.visible = true
        _simple_map_ui.trigger_redraw(_player, _seen)
    else:
        _simple_map_ui.visible = false

func _enter_new_coordinates(coords: Vector3i) -> void:
    if !_seen.has(coords):
        if _seen.size() < _memory_size:
            _seen.append(coords)
            _last_seen_idx = _seen.size() - 1
        else:
            _last_seen_idx += 1
            _last_seen_idx %= mini(_memory_size, _seen.size())
            _seen[_last_seen_idx] = coords
