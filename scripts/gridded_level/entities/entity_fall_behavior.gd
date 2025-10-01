extends Node3D
class_name EntityFallBehavior

@export var entity: GridEntity
@export var delay_per_fall_move_msec: int = 20
@export var _cat_fall: bool = true
@export var _cat_orient_duration: float = 0.2

var next_fall: int = 0

func _process(_delta: float) -> void:
    if entity.transportation_mode.mode != TransportationMode.NONE || entity.is_moving() || entity.cinematic:
        next_fall = 0
        return

    var t: int = Time.get_ticks_msec()
    if t > next_fall:
        if _cat_fall && entity.down != CardinalDirections.CardinalDirection.DOWN:
            _orient_entity()


        if !entity.force_movement(Movement.MovementType.ABS_DOWN):
            push_warning("[Falling] %s is falling, but cannot fall down" % entity.name)
        else:
            print_debug("[Falling] %s fell" % entity.name)

        next_fall = t + delay_per_fall_move_msec

func _orient_entity() -> void:
    if !CardinalDirections.is_planar_cardinal(entity.look_direction):
        if CardinalDirections.is_planar_cardinal(entity.down):
            entity.look_direction = entity.down
        else:
            entity.look_direction = CardinalDirections.ALL_PLANAR_DIRECTIONS.pick_random()

    entity.down = CardinalDirections.CardinalDirection.DOWN

    var look_target: Quaternion = CardinalDirections.direction_to_rotation(CardinalDirections.invert(entity.down), entity.look_direction)
    var tween: Tween = create_tween()
    var update_rotation: Callable = QuaternionUtils.create_tween_rotation_method(entity)

    @warning_ignore_start("return_value_discarded")
    tween.tween_method(
        update_rotation,
        entity.global_transform.basis.get_rotation_quaternion(),
        look_target,
        _cat_orient_duration
    )
    @warning_ignore_restore("return_value_discarded")

    if tween.finished.connect(
        func () -> void:
            entity.orient()
    ) != OK:
        push_error("Failed to connect rotation done")
        entity.orient()

    print_debug("[Falling] %s cat fall-resolved down as down and looking %s" % [entity.name, CardinalDirections.name(entity.look_direction)])
