extends Node
class_name BroadcastReceiver
@export var receiver: Node

func configure(type: Broadcaster.BroadcasterType, message_id: String, messages: Array[String]) -> void:
    if receiver is Crusher:
        var crusher: Crusher = receiver
        crusher._managed_message_id = message_id
        match type:
            Broadcaster.BroadcasterType.PRESSURE_PLATE:
                if messages.size() == 2:
                    crusher._managed = true
                    crusher._managed_crush_message = messages[0]
                    crusher._managed_retract_message = messages[1]
                    print_debug("[Broadcast Receiver] Configured Crusher %s as managed to receive %s messages with id '%s'" % [
                        crusher.name,
                        Broadcaster.name(type),
                        message_id,
                    ])
            _:
                push_error("Receiver doesn't know how to configure %s for Crushers, ignoring message id '%s'" % [Broadcaster.name(type), message_id])

        return


    push_error("Receiver doesn't know how to configure %s for unhandled type on %s, ignoring message id '%s'" % [
        Broadcaster.name(type),
        receiver.name,
        message_id,
    ])
