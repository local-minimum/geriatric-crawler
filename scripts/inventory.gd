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
        return true
    return false

static func set_credits(amount: int) -> void:
    _CREDITS = amount
    if active_inventory != null:
        active_inventory.on_update_credits.emit(_CREDITS)

@export
var base_slaying_income: int = 20

@export
var enemy_level_bonus: int = 5

@export
var battle: BattleMode

var _inventory: Dictionary[String, float] = {}

func _ready() -> void:
    active_inventory = self
    if battle.on_entity_join_battle.connect(_handle_entity_join_battle) != OK:
        push_error("Could not connect entity join battle")
    if battle.on_entity_leave_battle.connect(_handle_enity_leave_battle) != OK:
        push_error("Could not connect entity leave battle")

    on_update_credits.emit(_CREDITS)

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
        _CREDITS += base_slaying_income + maxi(0, enemy.level - 1) * enemy_level_bonus + enemy.carried_credits
        on_update_credits.emit(_CREDITS)

func add_to_inventory(id: String, amount: float) -> bool:
    if amount <= 0:
        return false

    if _inventory.has(id):
        _inventory[id] += amount
    else:
        _inventory[id] = amount

    on_add_to_inventory.emit(id, amount, _inventory[id])
    return true

func add_many_to_inventory(items: Dictionary[String, float]) -> bool:
    if items.values().any(FloatUtils.negative):
        return false

    for id: String in items:
        if !add_to_inventory(id, items[id]):
            return false

    return true

func remove_from_inventory(id: String, amount: float, accept_less: bool = false) -> float:
    if !_inventory.has(id) || amount <= 0:
        return 0

    var total: float = _inventory[id]
    if !accept_less && amount > total:
        return 0

    var withdraw: float = min(total, amount)

    _inventory[id] = total - withdraw
    on_remove_from_inventory.emit(id, withdraw, _inventory[id])

    return withdraw

func remove_many_from_inventory(items: Dictionary[String, float]) -> bool:
    for id: String in items:
        if !_inventory.has(id) || _inventory[id] < items[id] || items[id] <= 0:
            return false

    for id: String in items:
        @warning_ignore_start("return_value_discarded")
        remove_from_inventory(id, items[id])
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
