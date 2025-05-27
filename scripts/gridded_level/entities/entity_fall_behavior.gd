extends Node3D
class_name EntityFallBehavior

@export
var entity: GridEntity

@export
var delay_per_fall_move_msec: int = 20

var next_fall: int = 0

func _process(_delta: float) -> void:
    if entity.transportation_mode.mode != TransportationMode.NONE || entity.is_moving():
        next_fall = 0
        return

    var t: int = Time.get_ticks_msec()
    if t > next_fall:
        next_fall = t + delay_per_fall_move_msec
        if !entity.attempt_movement(Movement.MovementType.ABS_DOWN, false, true):
            push_warning("%s is falling, but cannot fall down" % entity.name)
        else:
            print_debug("%s fell" % entity.name)
