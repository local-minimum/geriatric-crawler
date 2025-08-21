extends Node
class_name Inventory

static var _CREDITS: int
static var active_inventory: Inventory

signal on_update_credits(credits: int)

signal on_add_to_inventory(id: String, amount: float, total: float)
signal on_remove_from_inventory(id: String, amount: float, total: float)

static func credits() -> int: return _CREDITS

static func withdraw_credits(amount: int) -> bool:
    if amount < 0:
        return false

    if amount <= _CREDITS:
        _CREDITS -= amount
        if active_inventory != null:
            active_inventory.on_update_credits.emit(_CREDITS)

        NotificationsManager.info("Lost", credits_with_sign(amount), 5000)
        return true
    return false

static func set_credits(amount: int) -> void:
    _CREDITS = amount
    if active_inventory != null:
        active_inventory.on_update_credits.emit(_CREDITS)

@export var base_slaying_income: int = 20

@export var enemy_level_bonus: int = 5

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

static func credits_with_sign(amount: int) -> String:
    return "₳ %s" % amount

func _ready() -> void:
    if battle.on_entity_join_battle.connect(_handle_entity_join_battle) != OK:
        push_error("Could not connect entity join battle")
    if battle.on_entity_leave_battle.connect(_handle_enity_leave_battle) != OK:
        push_error("Could not connect entity leave battle")

    on_update_credits.emit(_CREDITS)

func _enter_tree() -> void:
    if active_inventory != null && active_inventory != self:
        active_inventory.queue_free()

    active_inventory = self

func _exit_tree() -> void:
    if active_inventory == self:
        active_inventory = null

func _handle_entity_join_battle(entity: BattleEntity) -> void:
    if entity is BattleEnemy:
        if entity.on_death.connect(_handle_enemy_death) != OK:
            push_error("Could not connect enemy death")


func _handle_enity_leave_battle(entity: BattleEntity) -> void:
    if entity is BattleEnemy:
        entity.on_death.disconnect(_handle_enemy_death)


func _handle_enemy_death(entity: BattleEntity) -> void:
    if entity is BattleEnemy:
        var enemy: BattleEnemy = entity
        var amount: int = base_slaying_income + maxi(0, enemy.level - 1) * enemy_level_bonus + enemy.carried_credits
        _CREDITS += amount
        on_update_credits.emit(_CREDITS)
        NotificationsManager.info("Gained", credits_with_sign(amount), 5000)

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
