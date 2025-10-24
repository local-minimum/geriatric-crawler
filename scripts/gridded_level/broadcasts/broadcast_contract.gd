extends Node
class_name BroadcastContract

@export var _broadcaster: Node
@export var _receivers: Array[Node]
@export var _message_id: String
@export var _messages: Array[String]

func _ready() -> void:
    var type: Broadcaster.BroadcasterType = Broadcaster.BroadcasterType.NONE


    var caster: Broadcaster = get_broadcaster(self)
    if caster != null:
        type = caster.configure(_message_id, _messages)

    if type == Broadcaster.BroadcasterType.NONE:
        push_error("No broadcast was configured for contract %s with id '%s'" % [name, _message_id])

    for reciever: BroadcastReceiver in get_receivers(self):
        reciever.configure(type, _message_id, _messages)

static func get_message_id_text(contract: BroadcastContract) -> String:
    if contract._message_id.is_empty():
        return "[NO MESSAGE]"
    return contract._message_id

static func get_broadcaster_name(contract: BroadcastContract) -> String:
    if contract._broadcaster != null:
        return contract._broadcaster.name

    return "[NO BROADCASTER]"

static func get_reciever_count(contract: BroadcastContract) -> int:
    return contract._receivers.size()

static func get_broadcaster(contract: BroadcastContract) -> Broadcaster:
    if contract._broadcaster == null:
        return null

    if contract._broadcaster is Broadcaster:
        return contract._broadcaster

    for node: Node in contract._broadcaster.find_children("", "Broadcaster"):
        if node is Broadcaster:
            return node
    return null

static func get_receivers(contract: BroadcastContract) -> Array[BroadcastReceiver]:
    var receivers: Array[BroadcastReceiver]

    for node: Node in contract._receivers:
        if node is BroadcastReceiver:
            receivers.append(node)

        for child: Node in node.find_children("", "BroadcastReceiver"):
            if child is BroadcastReceiver:
                receivers.append(child)

    return receivers

static func get_orphan_receivers(contract: BroadcastContract) -> Array[Node]:
    var orphans: Array[Node]

    for node: Node in contract._receivers:
        if node is BroadcastReceiver:
            continue

        if node.find_children("", "BroadcastReceiver").is_empty():
            orphans.append(node)

    return orphans
