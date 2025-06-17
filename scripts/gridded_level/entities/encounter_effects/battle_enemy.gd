extends Node
class_name BattleEnemy

signal on_gain_shield(battle_enemy: BattleEnemy, shields: Array[int])
signal on_break_shield(battle_enemy: BattleEnemy, shields: Array[int], broken_shield: int)
signal on_hurt(battle_enemy: BattleEnemy, amount: int, new_health: int)
signal on_heal(battle_enemy: BattleEnemy, amount: int, new_health: int, overheal: bool)
signal on_death(battle_enemy: BattleEnemy)


## This is the variant ID of the enemy character in the blob, e.g. "space-slug". It shouldn't be unique. But if there are variants like "space-slug-lvl2" it should be named as such
@export
var variant_id: String

@export
var variant_name: String

@export
var level: int

@export
var deck: BattleDeck

var _health: int

@export
var max_health: int = 20

@export
var difficulty: int = 0

@export
var sprite: Texture

var _shields: Array[int] = []

func _ready() -> void:
    _health = max_health

func get_shields() -> Array[int]:
    return _shields

func get_health() -> int:
    return _health

func add_shield(shield: int) -> void:
    _shields.append(shield)
    on_gain_shield.emit(self, _shields, shield)

func hurt(amount: int) -> void:
    while  _shields.size():
        var shield: int = _shields.pop_front()
        amount = max(0, amount - shield)
        if amount == 0:
            break

        on_break_shield.emit(self, _shields, shield)

    _health = max(0, _health - amount)
    on_hurt.emit(self, amount, _health)

    if _health == 0:
        on_death.emit(self)

func heal(amount: int) -> void:
    if amount < 0:
        push_error("Negative heals not allowed (%s)" % amount)
        print_stack()
        return

    var raw_new: int = _health + amount
    var overshoot: bool = raw_new > max_health
    _health = min(raw_new, max_health)

    on_heal.emit(self, amount - (raw_new - _health), _health, overshoot)
