extends Node
class_name BattleEnemy

signal on_gain_shield(battle_enemy: BattleEnemy, shields: Array[int], new_shield: int)
signal on_break_shield(battle_enemy: BattleEnemy, shields: Array[int], broken_shield: int)

signal on_heal(battle_enemy: BattleEnemy, amount: int, new_health: int, overheal: bool)
signal on_hurt(battle_enemy: BattleEnemy, amount: int, new_health: int)
signal on_death(battle_enemy: BattleEnemy)

signal on_prepare_hand(battle_enemy: BattleEnemy, slotted_cards: Array[BattleCard])


## This is the variant ID of the enemy character in the blob, e.g. "space-slug". It shouldn't be unique. But if there are variants like "space-slug-lvl2" it should be named as such
@export
var variant_id: String

## Human readable / display name
@export
var variant_name: String

@export
var level: int

var _health: int

@export
var max_health: int = 20

@export
var difficulty: int = 0

@export
var sprite: Texture

@export
var hand_size: int = 3

@export
var play_slots: int = 1

@export
var deck: BattleDeck

@export
var brain: BattleBrain

var _shields: Array[int] = []

func _ready() -> void:
    _health = max_health

func get_shields() -> Array[int]:
    return _shields

func get_health() -> int:
    return _health

func is_alive() -> bool:
    return _health > 0

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

var _hand: Array[BattleCardData]
var _slotted: Array[BattleCardData]

func initiative() -> int:
    if _slotted.is_empty():
        return 0

    return _slotted[0].rank

func passing() -> bool:
    return _slotted.is_empty()

## Draws cards and asks a strategy to slot them
func prepare_hand() -> void:
    var draw_cards: int = hand_size - _hand.size()
    _hand.append_array(deck.draw(draw_cards))
    _slotted = brain.select_cards(_hand, play_slots)

    for card: BattleCardData in _slotted:
        _hand.erase(card)

    on_prepare_hand.emit(self, _slotted)
