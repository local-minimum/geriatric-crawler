extends Node
class_name Inventory

static var active_inventory: Inventory

## Create this helper in enter tree so it happens before the actual inventory is ready
class InventorySubscriber:
    var inventory: Inventory
    var _persist: bool

    func _init(persist: bool = true) -> void:
        _persist = persist

        if __SignalBus.on_activate_inventory.connect(_handle_activate_inventory) != OK:
            push_error("Failed to connect to activate inventory")
        if __SignalBus.on_deactivate_inventory.connect(_handle_deactivate_inventory) != OK:
            push_error("Failed to connect to deactivate inventory")

    func _handle_activate_inventory(inv: Inventory) -> void:
        if inventory == null || !_persist:
            inventory = inv

    func _handle_deactivate_inventory(inv: Inventory) -> void:
        if inventory == inv:
            inventory = null

            if Inventory.active_inventory != inv:
                inventory = Inventory.active_inventory

var _inventory: Dictionary[String, float] = {}


func _enter_tree() -> void:
    if active_inventory != null && active_inventory != self:
        active_inventory.queue_free()

    active_inventory = self

func _exit_tree() -> void:
    if active_inventory == self:
        active_inventory = null

    __SignalBus.on_deactivate_inventory.emit(self)

func _ready() -> void:
    __SignalBus.on_activate_inventory.emit(self)
    if __SignalBus.on_finalize_loadout.connect(_handle_loadout) != OK:
        push_error("Failed to connect finalize loadout")

func _handle_loadout(loadout: Dictionary[String, float]) -> void:
    if !remove_many_from_inventory(loadout):
        push_error("Failed to remove loadout from inventory, this will cause item duplications of something in %s" % loadout)

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

    __SignalBus.on_add_to_inventory.emit(self, id, amount, _inventory[id])
    if notify:
        NotificationsManager.info(
            tr("NOTICE_INVENTORY"),
            tr("GAINED_ITEM").format({"item": "%10.2f %s [b]%s[/b]" % [amount, LootableManager.unit(id) , LootableManager.translate(id)]}),
            5000,
        )
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
    __SignalBus.on_remove_from_inventory.emit(self, id, withdraw, _inventory[id])
    if notify:
        NotificationsManager.info(
            tr("NOTICE_INVENTORY"),
            tr("LOST_ITEM").format({"item": "%4.3f %s [b]%s[/b]" % [amount, LootableManager.unit(id), LootableManager.translate(id)]}),
            5000,
        )

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
    __SignalBus.on_load_inventory.emit(self)

func collect_save_data() -> Dictionary[String, float]:
    return _inventory
