extends GridEntity
class_name GridPlayer

@export
var spawn_node: GridNode

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

func _input(event: InputEvent) -> void:
    if transportation_mode.mode == TransportationMode.NONE:
        return

    if !event.is_echo():
        if event.is_action_pressed("crawl_forward"):
            if !attempt_move(look_direction):
                print_debug("Refused Forward")
        elif event.is_action_pressed("crawl_backward"):
            if !attempt_move(CardinalDirections.invert(look_direction)):
                print_debug("Refused Backward")
        elif event.is_action_pressed("crawl_strafe_left"):
            if !attempt_move(CardinalDirections.yaw_ccw(look_direction, down)[0]):
                print_debug("Refused Strafe Left")
        elif event.is_action_pressed("crawl_strafe_right"):
            if !attempt_move(CardinalDirections.yaw_cw(look_direction, down)[0]):
                print_debug("Refused Strafe Right")
        elif event.is_action_pressed("crawl_turn_left"):
            if !attempt_rotate(false):
                print_debug("Refused Rotate Left")
        elif event.is_action_pressed("crawl_turn_right"):
            if !attempt_rotate(true):
                print_debug("Refused Rotate Right")
        else:
            return

        print_debug("%s looking %s with %s down and has %s transportation" % [
            name,
            CardinalDirections.name(look_direction),
            CardinalDirections.name(down),
            transportation_mode.humanize()])
