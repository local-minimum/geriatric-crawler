extends Node
class_name GiegerCounterUI

@export var _update_interval_msec: int = 200
@export var _gauge: LinearGaugeUI

var _here_ranges: Array[Array]
var _forwards_ranges: Array[Array]
var _min_value: float = -1
var _max_value: float = -1
var _next_update: int
var _prev_range_min: float
var _prev_range_max: float

func _enter_tree() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect move end")

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() > _next_update:
        _calculate_values()

func _calculate_values() -> void:
    _next_update = Time.get_ticks_msec() + _update_interval_msec
    var here_value: float = _roll_value(_here_ranges)
    var forwards_value: float = _roll_value(_forwards_ranges)
    var value: float = _mix_values(here_value, forwards_value)

    if _min_value < 0 || value < _min_value:
        _min_value = value
    if value > _max_value:
        _max_value = value

    _gauge.current_value = value
    _gauge.min_value = _min_value
    _gauge.max_value = _max_value

func _mix_values(here_value: float, forwards_value: float) -> float:
    if here_value == 0:
        return forwards_value
    elif forwards_value == 0:
        return here_value
    else:
        return (here_value + forwards_value) * 0.5

func _roll_value(ranges: Array[Array]) -> float:
    var sum: float = 0

    for r: Array[int] in ranges:
        sum += randf_range(r[0], r[1])

    return sum

func _complete_move_end() -> void:
    var range_min_here: float = _here_ranges.reduce(func (acc: int, dmg_range: Array[int]) -> int: return acc + dmg_range[0], 0)
    var range_max_here: float = _here_ranges.reduce(func (acc: int, dmg_range: Array[int]) -> int: return acc + dmg_range[1], 0)
    var range_min_forward: float = _forwards_ranges.reduce(func (acc: int, dmg_range: Array[int]) -> int: return acc + dmg_range[0], 0)
    var range_max_forward: float = _forwards_ranges.reduce(func (acc: int, dmg_range: Array[int]) -> int: return acc + dmg_range[1], 0)

    var range_min: float = _mix_values(range_min_here, range_min_forward)
    var range_max: float = _mix_values(range_max_here, range_max_forward)

    if range_min != _prev_range_min:
        _min_value = -1
        _prev_range_min = range_min

    if range_max != _prev_range_max:
        _max_value = -1
        _prev_range_max = range_max

    _calculate_values()

func _handle_move_end(entity: GridEntity) -> void:
    if entity is not GridPlayer:
        return

    _here_ranges = _get_potential_damages_at(entity.get_level(), entity.coordinates())

    var node: GridNode = entity.get_grid_node()
    if node == null:
        push_warning("Player outside level, this doesn't make sense")
        _forwards_ranges.clear()
        _complete_move_end()
        return

    if !node.may_exit(entity, entity.look_direction, true):
        _forwards_ranges.clear()
        _complete_move_end()
        return

    var neighbour: GridNode = node.neighbour(entity.look_direction)
    if neighbour == null:
        _forwards_ranges.clear()
        _complete_move_end()
        return

    _forwards_ranges = _get_potential_damages_at(entity.get_level(), neighbour.coordinates)
    _complete_move_end()

func _get_potential_damages_at(level: GridLevel, coordinates: Vector3i) -> Array[Array]:
    var ranges: Array[Array]
    for zone: LevelZone in level.get_active_zones(coordinates):
        for dmg: ZoneDamage in zone.find_children("", "ZoneDamage"):
            if dmg.can_damage:
                ranges.append(dmg.damage_range)

    return ranges
