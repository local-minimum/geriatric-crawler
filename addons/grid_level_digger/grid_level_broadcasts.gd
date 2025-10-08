@tool
extends Control
class_name GridLevelBroadcasts

const NO_CONTRACT = 99999
@export var panel: GridLevelDiggerPanel
@export var new_help: Control
@export var create_new_info: Label
@export var create_new: Control
@export var broadcasts_lister: MenuButton
@export var selected_container: Control
@export var message_id: LineEdit
@export var change_broadcaster: Button
@export var selected_is_broadcaster: Control
@export var receivers: VBoxContainer
@export var new_receiver: GLDNewNode
@export var messages: VBoxContainer
@export var new_message: GLDNewNode
@export var broadcast_color: Color = Color.ORANGE_RED
@export var receiver_color: Color = Color.ALICE_BLUE
@export var bounding_box_grow: float = 0.1

var _receiver_uis: Array[GLDNodeListing]
var _messages_uis: Array[GLDNodeListing]
var _selection: Node

var _selected_contract: BroadcastContract:
    set(value):
        _require_update_highlight = true
        _selected_contract = value
        _sync_broadcasts_lister()
        _sync_selected_contract()

var _known_contracts: Array[BroadcastContract]

func _ready() -> void:
    _sync_create(null)
    _sync_known_contracts()
    _sync_broadcasts_lister()
    _sync_selected_contract()

func _enter_tree() -> void:
    if !panel.on_update_raw_selection.is_connected(_handle_selection_change):
        if panel.on_update_raw_selection.connect(_handle_selection_change) != OK:
            push_error("Failed to connect update selected nodes")

    if !panel.on_update_level.is_connected(_handle_update_level):
        if panel.on_update_level.connect(_handle_update_level) != OK:
            push_error("Failed to connect update level")

    if !broadcasts_lister.get_popup().id_pressed.is_connected(_handle_select_broadcast):
        if broadcasts_lister.get_popup().id_pressed.connect(_handle_select_broadcast) != OK:
            push_error("Failed to connect zone lister changed")

func _exit_tree() -> void:
    panel.on_update_raw_selection.disconnect(_handle_selection_change)
    panel.on_update_level.disconnect(_handle_update_level)
    broadcasts_lister.get_popup().id_pressed.disconnect(_handle_select_broadcast)

    for mesh: MeshInstance3D in _contract_highlights:
        mesh.queue_free()
    _contract_highlights.clear()


func _handle_selection_change(selected_nodes: Array[Node]) -> void:
    if selected_nodes.size() == 1:
        _selection = selected_nodes[0]
    else:
        _selection = null

    _sync_create(_selection)
    _sync_change_broadcaster()
    _sync_new_reciever()

func _handle_update_level(level: GridLevel) -> void:
    _sync_known_contracts()
    _selected_contract = null

    print_debug("[Grid Level Broadcasts] Updated level")

func _handle_select_broadcast(id: int) -> void:
    var contract: BroadcastContract
    if id == NO_CONTRACT:
        contract = null
    elif id >= 0 && id < _known_contracts.size():
        contract = _known_contracts[id]
    else:
        push_warning("Attempting to select non-existing contract %s, we only know of %s contracts" % [id, _known_contracts.size()])
        contract = null

    if contract == _selected_contract:
        return

    _selected_contract = contract

func _on_create_contract_pressed() -> void:
    if panel.level == null:
        push_error("Cannot create contracts outside grid levels")

    var contract = BroadcastContract.new()
    contract._broadcaster = _selection
    panel.level.broadcasts_parent.add_child(contract, true)
    contract.owner = panel.level.get_tree().edited_scene_root
    _selected_contract = contract

    _sync_known_contracts()
    _sync_selected_contract()

func _sync_create(broadcaster: Node) -> void:
    if broadcaster != null && panel.level != null:
        new_help.hide()
        create_new.show()
        create_new_info.text = "Using \"%s\" as Broadcaster (in its tree)" % broadcaster.name
    else:
        new_help.show()
        create_new.hide()

