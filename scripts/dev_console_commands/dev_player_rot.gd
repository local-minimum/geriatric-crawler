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
    var parts: PackedStringArray = parameters.split(" ")
    if parts.size() < 2:
        return false

    var look: CardinalDirections.CardinalDirection = CardinalDirections.from_string(parts[0])
    var down: CardinalDirections.CardinalDirection = CardinalDirections.from_string(parts[1])

    if look == CardinalDirections.CardinalDirection.NONE || down == CardinalDirections.CardinalDirection.NONE:
        console.output_error("Directions cannot be NONE (look: '%s' -> %s; down '%s' -> %s" % [
            parts[0],
            CardinalDirections.name(look),
            parts[1],
            CardinalDirections.name(down)
        ])
        return false

    if _level == null || _level.player == null:
        console.output_error("There's no level loaded with a player character")
        return true

    var player: GridPlayerCore = _level.player

    var duration: float = max(0.0, 0.5 if parts.size() < 3 else parts[2].to_float())

    player.look_direction = look
    player.down = down

    if duration == 0.0:
        player.orient()
        console.output_info("Player now looking %s with %s down" % [CardinalDirections.name(look), CardinalDirections.name(down)])
        return true

    var look_target: Quaternion = CardinalDirections.direction_to_rotation(CardinalDirections.invert(player.down), player.look_direction)
    var tween: Tween = create_tween()
    var update_rotation: Callable = QuaternionUtils.create_tween_rotation_method(player)

    @warning_ignore_start("return_value_discarded")
    tween.tween_method(
        update_rotation,
        player.global_transform.basis.get_rotation_quaternion(),
        look_target,
        duration
    )
    @warning_ignore_restore("return_value_discarded")

    if tween.finished.connect(
        func () -> void:
            player.orient()
    ) != OK:
        push_error("Failed to connect rotation done")
        player.orient()

    console.output_info("Player rotates towards looking %s with %s down" % [CardinalDirections.name(look), CardinalDirections.name(down)])
    return true
