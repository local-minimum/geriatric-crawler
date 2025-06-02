class_name Movement

enum MovementType {
    NONE,
    FORWARD,
    BACK,
    STRAFE_LEFT,
    STRAFE_RIGHT,
    TURN_CLOCKWISE,
    TURN_COUNTER_CLOCKWISE,
    ABS_DOWN,
    ABS_UP,
}

static func is_turn(movement: MovementType) -> bool:
    return movement == MovementType.TURN_CLOCKWISE || movement == MovementType.TURN_COUNTER_CLOCKWISE

static func is_translation(movement: MovementType) -> bool:
    return movement != MovementType.NONE && movement != MovementType.TURN_CLOCKWISE && movement != MovementType.TURN_COUNTER_CLOCKWISE

static func to_direction(
    movement: MovementType,
    look_direction: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
) -> CardinalDirections.CardinalDirection:
    if !is_translation(movement):
        push_error("%s is not a translation so it doesn't have a cardinal direction" % name(movement))
        print_stack()
        return CardinalDirections.CardinalDirection.NONE

    match movement:
        MovementType.FORWARD:
            return look_direction
        MovementType.BACK:
            return CardinalDirections.invert(look_direction)
        MovementType.STRAFE_LEFT:
            return CardinalDirections.yaw_ccw(look_direction, down)[0]
        MovementType.STRAFE_RIGHT:
            return CardinalDirections.yaw_cw(look_direction, down)[0]
        MovementType.ABS_DOWN:
            return CardinalDirections.CardinalDirection.DOWN
        MovementType.ABS_UP:
            return CardinalDirections.CardinalDirection.UP

    return CardinalDirections.CardinalDirection.NONE

static func name(movement: MovementType) -> String:
    match movement:
        MovementType.NONE: return "None"
        MovementType.FORWARD: return "Forward"
        MovementType.BACK: return "Back"
        MovementType.STRAFE_LEFT: return "Strafe left"
        MovementType.STRAFE_RIGHT: return "Strafe right"
        MovementType.TURN_CLOCKWISE: return "Turn right"
        MovementType.TURN_COUNTER_CLOCKWISE: return "Turn left"
        MovementType.ABS_DOWN: return "Absolute down"
        MovementType.ABS_UP: return "Absolute up"
        _:
            push_error("%s is not a movement" % movement)
            print_stack()
            return "Unknown"
