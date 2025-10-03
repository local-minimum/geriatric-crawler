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
# @export var broadcaster: EditorResourcePicker
@export var message_id: LineEdit

var _selected_contract: BroadcastContract:
    set(value):
        _selected_contract = value
        _sync_broadcasts_lister()
        _sync_highlight_contract()

var _known_contracts: Array[BroadcastContract]

func _ready() -> void:
    _sync_create(null)
    _sync_known_contracts()
    _sync_broadcasts_lister()
    _sync_highlight_contract()

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

func _handle_selection_change(selected_nodes: Array[Node]) -> void:
    if selected_nodes.size() == 1:
        _sync_create(selected_nodes[0])
    else:
        _sync_create(null)

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
    pass

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
    return "Msg ID '%s' from %s to %s" % [
        BroadcastContract.get_message_id_text(contract),
        BroadcastContract.get_broadcaster_name(contract),
        BroadcastContract.get_reciever_count(contract),
    ]


func _sync_highlight_contract() -> void:
    if _selected_contract == null:
        selected_container.hide()
    else:
        message_id.text = _selected_contract._message_id
        # broadcaster.text = _selected_contract._broadcaster
        selected_container.show()
