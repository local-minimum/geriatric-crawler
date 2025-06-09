extends Panel
class_name  ExplorationUI

@export
var level: GridLevel


func _on_forward_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.FORWARD):
        print_debug("Refused Forward")

func _on_back_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.BACK):
        print_debug("Refused Back")

func _on_turn_left_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.TURN_COUNTER_CLOCKWISE):
        print_debug("Refused Turn Left")

func _on_turn_right_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.TURN_CLOCKWISE):
        print_debug("Refused Turn Right")

func _on_strafe_left_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.STRAFE_LEFT):
        print_debug("Refused Strafe Left")

func _on_strafe_right_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.STRAFE_RIGHT):
        print_debug("Refused Strafe Right")
