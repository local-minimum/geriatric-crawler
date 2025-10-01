extends MinimumDevCommand

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
        console.output_info("Current game speed: %.2f" % Engine.time_scale)
        return true

    var speed: float = parameters.to_float()
    if speed < 0:
        console.output_error("Speed must be a positive number")
        return false

    Engine.time_scale = speed
    console.output_info("Setting game speed to: %.2f" % Engine.time_scale)
    return true