func _sync_known_contracts() -> void:
    var level: GridLevel = panel.level

    _known_contracts.clear()

    if level == null:
        return

    for contract: BroadcastContract in level.broadcasts_parent.find_children("", "BroadcastContract"):
        _known_contracts.append(contract)

func _sync_broadcasts_lister() -> void:
    var level: GridLevel = panel.level

    if _known_contracts.is_empty():
        broadcasts_lister.disabled = true
        broadcasts_lister.text = "Current scene not a grid level"
        return

    if _selected_contract == null:
        broadcasts_lister.text = "%s contracts in level %s" % [
            _known_contracts.size(),
            level.level_id if level else "???"
        ]
    else:
        broadcasts_lister.text = _name_contract(_selected_contract)

    broadcasts_lister.disabled = _known_contracts.is_empty()

    var popup: PopupMenu = broadcasts_lister.get_popup()

    popup.clear()

    popup.add_radio_check_item("[No contract selected]", NO_CONTRACT)

    for idx: int in range(_known_contracts.size()):
        popup.add_radio_check_item(_name_contract(_known_contracts[idx]), idx)

func _name_contract(contract: BroadcastContract) -> String:
    return "'%s' from %s to %s" % [
        BroadcastContract.get_message_id_text(contract),
        BroadcastContract.get_broadcaster_name(contract),
        BroadcastContract.get_reciever_count(contract),
    ]

func _get_new_receiver_listing() -> GLDNodeListing:
    var scene: PackedScene = load("res://addons/grid_level_digger/controls/node_listing.tscn")
    var listing: GLDNodeListing = scene.instantiate()
    _receiver_uis.append(listing)
    listing.name = "Reciever %s" % _receiver_uis.size()
    receivers.add_child(listing)
    return listing

func _get_new_message_listing() -> GLDNodeListing:
    var scene: PackedScene = load("res://addons/grid_level_digger/controls/node_listing.tscn")
    var listing: GLDNodeListing = scene.instantiate()
    _messages_uis.append(listing)
    listing.name = "Message %s" % _messages_uis.size()
    listing.editable = true
    messages.add_child(listing)
    return listing

func _sync_selected_contract() -> void:
    if _selected_contract == null:
        selected_container.hide()
        return

    message_id.text = _selected_contract._message_id
    selected_container.show()

    _sync_change_broadcaster()
    _sync_recievers()
    _sync_messages()
    _sync_protocol_highlight()

func _sync_change_broadcaster() -> void:
    if _selected_contract == null:
        return

    if _selected_contract._broadcaster == _selection:
        selected_is_broadcaster.show()
        change_broadcaster.hide()
    elif _selection == null:
        selected_is_broadcaster.hide()
        if _selected_contract._broadcaster != null:
            change_broadcaster.text = "Remove \"%s\" as Broadcaster" % _selected_contract._broadcaster.name
            change_broadcaster.show()
        else:
            change_broadcaster.hide()
    else:
        selected_is_broadcaster.hide()
        change_broadcaster.text = "Set \"%s\" as Broadcaster" % _selection.name
        change_broadcaster.show()

func _sync_recievers() -> void:
    var idx: int = 0
    while idx < _selected_contract._receivers.size():
        var ui: GLDNodeListing
        if idx < _receiver_uis.size():
            ui = _receiver_uis[idx]
        else:
            ui = _get_new_receiver_listing()

        var node: Node = _selected_contract._receivers[idx]
        ui.set_node(
            node,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Remove Receiver")
                panel.undo_redo.add_do_method(self, "_remove_receiver_from_contract", _selected_contract, node)
                panel.undo_redo.add_undo_method(self, "_add_receiver_to_contract", _selected_contract, node)
                panel.undo_redo.commit_action()
                ,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Move Receiver Up")
                panel.undo_redo.add_do_method(self, "_swap_recievers", _selected_contract, idx, idx - 1)
                panel.undo_redo.add_undo_method(self, "_swap_recievers", _selected_contract, idx, idx - 1)
                panel.undo_redo.commit_action()
                ,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Move Receiver Down")
                panel.undo_redo.add_do_method(self, "_swap_recievers", _selected_contract, idx, idx + 1)
                panel.undo_redo.add_undo_method(self, "_swap_recievers", _selected_contract, idx, idx + 1)
                panel.undo_redo.commit_action()
                ,
            true,
            idx > 0,
            idx < _selected_contract._receivers.size() - 1,
        )

        ui.show()

        idx += 1

    while idx < _receiver_uis.size():
        _receiver_uis[idx].hide()
        idx += 1

    new_receiver.move_to_front()
    _sync_new_reciever()

