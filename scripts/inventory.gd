extends Node
class_name Inventory

static var active_inventory: Inventory

signal on_add_to_inventory(id: String, amount: float, total: float)
signal on_remove_from_inventory(id: String, amount: float, total: float)


@export var battle: BattleMode

var _inventory: Dictionary[String, float] = {}

static func inventory_item_id_to_text(id: String) -> String:
    if id.begins_with(HackingGame.ITEM_HACKING_PREFIX):
        return HackingGame.item_id_to_text(id)

    return id

static func inventory_item_id_to_unit(id: String) -> String:
    if id.begins_with(HackingGame.ITEM_HACKING_PREFIX):
        return ""
    return "kg"

func _enter_tree() -> void:
    if active_inventory != null && active_inventory != self:
        active_inventory.queue_free()

    active_inventory = self

func _exit_tree() -> void:
    if active_inventory == self:
        active_inventory = null

class InventoryListing:
    var id: String
    var amount: float

    func _init(p_id: String, p_amount: float) -> void:
        id = p_id
        amount = p_amount

func get_item_count(id: String) -> float:
    return _inventory.get(id, 0.0)

func list_inventory() -> Array[InventoryListing]:
    var result: Array[InventoryListing]
    for item_id: String in _inventory:
        var amount: float = _inventory[item_id]
        if amount != 0:
            result.append(InventoryListing.new(item_id, amount))

    return result

func add_to_inventory(id: String, amount: float, notify: bool = true) -> bool:
    if amount <= 0:
        return false

    if _inventory.has(id):
        _inventory[id] += amount
    else:
        _inventory[id] = amount

    on_add_to_inventory.emit(id, amount, _inventory[id])
    if notify:
        NotificationsManager.info("Gained", "%10.2f %s [b]%s[/b]" % [amount, inventory_item_id_to_unit(id) , inventory_item_id_to_text(id)], 5000)
    return true

func add_many_to_inventory(items: Dictionary[String, float], notify: bool = true) -> bool:
    if items.values().any(FloatUtils.negative):
        return false

    for id: String in items:
        if KeyRing.is_key(id):
           continue

        if !add_to_inventory(id, items[id], notify):
            return false

    return true

func remove_from_inventory(id: String, amount: float, accept_less: bool = false, notify: bool = true) -> float:
    if !_inventory.has(id) || amount <= 0:
        return 0

    var total: float = _inventory[id]
    if !accept_less && amount > total:
        return 0

    var withdraw: float = min(total, amount)

    _inventory[id] = total - withdraw
    on_remove_from_inventory.emit(id, withdraw, _inventory[id])
    if notify:
        NotificationsManager.info("Lost", "%4.3f %s [b]%s[/b]" % [amount, inventory_item_id_to_unit(id), inventory_item_id_to_text(id)], 5000)

    return withdraw

func remove_many_from_inventory(items: Dictionary[String, float], notify: bool = true) -> bool:
    for id: String in items:
        if !_inventory.has(id) || _inventory[id] < items[id] || items[id] <= 0:
            return false

    for id: String in items:
        @warning_ignore_start("return_value_discarded")
        remove_from_inventory(id, items[id], false, notify)
        @warning_ignore_restore("return_value_discarded")

    return true

func transfer_inventory(receiver: Inventory) -> void:
    for id: String in _inventory:
        var removed: float = remove_from_inventory(id, _inventory[id])
        if !receiver.add_to_inventory(id, removed):
            push_error("%s of %s got lost in the transfer from %s to %s" % [removed, id, self, receiver])

func load_from_save(save: Dictionary[String, float]) -> void:
    _inventory = save

func collect_save_data() -> Dictionary[String, float]:
    return _inventory
