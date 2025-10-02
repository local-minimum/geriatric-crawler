extends Node
class_name BroadcastContract

@export var _broadcaster: Node
@export var _receivers: Array[Node]
@export var _message_id: String
@export var _messages: Array[String]

func _ready() -> void:
    var type: Broadcaster.BroadcasterType = Broadcaster.BroadcasterType.NONE

    if _broadcaster is Broadcaster:
        var caster: Broadcaster = _broadcaster
        type = caster.configure(_message_id, _messages)
    else:
        for node: Node in _broadcaster.find_children("", "Broadcaster"):
            if node is Broadcaster:
                var caster: Broadcaster = node
                type = caster.configure(_message_id, _messages)
                if type != Broadcaster.BroadcasterType.NONE:
                    break

    if type == Broadcaster.BroadcasterType.NONE:
        push_error("No broadcast was configured for contract %s with id '%s'" % [name, _message_id])

    for node: Node in _receivers:
        if node is BroadcastReceiver:
            var receiver: BroadcastReceiver = node
            receiver.configure(type, _message_id, _messages)

        for child: Node in node.find_children("", "BroadcastReceiver"):
            if child is BroadcastReceiver:
                var receiver: BroadcastReceiver = child
                receiver.configure(type, _message_id, _messages)
