extends Node
class_name BattleEnemyTargetSystem

@export
var _kill_bonus: float = 2

@export_range(0, 1)
var _hit_unhealthy: float = 0.7

@export_range(0, 1)
var _hit_unshielded: float = 0.4

@export_range(0, 1)
var _prioritize_self: float = 0.6

@export
var _self: BattleEnemy

func get_target_order(
    effect: BattleCardPrimaryEffect,
    suit_bonus: int,
    targets: Array[BattleEntity],
    n_targets: int,
    allies: Array[BattleEntity],
) -> Array[int]:
    match effect.mode:
        BattleCardPrimaryEffect.EffectMode.Damage: return _get_attack_order(effect, suit_bonus, targets, n_targets, allies)
        BattleCardPrimaryEffect.EffectMode.Heal: return _get_heal_order(targets, n_targets, allies)
        BattleCardPrimaryEffect.EffectMode.Defence: return _get_shield_order(targets, n_targets, allies)

    push_error("Effect mode %s not handled using random order" % BattleCardPrimaryEffect.humanize(effect.mode))
    var target_order: Array[int] = ArrayUtils.int_range(targets.size())
    target_order.shuffle()
    return target_order

func _get_attack_order(
    effect: BattleCardPrimaryEffect,
    suit_bonus: int,
    targets: Array[BattleEntity],
    n_targets: int,
    allies: Array[BattleEntity],
) -> Array[int]:
    var weights: Dictionary[BattleEntity, float] = {}

    for target: BattleEntity in targets:
        var priority: float = -1 if allies.has(target) else 1
        var healthyness: float = target.get_healthiness()
        var shielding: Array[int] = target.get_shields()
        var effect_range: Array[int] = effect.get_effect_range(
            suit_bonus if effect.allows_crit(allies.has(target)) else 0
        )
        @warning_ignore_start("integer_division")
        var effect_magnitude: int = (effect_range[0] + effect_range[1]) / 2
        @warning_ignore_restore("integer_division")

        var kill_bonus: float = _kill_bonus if target.get_health() < effect_range[1] else 0.0

        priority *= 1 + kill_bonus + (1 - healthyness) * _hit_unhealthy + (
            _hit_unshielded * effect_magnitude if shielding.size() == 0 else _shield_bashing_score(shielding, effect_magnitude))

        weights[target] = priority

    return _get_targets(weights, targets, n_targets)

func _shield_bashing_score(shields: Array[int], effect: int) -> float:
    var shields_bashed: int = 0
    for shield: int in shields:
        effect = max(effect - shield, 0)
        shields_bashed += 1
        if effect == 0:
            break

    return _hit_unshielded * effect + (1 - _hit_unshielded) * shields_bashed

func _get_heal_order(
    targets: Array[BattleEntity],
    n_targets: int,
    allies: Array[BattleEntity],
) -> Array[int]:
    var weights: Dictionary[BattleEntity, float] = {}

    for target: BattleEntity in targets:
        var priority: float = 1 if allies.has(target) else -1
        var healable_fraction: float = 1 - target.get_healthiness()
        var is_self: bool = target == _self

        # TODO: Consider avoiding overhealing
        priority *= 1 + (
            _prioritize_self * healable_fraction if is_self else (1 - _prioritize_self) * healable_fraction
        )

        weights[target] = priority

    return _get_targets(weights, targets, n_targets)

func _get_shield_order(
    targets: Array[BattleEntity],
    n_targets: int,
    allies: Array[BattleEntity],
) -> Array[int]:
    var weights: Dictionary[BattleEntity, float] = {}

    for target: BattleEntity in targets:
        var priority: float = 1 if allies.has(target) else -1
        var missing_health_factor: float = 1.5 - target.get_healthiness()
        var shielding: Array[int] = target.get_shields()

        var shielding_factor: float = shielding.size() * ArrayUtils.sumi(shielding) + 1

        var need: float = missing_health_factor + target.max_health / shielding_factor

        var is_self: bool = target == _self

        priority *= 1 + (
            _prioritize_self * need if is_self else (1 - _prioritize_self) * need
        )

        weights[target] = priority

    return _get_targets(weights, targets, n_targets)

func _get_targets(
    weights: Dictionary[BattleEntity, float],
    targets: Array[BattleEntity],
    n_targets: int
) -> Array[int]:
    var target_order: Array[int] = ArrayUtils.int_range(targets.size())
    target_order.sort_custom(
        func (a: int, b: int) -> bool:
            return weights[targets[a]] > weights[targets[b]]
    )

    return target_order.slice(n_targets)
