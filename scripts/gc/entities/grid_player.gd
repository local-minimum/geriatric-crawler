extends GridPlayerCore
class_name GridPlayer
@export var robot: Robot

var override_wall_walking: bool:
    set(value):
        override_wall_walking = value
        if value:
            transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
        else:
            var climbing: int = robot.get_skill_level(RobotAbility.SKILL_CLIMBING)
            if climbing == 0:
                transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)
            else:
                transportation_abilities.set_flag(TransportationMode.WALL_WALKING)

var override_ceiling_walking: bool:
    set(value):
        override_ceiling_walking = value
        if value:
            transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
            transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)
        else:
            var climbing: int = robot.get_skill_level(RobotAbility.SKILL_CLIMBING)
            if climbing < 2:
                if !override_wall_walking && climbing == 0:
                    transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
                transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)
            else:
                transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)

func _ready() -> void:
    if __SignalBus.on_robot_death.connect(_handle_robot_death) != OK:
        push_error("Failed to connect to robot death")

    super()

func is_alive() -> bool:
    return robot.is_alive()

func _handle_robot_death(dead_robot: Robot) -> void:
    if robot == dead_robot:
        print_debug("[Grid Player] We are dead")
        cinematic = true
