extends Control
class_name CompassUI

@export
var exploration_ui: ExplorationUI

@export
var cardinal_north: Control

@export
var cardinal_south: Control

@export
var cardinal_west: Control

@export
var cardinal_east: Control

@export
var cardinal_up: Control

@export
var cardinal_down: Control

@export
var spacers_north_west: Array[Control]

@export
var spacers_north_east: Array[Control]

@export
var spacers_south_west: Array[Control]

@export
var spacers_south_east: Array[Control]

@export
var spacers_north_up: Array[Control]

@export
var spacers_south_up: Array[Control]

@export
var spacers_west_up: Array[Control]

@export
var spacers_east_up: Array[Control]

@export
var spacers_north_down: Array[Control]

@export
var spacers_south_down: Array[Control]

@export
var spacers_west_down: Array[Control]

@export
var spacers_east_down: Array[Control]

const _MAPPING_SKILL: String = "mapping"

func _ready() -> void:
    if exploration_ui.level.on_change_player.connect(_handle_new_player) != OK:
        push_error("Failed to connect on change player")

    _handle_new_player()

func _handle_new_player() -> void:
    var player: GridPlayer = exploration_ui.level.player
    if player.on_update_orientation.connect(_handle_update_orientation) != OK:
        push_error("Failed to connect on move start")

    _sync_robot.call_deferred(player, player.robot)

func _handle_update_orientation(
    _entity: GridEntity,
    old_down: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    if _entity is GridPlayer:
        var player: GridPlayer = _entity
        if player.robot.get_skill_level(_MAPPING_SKILL) < 1:
            visible = false
            return
    else:
        return

    visible = true

    print_debug("Down %s -> %s, Look %s -> %s" % [
        CardinalDirections.name(old_down),
        CardinalDirections.name(down),
        CardinalDirections.name(old_forward),
        CardinalDirections.name(forward),
    ])
    if down == old_down || old_down == CardinalDirections.CardinalDirection.NONE:
        _animate_yaw_rotation(down, old_forward, forward)
    elif old_forward == forward:
        _animate_roll_rotation(old_down, old_forward, down, forward)
    else:
        _animate_pitch_rotation(old_down, old_forward, forward)

func _sync_robot(player: GridPlayer, robot: Robot) -> void:
    if robot == null || robot.get_skill_level(_MAPPING_SKILL) < 1:
        print_debug("%s doesn't have enough mapping skill %s" % [robot.given_name, robot.get_skill_level(_MAPPING_SKILL)])
        visible = false
        return

    visible = true

    var left_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT)
    var mid_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.MID)
    var right_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT)

    var mid: CardinalDirections.CardinalDirection = player.look_direction
    var left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(player.look_direction, player.down)[0]
    var right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(player.look_direction, player.down)[0]

    _get_cardinal(mid).global_position = mid_coords
    _get_cardinal(left).global_position = left_coords
    _get_cardinal(right).global_position = right_coords

    var up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.UP)
    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        if direction == mid || direction == left || direction == right:
            continue

        _get_cardinal(direction).global_position = up_coords

@export
var _animation_duration: float = 0.3

func _animate_roll_rotation(
    old_down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    var clockwise: bool = CardinalDirections.roll_cw(old_forward, old_down)[1] == down
    var old_left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(old_forward, old_down)[0]
    var old_right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(old_forward, old_down)[0]
    var left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(forward, down)[0]
    var right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(forward, down)[0]

    var tween: Tween = get_tree().create_tween()

    var left_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT)
    var right_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT)
    var up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.UP)
    var down_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.DOWN)

    @warning_ignore_start("return_value_discarded")
    if clockwise:
        tween.tween_property(_get_cardinal(old_left), "global_position", up_coords, _animation_duration)

        var left_label: Control = _get_cardinal(left)
        left_label.global_position = down_coords
        tween.parallel().tween_property(left_label, "global_position", left_coords, _animation_duration)

        tween.parallel().tween_property(_get_cardinal(old_right), "global_position", down_coords, _animation_duration)

        var right_label: Control = _get_cardinal(right)
        right_label.global_position = up_coords
        tween.parallel().tween_property(right_label, "global_position", right_coords, _animation_duration)
    else:
        tween.tween_property(_get_cardinal(old_right), "global_position", up_coords, _animation_duration)

        var right_label: Control = _get_cardinal(right)
        right_label.global_position = down_coords
        tween.parallel().tween_property(right_label, "global_position", right_coords, _animation_duration)

        tween.parallel().tween_property(_get_cardinal(old_left), "global_position", down_coords, _animation_duration)

        var left_label: Control = _get_cardinal(left)
        left_label.global_position = up_coords
        tween.parallel().tween_property(left_label, "global_position", left_coords, _animation_duration)
    @warning_ignore_restore("return_value_discarded")