func _swap_recievers(contract: BroadcastContract,  a: int, b: int) -> void:
    var r: Node = contract._receivers[a]
    contract._receivers[a] = contract._receivers[b]
    contract._receivers[b] = r
    _sync_selected_contract()

func _sync_new_reciever() -> void:
    if _selected_contract == null:
        return

    new_receiver.set_node(_selection if !_selected_contract._receivers.has(_selection) else null, _add_reciever)

func _add_reciever(node: Node) -> void:
    if _selected_contract == null:
        push_error("Attempted to add new receiver when there's no contract")
        return

    if _selected_contract._receivers.has(node):
        push_error("%s is already a reciever of the selected contract" % node.name)
        return

    panel.undo_redo.create_action("GridLevelBroadcasts: Add Receiver")
    panel.undo_redo.add_do_method(self, "_add_receiver_to_contract", _selected_contract, node)
    panel.undo_redo.add_undo_method(self, "_remove_receiver_from_contract", _selected_contract, node)
    panel.undo_redo.commit_action()

func _add_receiver_to_contract(contract: BroadcastContract, receiver: Node) -> void:
    if !contract._receivers.has(receiver):
        contract._receivers.append(receiver)
        _require_update_highlight = true
    _sync_selected_contract()

func _remove_receiver_from_contract(contract: BroadcastContract, reciever: Node) -> void:
    contract._receivers.erase(reciever)
    _require_update_highlight = true
    _sync_selected_contract()

func _sync_messages() -> void:
    var idx: int = 0
    while idx < _selected_contract._messages.size():
        var ui: GLDNodeListing
        if idx < _messages_uis.size():
            ui = _messages_uis[idx]
        else:
            ui = _get_new_message_listing()

        var text: String = _selected_contract._messages[idx]
        ui.set_text(
            text,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Remove Message")
                panel.undo_redo.add_do_method(self, "_remove_message_from_contract", _selected_contract, idx)
                panel.undo_redo.add_undo_method(self, "_add_message_to_contract", _selected_contract, text)
                panel.undo_redo.commit_action()
                ,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Move Message Up")
                panel.undo_redo.add_do_method(self, "_swap_messages", _selected_contract, idx, idx - 1)
                panel.undo_redo.add_undo_method(self, "_swap_messages", _selected_contract, idx, idx - 1)
                panel.undo_redo.commit_action()
                ,
            func () -> void:
                panel.undo_redo.create_action("GridLevelBroadcasts: Move Message Down")
                panel.undo_redo.add_do_method(self, "_swap_messages", _selected_contract, idx, idx + 1)
                panel.undo_redo.add_undo_method(self, "_swap_messages", _selected_contract, idx, idx + 1)
                panel.undo_redo.commit_action()
                ,
            true,
            idx > 0,
            idx < _selected_contract._messages.size() - 1,
        )

        ui.show()

        idx += 1

    while idx < _messages_uis.size():
        _messages_uis[idx].hide()
        idx += 1

    new_message.move_to_front()
    _sync_new_message()

func _sync_new_message() -> void:
    if _selected_contract == null:
        return

    new_message.editable = true
    new_message.set_text_callback(_add_message)

func _swap_messages(contract: BroadcastContract,  a: int, b: int) -> void:
    var r: String = contract._messages[a]
    contract._messages[a] = contract._messages[b]
    contract._messages[b] = r
    _sync_selected_contract()

