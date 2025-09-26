extends Control
class_name GiegerCounterUI

@export var _min_color: Color
@export var _max_color: Color
@export var _last_value_color: Color
@export var _update_interval_msec: int = 200

var _here_ranges: Array[Array]
var _forwads_ranges: Array[Array]
var _min_value: int = -1
var _max_value: int = -1
var _next_draw: int

func _enter_tree() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() > _next_draw:
        _next_draw = Time.get_ticks_msec() + _update_interval_msec
        queue_redraw()

func _draw() -> void:
    var here_value: float = _roll_value(_here_ranges)
    var forwards_value: float = _roll_value(_forwads_ranges)
    var value: float = (here_value + forwards_value) * 0.5
    if _min_value < 0 || value < _min_value:
        _min_value = value
    if value > _max_value:
        _max_value = value


func _roll_value(ranges: Array[Array]) -> float:
    var sum: float = 0

    for r: Array[int] in ranges:
        sum += randf_range(r[0], r[1])

    return sum

func _handle_move_end(entity: GridEntity) -> void:
    if entity is not GridPlayer:
        return

    _min_value = -1
    _max_value = -1

    _here_ranges = _get_potential_damages_at(entity.get_level(), entity.coordinates())

    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_warning("Player outside level, this doesn't make sense")
        _forwads_ranges.clear()
        return

    if !node.may_exit(entity, entity.look_direction, true):
        _forwads_ranges.clear()
        return

    var neighbour: GridNode = node.neighbour(entity.look_direction)
    if neighbour == null:
        _forwads_ranges.clear()
        return

    _forwads_ranges = _get_potential_damages_at(entity.get_level(), neighbour.coordinates)


func _get_potential_damages_at(level: GridLevel, coordinates: Vector3i) -> Array[Array]:
    var ranges: Array[Array]
    for zone: LevelZone in level.get_active_zones(coordinates):
        for dmg: ZoneDamage in zone.find_children("", "ZoneDamage"):
            if dmg.can_damage:
                ranges.append_array(dmg.damage_range)

    return ranges