func _animate_pitch_rotation(
    old_down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    var pitch_up: bool = CardinalDirections.pitch_up(old_forward, old_down)[0] == forward

    var tween: Tween = get_tree().create_tween()

    var up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.UP)
    var mid_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.MID)
    var down_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.DOWN)

    var forward_label: Control = _get_cardinal(forward)
    @warning_ignore_start("return_value_discarded")
    if pitch_up:
        tween.tween_property(_get_cardinal(old_forward), "global_position", down_coords, _animation_duration)
        forward_label.global_position = up_coords
    else:
        tween.tween_property(_get_cardinal(old_forward), "global_position", up_coords, _animation_duration)
        forward_label.global_position = down_coords

    tween.parallel().tween_property(forward_label, "global_position", mid_coords, _animation_duration)
    @warning_ignore_restore("return_value_discarded")

func _animate_yaw_rotation(
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    var old_left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(old_forward, down)[0]
    var left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(forward, down)[0]
    var old_right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(old_forward, down)[0]
    var right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(forward, down)[0]

    var tween: Tween = get_tree().create_tween()

    var left_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT)
    var mid_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.MID)
    var right_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT)

    @warning_ignore_start("return_value_discarded")
    if old_forward == left:
        var far_left_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.FAR_LEFT)
        tween.tween_property(_get_cardinal(old_forward), "global_position", left_coords, _animation_duration)
        tween.parallel().tween_property(_get_cardinal(old_left), "global_position", far_left_coords, _animation_duration)
        var right_label: Control = _get_cardinal(right)
        right_label.position = _get_coordinates(CompassCardinalLabelPosition.FAR_RIGHT)
        tween.parallel().tween_property(right_label, "global_position", right_coords, _animation_duration)
    else:
        var far_right_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.FAR_RIGHT)
        tween.tween_property(_get_cardinal(old_forward), "global_position", right_coords, _animation_duration)
        tween.parallel().tween_property(_get_cardinal(old_right), "global_position", far_right_coords, _animation_duration)
        var left_label: Control = _get_cardinal(left)
        left_label.position = _get_coordinates(CompassCardinalLabelPosition.FAR_LEFT)
        tween.parallel().tween_property(left_label, "global_position", left_coords, _animation_duration)

    tween.parallel().tween_property(_get_cardinal(forward), "global_position", mid_coords, _animation_duration)
    @warning_ignore_restore("return_value_discarded")


func _get_cardinal(direction: CardinalDirections.CardinalDirection) -> Control:
    match direction:
        CardinalDirections.CardinalDirection.NORTH: return cardinal_north
        CardinalDirections.CardinalDirection.SOUTH: return cardinal_south
        CardinalDirections.CardinalDirection.WEST: return cardinal_west
        CardinalDirections.CardinalDirection.EAST: return cardinal_east
        CardinalDirections.CardinalDirection.UP: return cardinal_up
        CardinalDirections.CardinalDirection.DOWN: return cardinal_down

    return null

