extends Node
class_name BattleEntity

signal on_gain_shield(battle_entitiy: BattleEntity, shields: Array[int], new_shield: int)
signal on_break_shield(battle_entity: BattleEntity, shields: Array[int], broken_shield: int)

signal on_heal(battle_entity: BattleEntity, amount: int, new_health: int, overheal: bool)
signal on_hurt(battle_entity: BattleEntity, amount: int, new_health: int)
signal on_death(battle_entity: BattleEntity)

# Used by subclasses
@warning_ignore_start("unused_signal")
signal on_start_turn(entity: BattleEntity)
signal on_end_turn(entity: BattleEntity)
@warning_ignore_restore("unused_signal")

var _health: int

@export
var max_health: int = 20

@export
var sprite: Texture

func _ready() -> void:
    _health = max_health

func get_entity_name() -> String:
    push_error("%s doesn't have a name" % name)
    return name

func get_health() -> int:
    return _health

func get_healthiness() -> float:
    return _health as float / max_health

func is_alive() -> bool:
    return _health > 0

var _shields: Array[int] = []

func get_shields() -> Array[int]:
    return _shields

func add_shield(shield: int) -> void:
    _shields.append(shield)
    on_gain_shield.emit(self, _shields, shield)

func hurt(amount: int) -> void:
    while  _shields.size():
        var shield: int = _shields.pop_front()
        amount = max(0, amount - shield)

        on_break_shield.emit(self, _shields, shield)
        print_debug("Broke shield %s, %s damage remaining" % [shield, amount])
        await get_tree().create_timer(0.2).timeout

        if amount == 0:
            break

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


func get_suit_bonus(
    card: BattleCardData,
    suit_bonus: int,
    prev_card: BattleCardData,
    next_card: BattleCardData,
    first_card: bool,
) -> int:
    var suited_rule: bool = false

    if card.secondary_effects.has(BattleCardData.SecondaryEffect.Accelerated):
        if card.has_identical_suit(prev_card):
            suit_bonus = max(suit_bonus + 1, suit_bonus * 2)
        else:
            suit_bonus = -1
        suited_rule = true

    if card.secondary_effects.has(BattleCardData.SecondaryEffect.SuitedUp):
        if card.has_suit_intersection(prev_card) && card.has_suit_intersection(next_card):
            suit_bonus += 1
        else:
            suit_bonus = 0
        suited_rule = true

    if !suited_rule && first_card:
        if card.has_suit_intersection(prev_card):
            suit_bonus += 1
        else:
            suit_bonus = 0

    return suit_bonus

func play_actions(
    _allies: Array[BattleEntity],
    _enemies: Array[BattleEntity],
) -> void:
    pass

var _halted: bool = false

func end_turn_early() -> void:
    _halted = true

func clean_up_round() -> void:
    _halted = false
