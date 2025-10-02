extends Node
class_name Broadcaster

enum BroadcasterType { NONE, PRESSURE_PLATE }

static func name(type: BroadcasterType) -> String:
    return BroadcasterType.find_key(type)

@export var sender: Node

func configure(message_id: String, messages: Array[String]) -> BroadcasterType:
    if sender is PressurePlate:
        var plate: PressurePlate = sender
        plate._broadcast_id = message_id
        if messages.size() >= 2:
            plate._broadcast_activate_message = messages[0]
            plate._broadcast_deactivate_message = messages[1]
            print_debug("[Broadcaster] Configured pressure plates %s to send messages with id '%s'" % [plate.name, message_id])
        else:
            push_warning("Cannot configure broadcasting of pressure plate %s, expected 2 messages, got: %s" % [sender.name, messages])

        return BroadcasterType.PRESSURE_PLATE

    return BroadcasterType.NONE
