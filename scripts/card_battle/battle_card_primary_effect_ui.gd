extends Control

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

    return null

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
            push_warning("No separate icon for this yet!")
            return _anyone_texture

    return null

func _bonus_icon(allows_bonus: bool, bonus: int) -> Texture:
    if !allows_bonus:
        return _no_bonus_texture
    if bonus > 0:
        return _bonus_texture
    return null

func sync(effect: BattleCardPrimaryEffect, bonus: int) -> void:
    _mode.texture = _mode_icon(effect.mode)

    _random_select.visible = effect.targets_random()

    _target_type.texture = _target_type_icon(effect.target_type())

    _bonus.texture = _bonus_icon(effect.allows_crit(effect.targets_allies()), bonus)
    _bonus.visible = _bonus.texture != null
