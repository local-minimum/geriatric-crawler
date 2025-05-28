extends GridEntity
class_name GridPlayer

@export
var camera: Camera3D

@export
var spawn_node: GridNode

@export
var allow_replays: bool = true

@export
var persist_repeat_moves: bool

func _ready() -> void:
    if spawn_node != null:
        var anchor: GridAnchor = spawn_node.get_anchor(down)
        update_entity_anchorage(spawn_node, anchor, true)
        print_debug("%s anchors to %s in node %s and mode %s" % [
            name,
            anchor,
            spawn_node,
            transportation_mode.humanize()
        ])

    # We do super afterwards to not get uneccesary warning about player not being
    # preset as a child of a node
    super()

var _repeat_movement: Array[Movement.MovementType] = []

func _input(event: InputEvent) -> void:
    if transportation_mode.mode == TransportationMode.NONE:
        return

    if !event.is_echo():
        if event.is_action_pressed("crawl_forward"):
            if !attempt_movement(Movement.MovementType.FORWARD):
                print_debug("Refused Forward")
            _held_movement(Movement.MovementType.FORWARD)
        elif event.is_action_released("crawl_forward"):
            _clear_held_movement(Movement.MovementType.FORWARD)

        elif event.is_action_pressed("crawl_backward"):
            if !attempt_movement(Movement.MovementType.BACK):
                print_debug("Refused Backward")
            _held_movement(Movement.MovementType.BACK)
        elif event.is_action_released("crawl_backward"):
            _clear_held_movement(Movement.MovementType.BACK)

        elif event.is_action_pressed("crawl_strafe_left"):
            if !attempt_movement(Movement.MovementType.STRAFE_LEFT):
                print_debug("Refused Strafe Left")
            _held_movement(Movement.MovementType.STRAFE_LEFT)
        elif event.is_action_released("crawl_strafe_left"):
            _clear_held_movement(Movement.MovementType.STRAFE_LEFT)

        elif event.is_action_pressed("crawl_strafe_right"):
            if !attempt_movement(Movement.MovementType.STRAFE_RIGHT):
                print_debug("Refused Strafe Right")
            _held_movement(Movement.MovementType.STRAFE_RIGHT)
        elif event.is_action_released("crawl_strafe_right"):
            _clear_held_movement(Movement.MovementType.STRAFE_RIGHT)

        elif event.is_action_pressed("crawl_turn_left"):
            if !attempt_movement(Movement.MovementType.TURN_COUNTER_CLOCKWISE):
                print_debug("Refused Rotate Left")

        elif event.is_action_pressed("crawl_turn_right"):
            if !attempt_movement(Movement.MovementType.TURN_CLOCKWISE):
                print_debug("Refused Rotate Right")
        else:
            return

        print_debug("%s looking %s with %s down and has %s transportation" % [
            name,
            CardinalDirections.name(look_direction),
            CardinalDirections.name(down),
            transportation_mode.humanize()])

func _held_movement(movement: Movement.MovementType) -> void:
    if !allow_replays:
        return

    if persist_repeat_moves:
        if !_repeat_movement.has(movement):
            _repeat_movement.append(movement)
    else:
        _repeat_movement[0] = movement

func _clear_held_movement(movement: Movement.MovementType) -> void:
    _repeat_movement.erase(movement)

func _process(_delta: float) -> void:
    if !allow_replays || is_moving():
        return

    var count: int = _repeat_movement.size()
    if count > 0:
        if !attempt_movement(_repeat_movement[count - 1], false):
            _clear_held_movement(_repeat_movement[count - 1])
