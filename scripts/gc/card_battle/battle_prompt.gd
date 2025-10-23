extends Label
class_name BattlePrompt

func _ready() -> void:
    text = ""
    if __SignalBus.on_player_select_targets.connect(_show_prompt) != OK:
        push_error("Failed to connect player select targets")
    if __SignalBus.on_before_execute_effect_on_target.connect(_hide_prompt) != OK:
        push_error("Failed to connect player execute effect")

func _name_target(target_type: BattleCardPrimaryEffect.EffectTarget, count: int) -> String:
    match  target_type:
        BattleCardPrimaryEffect.EffectTarget.None: return tr("NO_ONE")
        BattleCardPrimaryEffect.EffectTarget.Self: return tr("SELF")
        BattleCardPrimaryEffect.EffectTarget.Allies: return tr("ALLY") if count == 1 else tr("ALLIES")
        BattleCardPrimaryEffect.EffectTarget.Enemies: return tr("ENEMY") if count == 1 else tr("ENEMIES")
        BattleCardPrimaryEffect.EffectTarget.AlliesAndEnemies: return tr("ENTITY") if count == 1 else tr("ENTITIES")
        BattleCardPrimaryEffect.EffectTarget.SelfAndEnemies: return tr("A_OR_B").format({"a": tr("SELF"), "b": tr("enemy")}) if count == 1 else tr("A_OR_B").format({"a": tr("SELF"), "b": tr("ENEMIES")})

    return "no-one"

func _name_effect(effect: BattleCardPrimaryEffect.EffectMode) -> String:
    match effect:
        BattleCardPrimaryEffect.EffectMode.Damage: return tr("ATTACK")
        BattleCardPrimaryEffect.EffectMode.Defence: return tr("SHIELD")
        BattleCardPrimaryEffect.EffectMode.Heal: return tr("HEAL")
    return tr("PERFORM_UNKNOWN_EFFECT")

func _show_prompt(
    _player: BattlePlayer,
    count: int,
    _options: Array[BattleEntity],
    effect: BattleCardPrimaryEffect.EffectMode,
    target_type: BattleCardPrimaryEffect.EffectTarget,
) -> void:
    if count == 0:
        _hide_prompt()
        return

    text = tr("SELECT_TO_EFFECT").format({
        "count": count,
        "type": _name_target(target_type, count),
        "effect": _name_effect(effect),
    })
    visible = true

func _hide_prompt(_player: BattlePlayer = null, _target: BattleEntity = null) -> void:
    visible = false
