extends CompassUICore
class_name CompassUI

@export var exploration_ui: ExplorationUI

var _inited: bool

func _ready() -> void:
    if __SignalBus.on_robot_gain_ability.connect(_handle_robot_gain_ability) != OK:
        push_error("Failed to connect robot gain ability")

func _handle_robot_gain_ability(robot: Robot, ability: RobotAbility) -> void:
    if ability.id == RobotAbility.SKILL_MAPPING:
        _sync_robot(exploration_ui.player, robot)

func _handle_loaded() -> void:
    super._handle_loaded()
    _sync_robot(exploration_ui.player, exploration_ui.robot)

func _handle_update_orientation(
    entity: GridEntity,
    old_down: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
) -> void:
    var player: GridPlayer = null
    if entity is GridPlayer:
        player = entity
        if player.robot.get_skill_level(RobotAbility.SKILL_MAPPING) < 1:
            visible = false
            return
    else:
        return

    # print_debug("[Compass] Player rotated %s and %s" % [CardinalDirections.name(down), CardinalDirections.name(forward)])
    visible = true

    if !_inited:
        _sync_robot(player, player.robot)
        return

    # After running this we know if orientation was handled or not
    super._handle_update_orientation(entity, old_down, down, old_forward, forward)

    if !_orinentation_handled:
        _sync_robot(player, player.robot)

func _sync_robot(player: GridPlayer, robot: Robot) -> void:
    if robot == null || robot.get_skill_level(RobotAbility.SKILL_MAPPING) < 1:
        print_debug("[Compass] %s doesn't have enough mapping skill %s" % [robot.given_name, robot.get_skill_level(RobotAbility.SKILL_MAPPING)])
        visible = false
        return

    var rect: Rect2 = get_global_rect()
    if rect.size.x == 0 || rect.size.y == 0:
        return

    visible = true

    # print_debug("[Compass] sync of %s look %s down %s (%s)" % [robot.given_name, CardinalDirections.name(player.look_direction), CardinalDirections.name(player.down), _inited])

    var left_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.LEFT)
    var mid_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.MID)
    var right_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.RIGHT)

    var mid: CardinalDirections.CardinalDirection = player.look_direction
    var left: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(player.look_direction, player.down)[0]
    var right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(player.look_direction, player.down)[0]

    # print_debug("[Compass] left %s = %s mid %s = %s right %s = %s" % [
    #    _get_cardinal(left), left_coords, _get_cardinal(mid), mid_coords, _get_cardinal(right), right_coords])

    if mid != CardinalDirections.CardinalDirection.NONE:
        _get_cardinal(mid).global_position = mid_coords
    if left != CardinalDirections.CardinalDirection.NONE:
        _get_cardinal(left).global_position = left_coords
    if right != CardinalDirections.CardinalDirection.NONE:
        _get_cardinal(right).global_position = right_coords

    var up_coords: Vector2 = _get_coordinates(CompassCardinalLabelPosition.UP)
    for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
        if direction == mid || direction == left || direction == right:
            continue

        _get_cardinal(direction).global_position = up_coords

        # print_debug("[Compass] %s = %s" % [_get_cardinal(direction), up_coords])

    _inited = true

func _process(_delta: float) -> void:
    if !_inited:
        _sync_robot.call_deferred(exploration_ui.player, exploration_ui.robot)
