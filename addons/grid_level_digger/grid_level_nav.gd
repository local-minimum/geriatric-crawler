@tool
extends Control
class_name GridLevelNav

signal on_update_nav(coordinates: Vector3i, look_direction: CardinalDirections.CardinalDirection)

@export
var panel: GridLevelDiggerPanel

func _enact_translation(movement: Movement.MovementType) -> void:
    if !Movement.is_translation(movement) || panel.level == null: return

    var direction: CardinalDirections.CardinalDirection = Movement.to_direction(
        movement,
        panel.look_direction,
        CardinalDirections.CardinalDirection.DOWN
    )

    var coordinates: Vector3i = CardinalDirections.translate(panel.coordinates, direction)

    on_update_nav.emit(coordinates, panel.look_direction)


func _on_down_pressed() -> void:
    _enact_translation(Movement.MovementType.ABS_DOWN)

func _on_strafe_right_pressed() -> void:
    _enact_translation(Movement.MovementType.STRAFE_RIGHT)

func _on_back_pressed() -> void:
    _enact_translation(Movement.MovementType.BACK)

func _on_strafe_left_pressed() -> void:
    _enact_translation(Movement.MovementType.STRAFE_LEFT)

func _on_up_pressed() -> void:
    _enact_translation(Movement.MovementType.ABS_UP)

func _on_forward_pressed() -> void:
    _enact_translation(Movement.MovementType.FORWARD)

func _on_turn_right_pressed() -> void:
    var look_direction: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(
        panel.look_direction,
        CardinalDirections.CardinalDirection.DOWN,
    )[0]

    on_update_nav.emit(panel.coordinates, look_direction)

func _on_turn_left_pressed() -> void:
    var look_direction: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(
        panel.look_direction,
        CardinalDirections.CardinalDirection.DOWN,
    )[0]
    on_update_nav.emit(panel.coordinates, look_direction)
