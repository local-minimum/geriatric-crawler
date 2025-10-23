extends GridRampCore
class_name GridRamp

@export var climbing_requirement: int = 0

func _can_climb(entity: GridEntity, silent: bool) -> bool:
    if entity is GridPlayer:
        var player: GridPlayer = entity
        if player.robot.get_skill_level(RobotAbility.SKILL_CLIMBING) < climbing_requirement:
            if !silent:
                NotificationsManager.warn(tr("NOTICE_INACCESSIBLE"), tr("INSUFFICIENT_LEVEL"))
                print_debug("Entry to ramp blocked by too low climbing-skill")
            return false
    return true
