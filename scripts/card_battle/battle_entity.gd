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

static var _HEALTH_KEY: String = "health"

var _health: int = -1:
    set (value):
        print_debug("%s health %s -> %s" % [name, _health, value])
        _health = value

@export var max_health: int = 20

@export var sprite: Texture

func _ready() -> void:
    if _health < 0:
        _health = max_health

## Returns localized entity name
func get_entity_name() -> String:
    push_error("%s doesn't have a name" % name)
    return tr(name)

func get_health() -> int:
    return _health

func get_healthiness() -> float:
    return _health as float / max_health

func validate_health() -> void:
    if _health < 0:
        _health = max_health
        on_heal.emit(self, 0, _health, false)

    if _health > max_health:
        _health = max_health
        on_heal.emit(self, 0, _health, false)

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

func _get_imposing_effects(
    hand: Array[BattleCardData],
) -> Array[BattleCardData.SecondaryEffect]:
    var imposing_effects: Array[BattleCardData.SecondaryEffect]
    for hand_card: BattleCardData in hand:
        if hand_card.secondary_effects.has(BattleCardData.SecondaryEffect.IMPOSING):
            for effect: BattleCardData.SecondaryEffect in hand_card.secondary_effects:
                if effect != BattleCardData.SecondaryEffect.IMPOSING && !imposing_effects.has(effect):
                    imposing_effects.append(effect)

    return imposing_effects

func get_rank_bonus(
    card: BattleCardData,
    rank_bonus: int,
    step_size: int,
    prev_card: BattleCardData,
    rank_direction: int,
    _next_card: BattleCardData,
    first_card: bool,
    allow_descending: bool,
    hand: Array[BattleCardData],
) -> int:
    var imposing_effects: Array[BattleCardData.SecondaryEffect] = _get_imposing_effects(hand)

    if imposing_effects.has(BattleCardData.SecondaryEffect.BREAKING):
        return -step_size

    if prev_card == null:
        return rank_bonus if first_card else 0

    if allow_descending:
        return rank_bonus + step_size if card.rank < prev_card.rank && rank_direction < 0 else 0
    return rank_bonus + step_size if card.rank > prev_card.rank && rank_direction > 0 else 0


func get_suit_bonus(
    card: BattleCardData,
    suit_bonus: int,
    step_size: int,
    prev_card: BattleCardData,
    next_card: BattleCardData,
    first_card: bool,
    hand: Array[BattleCardData],
) -> int:
    var suited_rule: bool = false

    var solid: bool = card.secondary_effects.has(BattleCardData.SecondaryEffect.SOLID)
    var imposing_effects: Array[BattleCardData.SecondaryEffect] = _get_imposing_effects(hand)

    if imposing_effects.has(BattleCardData.SecondaryEffect.ACCELERATED) || card.secondary_effects.has(BattleCardData.SecondaryEffect.ACCELERATED):
        if card.has_identical_suit(prev_card):
            suit_bonus = max(suit_bonus + 1, step_size * 2)
            suited_rule = true
        elif !solid:
            suit_bonus = -step_size
            suited_rule = true

    if imposing_effects.has(BattleCardData.SecondaryEffect.SUITED_UP) || card.secondary_effects.has(BattleCardData.SecondaryEffect.SUITED_UP):
        if card.has_suit_intersection(prev_card) && card.has_suit_intersection(next_card):
            suit_bonus += step_size
            suited_rule = true
        elif !solid:
            suit_bonus = 0
            suited_rule = true

    if imposing_effects.has(BattleCardData.SecondaryEffect.BREAKING) || card.secondary_effects.has(BattleCardData.SecondaryEffect.BREAKING):
        suit_bonus = -step_size
        suited_rule = true

    if !suited_rule && (!first_card || prev_card != null):
        if card.has_suit_intersection(prev_card):
            suit_bonus += step_size
        elif !solid:
            suit_bonus = 0

    return suit_bonus

func play_actions(
    _allies: Array[BattleEntity],
    _enemies: Array[BattleEntity],
    _hand: Array[BattleCardData] = [],
) -> void:
    pass

var _halted: bool = false

func end_turn_early() -> void:
    _halted = true

func clean_up_round() -> void:
    _halted = false

func clean_up_battle() -> void:
    _shields.clear()

func collect_save_data() -> Dictionary:
    return {
        _HEALTH_KEY: _health,
    }