func _get_spacers(from: CardinalDirections.CardinalDirection, to: CardinalDirections.CardinalDirection) -> Array[Control]:
    match from:
        CardinalDirections.CardinalDirection.NORTH:
            match to:
                CardinalDirections.CardinalDirection.WEST: return spacers_north_west
                CardinalDirections.CardinalDirection.EAST: return spacers_north_east
                CardinalDirections.CardinalDirection.UP: return spacers_north_up
                CardinalDirections.CardinalDirection.DOWN: return spacers_north_down
        CardinalDirections.CardinalDirection.SOUTH:
            match to:
                CardinalDirections.CardinalDirection.WEST: return spacers_south_west
                CardinalDirections.CardinalDirection.EAST: return spacers_south_east
                CardinalDirections.CardinalDirection.UP: return spacers_south_up
                CardinalDirections.CardinalDirection.DOWN: return spacers_south_down
        CardinalDirections.CardinalDirection.WEST:
            match to:
                CardinalDirections.CardinalDirection.NORTH: return [spacers_north_west[1], spacers_north_west[0]]
                CardinalDirections.CardinalDirection.SOUTH: return [spacers_south_west[1], spacers_south_west[0]]
                CardinalDirections.CardinalDirection.UP: return spacers_west_up
                CardinalDirections.CardinalDirection.DOWN: return spacers_west_down
        CardinalDirections.CardinalDirection.EAST:
            match to:
                CardinalDirections.CardinalDirection.NORTH: return [spacers_north_east[1], spacers_north_east[0]]
                CardinalDirections.CardinalDirection.SOUTH: return [spacers_south_east[1], spacers_south_east[0]]
                CardinalDirections.CardinalDirection.UP: return spacers_east_up
                CardinalDirections.CardinalDirection.DOWN: return spacers_east_down
        CardinalDirections.CardinalDirection.UP:
            match to:
                CardinalDirections.CardinalDirection.NORTH: return [spacers_north_up[1], spacers_north_up[0]]
                CardinalDirections.CardinalDirection.SOUTH: return [spacers_south_up[1], spacers_south_up[0]]
                CardinalDirections.CardinalDirection.WEST: return [spacers_west_up[1], spacers_west_up[0]]
                CardinalDirections.CardinalDirection.EAST: return [spacers_east_up[1], spacers_east_up[0]]
        CardinalDirections.CardinalDirection.DOWN:
            match to:
                CardinalDirections.CardinalDirection.NORTH: return [spacers_north_down[1], spacers_north_down[0]]
                CardinalDirections.CardinalDirection.SOUTH: return [spacers_south_down[1], spacers_south_down[0]]
                CardinalDirections.CardinalDirection.WEST: return [spacers_west_down[1], spacers_west_down[0]]
                CardinalDirections.CardinalDirection.EAST: return [spacers_east_down[1], spacers_east_down[0]]

    push_error("%s and %s are not next to each other" % [
        CardinalDirections.name(from),
        CardinalDirections.name(to),
    ])

    return []

enum CompassCardinalLabelPosition {FAR_LEFT, LEFT, MID, RIGHT, FAR_RIGHT, UP, DOWN}

@export
var _vertical_label_offset: float = -14
@export
var _horizontal_label_offset: float = -10

func _get_coordinates(label_position: CompassCardinalLabelPosition) -> Vector2:
    var rect: Rect2 = get_global_rect()
    var center: Vector2 = rect.get_center()
    center.y += _vertical_label_offset
    center.x += _horizontal_label_offset
    # We need some space to edge
    var offset: float = rect.size.x * 0.4
    var far_offset: float = rect.size.x * 0.7

    match label_position:
        CompassCardinalLabelPosition.MID: return center
        CompassCardinalLabelPosition.LEFT: return center + Vector2.LEFT * offset
        CompassCardinalLabelPosition.RIGHT: return center + Vector2.RIGHT * offset
        CompassCardinalLabelPosition.FAR_LEFT: return center + Vector2.LEFT * far_offset
        CompassCardinalLabelPosition.FAR_RIGHT: return center + Vector2.RIGHT * far_offset
        CompassCardinalLabelPosition.UP: return center + Vector2.UP * offset
        CompassCardinalLabelPosition.DOWN: return center + Vector2.DOWN * offset
        _:
            push_error("Position %s not handled" % label_position)
            return center
