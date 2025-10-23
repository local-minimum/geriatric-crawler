extends Control
class_name BattleCardPrimaryEffectUI

@export
var _attack_texture: Texture

@export
var _heal_texture: Texture

@export
var _shield_texture: Texture

@export
var _self_texture: Texture

@export
var _ally_texture: Texture

@export
var _foe_texture: Texture

@export
var _anyone_texture: Texture

@export
var _no_bonus_texture: Texture

@export
var _bonus_texture: Texture

@export
var _mode: TextureRect

@export
var _target_count: Label

@export
var _random_select: TextureRect

@export
var _target_type: TextureRect

@export
var _effect_magnitude: Label

@export
var _bonus: TextureRect


func _mode_icon(mode: BattleCardPrimaryEffect.EffectMode) -> Texture:
    match mode:
        BattleCardPrimaryEffect.EffectMode.Damage:
            return _attack_texture
        BattleCardPrimaryEffect.EffectMode.Defence:
            return _shield_texture
        BattleCardPrimaryEffect.EffectMode.Heal:
            return _heal_texture

    push_warning("%s not a known effect mode" % BattleCardPrimaryEffect.humanize(mode))
    return null

func _mode_icon_tooltip(mode: BattleCardPrimaryEffect.EffectMode) -> String:
    match mode:
        BattleCardPrimaryEffect.EffectMode.Damage:
            return tr("ATTACK")
        BattleCardPrimaryEffect.EffectMode.Defence:
            return tr("SHIELD")
        BattleCardPrimaryEffect.EffectMode.Heal:
            return tr("HEAL")

    return tr("UNKOWN_ID").format({"type": tr("EFFECT"), "id": mode})

func _target_type_icon(target_type: BattleCardPrimaryEffect.EffectTarget) -> Texture:
    match target_type:
        BattleCardPrimaryEffect.EffectTarget.Self:
            return _self_texture
        BattleCardPrimaryEffect.EffectTarget.Allies:
            return _ally_texture
        BattleCardPrimaryEffect.EffectTarget.Enemies:
            return _foe_texture
        BattleCardPrimaryEffect.EffectTarget.AlliesAndEnemies:
            return _anyone_texture
        BattleCardPrimaryEffect.EffectTarget.SelfAndEnemies:
            # TODO: Make if needed
            push_warning("No separate icon for this yet!")
            return _anyone_texture

    push_warning("%s not a known effect target category" % target_type)
    return null

func _target_type_tooltip(target_type: BattleCardPrimaryEffect.EffectTarget) -> String:
    match target_type:
        BattleCardPrimaryEffect.EffectTarget.Self:
            return tr("SELF")
        BattleCardPrimaryEffect.EffectTarget.Allies:
            return tr("ALLY")
        BattleCardPrimaryEffect.EffectTarget.Enemies:
            return tr("FOE")
        BattleCardPrimaryEffect.EffectTarget.AlliesAndEnemies:
            return tr("A_AND_B").format({"a": tr("ALLIES"), "b": tr("FOES")})
        BattleCardPrimaryEffect.EffectTarget.SelfAndEnemies:
            return tr("A_AND_B").format({"a": tr("SELF"), "b": tr("FOES")})

    return tr("UNKNOWN_ID").format({"type": tr("TARGET"), "id": target_type})

func _bonus_icon(allows_bonus: bool, bonus: int) -> Texture:
    if !allows_bonus:
        return _no_bonus_texture
    if bonus > 0:
        return _bonus_texture
    return null

func _bonus_icon_tooltip(allows_bonus: bool, bonus: int) -> String:
    if !allows_bonus:
        return tr("CANNOT_HAVE_BONUS")
    if bonus > 0:
        return tr("HAS_BONUS")
    return tr("NO_BONUS")

func sync(effect: BattleCardPrimaryEffect, bonus: int) -> void:
    if effect == null:
        _mode.visible = false
        _target_count.text = tr("DOES_NOTHING")
        _random_select.visible = false
        _target_type.visible = false
        _effect_magnitude.visible = false
        _bonus.visible = false
        return

    _mode.texture = _mode_icon(effect.mode)
    _mode.tooltip_text = _mode_icon_tooltip(effect.mode)
    _mode.visible = true

    _target_count.text = BattleCardPrimaryEffect.target_range_text(effect.get_target_range())

    _random_select.visible = effect.targets_random()
    _random_select.tooltip_text = tr("RANDOM_TARGETS")

    var target_type: BattleCardPrimaryEffect.EffectTarget = effect.target_type()
    _target_type.texture = _target_type_icon(target_type)
    _target_type.tooltip_text = _target_type_tooltip(target_type)
    _target_type.visible = true

    var effect_range: Array[int] = effect.get_effect_range(bonus)
    var effect_range_text: String ="%s - %s" % effect_range if effect_range[0] != effect_range[1] else str(effect_range[0])
    _effect_magnitude.text = tr("FOR_VALUE").format({"value": effect_range_text})
    _effect_magnitude.visible = true

    var allows_bonus: bool = effect.allows_crit(effect.targets_allies())
    _bonus.texture = _bonus_icon(allows_bonus, bonus)
    _bonus.tooltip_text = _bonus_icon_tooltip(allows_bonus, bonus)
    _bonus.visible = _bonus.texture != null
