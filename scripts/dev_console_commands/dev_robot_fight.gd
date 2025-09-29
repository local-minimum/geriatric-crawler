extends MinimumDevCommand

func _ready() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Failed to connect level loaded")
    if __SignalBus.on_robot_loaded.connect(_handle_robot_loaded) != OK:
        push_error("Failed to connect robot loaded")

var _robot: Robot

func _handle_robot_loaded(robot: Robot) -> void:
    _robot = robot

func _handle_level_loaded(level: GridLevel) -> void:
    if level.player != null:
        _robot = level.player.robot
    else:
        _robot = null

func execute(_parameters: String, console: MinimumDevConsole) -> bool:
    if _robot != null:
        _robot.complete_fight()
        console.output_info("Robot has now completed a fight")

    else:
        console.output_info("No robot is known")

    return true
