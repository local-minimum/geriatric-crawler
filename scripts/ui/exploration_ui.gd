extends Panel
class_name  ExplorationUI

@export
var level: GridLevel

@export
var battle: BattleMode

@export
var inspect_robot_ui: RobotInspectionUI

func _on_turn_left_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.TURN_COUNTER_CLOCKWISE):
        print_debug("Refused Turn Left")

func _on_turn_right_pressed() -> void:
    if !level.player.attempt_movement(Movement.MovementType.TURN_CLOCKWISE):
        print_debug("Refused Turn Right")

func _on_forward_button_down() -> void:
    level.player.hold_movement(Movement.MovementType.FORWARD)

func _on_forward_button_up() -> void:
    level.player.clear_held_movement(Movement.MovementType.FORWARD)

func _on_strafe_left_button_down() -> void:
    level.player.hold_movement(Movement.MovementType.STRAFE_LEFT)

func _on_strafe_left_button_up() -> void:
    level.player.clear_held_movement(Movement.MovementType.STRAFE_LEFT)

func _on_strafe_right_button_down() -> void:
    level.player.hold_movement(Movement.MovementType.STRAFE_RIGHT)

func _on_strafe_right_button_up() -> void:
    level.player.clear_held_movement(Movement.MovementType.STRAFE_RIGHT)

func _on_back_button_down() -> void:
    level.player.hold_movement(Movement.MovementType.BACK)

func _on_back_button_up() -> void:
    level.player.clear_held_movement(Movement.MovementType.BACK)

func inspect_robot() -> void:
    inspect_robot_ui.inspect(level.player.robot, battle.battle_player)
