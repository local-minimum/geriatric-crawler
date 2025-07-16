extends Node
class_name ExplorationInventory

static var _CREDITS: int
static var _INVENTORY: ExplorationInventory

signal on_update_credits(credits: int)


static func credits() -> int: return _CREDITS

static func withdraw(amount: int) -> bool:
    if amount <= _CREDITS:
        _CREDITS -= amount
        if _INVENTORY != null:
            _INVENTORY.on_update_credits.emit(_CREDITS)
        return true
    return false

@export
var base_slaying_income: int = 20

@export
var enemy_level_bonus: int = 5

@export
var battle: BattleMode

func _ready() -> void:
    _INVENTORY = self
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
