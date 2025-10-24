extends ExplorationUICore
class_name  ExplorationUI


@export var battle: BattleMode

@export var inspect_robot_ui: RobotInspectionUI

var player: GridPlayer:
    get():
        if level.player is GridPlayer:
            return (level.player as GridPlayer)
        return null

var robot: Robot:
    get():
        if level.player is GridPlayer:
            return (level.player as GridPlayer).robot
        return null

func inspect_robot() -> void:
    if level.player is GridPlayer:
        inspect_robot_ui.inspect(
            level.player as GridPlayer,
            (level.player as GridPlayer).robot,
            battle.battle_player,
            __GlobalGameState.total_credits,
        )
