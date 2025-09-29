extends MinimumDevCommand
class_name MinimumDevCommandCategory

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    console.set_context(command)
    return true
