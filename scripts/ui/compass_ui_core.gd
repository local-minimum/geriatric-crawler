extends Control
class_name CompassUICore

@export var cardinal_north: Control
@export var cardinal_south: Control
@export var cardinal_west: Control
@export var cardinal_east: Control
@export var cardinal_up: Control
@export var cardinal_down: Control

@export var _animation_duration: float = 0.3

@export var _vertical_label_offset: float = -14
@export var _horizontal_label_offset: float = -10

func _ready() -> void:
    if __SignalBus.on_load_complete.connect(_handle_loaded) != OK:
        push_error("Failed to connect load complete")

    if __SignalBus.on_update_orientation.connect(_handle_update_orientation) != OK:
        push_error("Failed to connect on move start")

func _handle_loaded() -> void:
    clear()

func clear() -> void:
    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        _get_cardinal(direction).global_position = _get_coordinates(CompassCardinalLabelPosition.UP)

var _orinentation_handled: bool

func _handle_update_orientation(
    _entity: GridEntity,
    old_down: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    # print_debug("[Compass] Player rotated %s and %s" % [CardinalDirections.name(down), CardinalDirections.name(forward)])
    visible = true
    _orinentation_handled = true

    if down == old_down || old_down == CardinalDirections.CardinalDirection.NONE:
        if old_forward != CardinalDirections.CardinalDirection.NONE:
            _animate_yaw_rotation(down, old_forward, forward)
    elif old_forward == forward:
        _animate_roll_rotation(old_down, old_forward, down, forward)
    elif forward == old_down || down == old_forward:
        _animate_pitch_rotation(old_down, old_forward, forward)
    else:
        _orinentation_handled = false

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
    var left_up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT_UP)
    var left_down_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT_DOWN)
    var right_up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT_UP)
    var right_down_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT_DOWN)

    @warning_ignore_start("return_value_discarded")
    if clockwise:
        tween.tween_property(_get_cardinal(old_left), "global_position", left_up_coords, _animation_duration)

        var left_label: Control = _get_cardinal(left)
        left_label.global_position = left_down_coords
        tween.parallel().tween_property(left_label, "global_position", left_coords, _animation_duration)

        tween.parallel().tween_property(_get_cardinal(old_right), "global_position", right_down_coords, _animation_duration)

        var right_label: Control = _get_cardinal(right)
        right_label.global_position = right_up_coords
        tween.parallel().tween_property(right_label, "global_position", right_coords, _animation_duration)
    else:
        tween.tween_property(_get_cardinal(old_right), "global_position", right_up_coords, _animation_duration)

        var right_label: Control = _get_cardinal(right)
        right_label.global_position = right_down_coords
        tween.parallel().tween_property(right_label, "global_position", right_coords, _animation_duration)

        tween.parallel().tween_property(_get_cardinal(old_left), "global_position", left_down_coords, _animation_duration)

        var left_label: Control = _get_cardinal(left)
        left_label.global_position = left_up_coords
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

    push_error("Direction %s not part of compass" % CardinalDirections.name(direction))
    return null

enum CompassCardinalLabelPosition {FAR_LEFT, LEFT, MID, RIGHT, FAR_RIGHT, UP, DOWN, RIGHT_UP, RIGHT_DOWN, LEFT_UP, LEFT_DOWN}

func _get_coordinates(label_position: CompassCardinalLabelPosition) -> Vector2:
    var rect: Rect2 = get_global_rect()
    var center: Vector2 = rect.get_center()
    # print_debug("[Compass] %s size" % rect.size)
    center.y += _vertical_label_offset
    center.x += _horizontal_label_offset
    # We need some space to edge
    var offset: float = rect.size.x * 0.4
    var far_offset: float = rect.size.x * 0.7

    match label_position:
        CompassCardinalLabelPosition.MID: return center
        CompassCardinalLabelPosition.LEFT: return center + Vector2.LEFT * offset
        CompassCardinalLabelPosition.LEFT_UP: return center + Vector2.LEFT * offset + Vector2.UP * offset
        CompassCardinalLabelPosition.LEFT_DOWN: return center + Vector2.LEFT * offset + Vector2.DOWN * offset
        CompassCardinalLabelPosition.RIGHT: return center + Vector2.RIGHT * offset
        CompassCardinalLabelPosition.RIGHT_UP: return center + Vector2.RIGHT * offset + Vector2.UP * offset
        CompassCardinalLabelPosition.RIGHT_DOWN: return center + Vector2.RIGHT * offset + Vector2.DOWN * offset
        CompassCardinalLabelPosition.FAR_LEFT: return center + Vector2.LEFT * far_offset
        CompassCardinalLabelPosition.FAR_RIGHT: return center + Vector2.RIGHT * far_offset
        CompassCardinalLabelPosition.UP: return center + Vector2.UP * offset
        CompassCardinalLabelPosition.DOWN: return center + Vector2.DOWN * offset
        _:
            push_error("Position %s not handled" % label_position)
            return center
