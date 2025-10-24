extends Node
class_name Insurer

static func calculate_insurance_cost(robot: RobotData) -> int:
    return ceili(robot.model.production.credits * 0.7) + 50
