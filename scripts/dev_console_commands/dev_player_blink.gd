extends MinimumDevCommand

func _ready() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Failed to connect level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Failed to connect level unloaded")

var _level: GridLevelCore

func _handle_level_loaded(level: GridLevelCore) -> void:
    _level = level

func _handle_level_unloaded(level: GridLevelCore) -> void:
    if _level == level:
        _level = null

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    if parameters.is_empty():
        if _move_step(1):
            console.output_info("Blinked forward one step")
            return true
        else:
            console.output_error("Could not blink forward")
            return true

    var steps: int = parameters.to_int()

    if steps <= 0:
        console.output_error("Steps must be a positve number")
        return false

    if _move_step(steps):
        console.output_info("Blinked %s step%s forward" % [steps, "" if steps == 1 else "s"])
    else:
        console.output_error("Failed to blink forward")
    return true


func _move_step(steps: int) -> bool:
    if _level == null || _level.player == null:
        return false

    var player: GridPlayerCore = _level.player

    var coords: Vector3i = CardinalDirections.translate(player.coordinates(), player.look_direction, steps)

    var node: GridNode = _level.get_grid_node(coords)
    if node == null:
        return false

    if node.may_enter(player, null, CardinalDirections.CardinalDirection.NONE, player.down):
        var anchor: GridAnchor = node.get_grid_anchor(player.down)
        if anchor != null:
            player.set_grid_anchor(anchor)
        else:
            player.set_grid_node(node)

        player.sync_position()

    return true
