extends ZoneDamageCore
class_name ZoneDamage

func _handle_player_damage(player: GridPlayerCore) -> void:
    if player is not GridPlayer:
        return

    var robot: Robot = (player as GridPlayer).robot
    var damage: int = max(0, randi_range(_min_damage, _max_damage) - robot.get_skill_level(RobotAbility.SKILL_HARDENED))
    if damage == 0:
        return

    robot.health -= damage
    __SignalBus.on_robot_exploration_damage.emit(robot, damage)

    if robot.health == 0:
        robot.kill()