func _add_message(message: String) -> void:
    if _selected_contract == null:
        push_error("Attempted to add new receiver when there's no contract")
        return

    panel.undo_redo.create_action("GridLevelBroadcasts: Add Message")
    panel.undo_redo.add_do_method(self, "_add_message_to_contract", _selected_contract, message)
    panel.undo_redo.add_undo_method(self, "_remove_message_from_contract", _selected_contract, _selected_contract._messages.size())
    panel.undo_redo.commit_action()

func _add_message_to_contract(contract: BroadcastContract, message: String) -> void:
    contract._messages.append(message)
    _sync_selected_contract()

func _remove_message_from_contract(contract: BroadcastContract, message_idx: int) -> void:
    contract._messages.remove_at(message_idx)
    _sync_selected_contract()

func _on_change_broadcaster_pressed() -> void:
    if _selected_contract == null:
        push_error("Attempting to change broadcaster without a selected contract")
        return

    panel.undo_redo.create_action("GridLevelBroadcasts: Change Broadcaster")
    panel.undo_redo.add_do_method(self, "_set_contract_broadcaster", _selected_contract, _selection)
    panel.undo_redo.add_undo_method(self, "_set_contract_broadcaster", _selected_contract, _selected_contract._broadcaster)
    panel.undo_redo.commit_action()


func _set_contract_broadcaster(contract: BroadcastContract, caster: Node) -> void:
    contract._broadcaster = caster
    _require_update_highlight = true
    _sync_selected_contract()

var _require_update_highlight: bool = true
var _contract_highlights: Array[MeshInstance3D]

func _sync_protocol_highlight() -> void:
    _require_update_highlight = false

    for mesh: MeshInstance3D in _contract_highlights:
        mesh.queue_free()
    _contract_highlights.clear()

    var level: GridLevel = panel.level
    print_debug("[GLD Broadcasts] updating highlight for %s using %s" % [_selected_contract, level])
    if _selected_contract == null || level == null:
        return

    var caster: Broadcaster = BroadcastContract.get_broadcaster(_selected_contract)
    var arrow_origin: AABB
    if caster != null:
        var node: Node3D = NodeUtils.find_parent_types(caster, ["GridNodeFeature", "GridNodeSide", "GridNode", "Node3D"])
        if node != null:
            var bounds: AABB = AABBUtils.bounding_box(node)
            bounds = bounds.grow(bounding_box_grow)
            arrow_origin = bounds
            var box: MeshInstance3D = DebugDraw.box(
                level,
                bounds.get_center(),
                bounds.size,
                broadcast_color,
                false,
            )
            _contract_highlights.append(box)
            print_debug("[GLD Broadcasts] caster %s highlight added %s" % [node, bounds])
        else:
            print_debug("[GLD Broadcasts] caster %s has no node3d parent" % node)
    else:
        print_debug("[GLD Broadcasts] couldn't find the broadcaster of caster %s " % _selected_contract._broadcaster)

    for receiver: BroadcastReceiver in BroadcastContract.get_receivers(_selected_contract):
        var node: Node3D = NodeUtils.find_parent_types(receiver, ["GridNodeFeature", "GridNodeSide", "GridNode", "Node3D"])
        if node != null:
            var bounds: AABB = AABBUtils.bounding_box(node)
            bounds = bounds.grow(bounding_box_grow)
            var box: MeshInstance3D = DebugDraw.box(
                level,
                bounds.get_center(),
                bounds.size,
                receiver_color,
                false,
            )
            _contract_highlights.append(box)

            if caster != null:
                var from: Vector3 = AABBUtils.closest_surface_point(arrow_origin, bounds.get_center())
                var to: Vector3 = AABBUtils.closest_surface_point(bounds, from)
                var arrow: MeshInstance3D = DebugDraw.arrow(
                    level,
                    from,
                    to,
                    broadcast_color,
                )
                _contract_highlights.append(arrow)
            print_debug("[GLD Broadcasts] reciever %s added %s" % [node, bounds])
        else:
            print_debug("[GLD Broadcasts] reciever %s has no node3d parent" % node)
