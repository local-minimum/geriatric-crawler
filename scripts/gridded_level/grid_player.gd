extends GridEntity
class_name GridPlayer

func _input(event: InputEvent) -> void:
    if !event.is_echo():
        if event.is_action_pressed("crawl_forward"):
            if attempt_move(look_direction):
                print_debug("Forward")
        elif event.is_action_pressed("crawl_backward"):
            if attempt_move(CardinalDirections.invert(look_direction)):
                print_debug("Backward")
        elif event.is_action_pressed("crawl_strafe_left"):
            if attempt_move(CardinalDirections.yaw_ccw(look_direction, down)):
                print_debug("Strafe Left")
        elif event.is_action_pressed("crawl_strafe_right"):
            if attempt_move(CardinalDirections.yaw_cw(look_direction, down)):
                print_debug("Strafe Right")
