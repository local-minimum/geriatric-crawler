extends NinePatchRect
class_name BattleCard

@export
var suite_icon: TextureRect

@export
var suite_electricity: Texture

@export
var suite_metal: Texture

@export
var suite_data: Texture

@export
var suite_electricity_metal: Texture

@export
var suite_metal_data: Texture

@export
var suite_data_electricity: Texture

@export
var suite_data_electricity_metal: Texture

@export
var rank_label: Label

@export
var card_icon: TextureRect

@export
var primary_effect: RichTextLabel

@export
var divider: Control

@export
var secondary_effect: RichTextLabel

var data: BattleCardData:
    set(value):
        data = value
        sync_display(0)

func sync_display(crit_multiplyer: int) -> void:
        suite_icon.visible = data.suit != BattleCardData.SUIT_NONE
        suite_icon.texture = _get_suite_icon_texture(data.suit)

        rank_label.text = str(data.rank)
        card_icon.texture = data.icon

        var primary_effect_parts: Array[String] = [data.name]
        for effect: BattleCardPrimaryEffect in data.primary_effects:
            primary_effect_parts.append(_get_primary_effect_text(effect, crit_multiplyer))
        primary_effect.text = "%s\n%s" % primary_effect_parts

        if data.secondary_effects.is_empty():
            divider.visible = false
            secondary_effect.visible = false
        else:
            divider.visible = true
            secondary_effect.visible = true
            secondary_effect.text = "\n".join(data.secondary_effect_names())

func _get_suite_icon_texture(suite: int) -> Texture:
    match suite:
        BattleCardData.SUIT_ELECTRICITY: return suite_electricity
        BattleCardData.SUIT_DATA: return suite_data
        BattleCardData.SUIT_METAL: return suite_metal

        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_DATA: return suite_data_electricity
        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_METAL: return suite_electricity_metal
        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL: return suite_metal_data

        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL | BattleCardData.SUIT_ELECTRICITY: return suite_data_electricity_metal

        _:
            push_error("Suite %s (%s) doesn't have an icon" % [BattleCardData.suit_name(suite), suite])
            print_stack()
            return null

func _get_primary_effect_text(effect: BattleCardPrimaryEffect, crit_multiplyer: int) -> String:
    var target_range: String = BattleCardPrimaryEffect.target_range_text(effect.get_target_range())
    var effect_range: Array[int] = effect.get_effect_range(crit_multiplyer)

    var can_crit: bool = effect.can_crit()

    return "%s %s %s for %s%s" % [
        effect.mode_name(),
        target_range,
        effect.target_type_text(),
        "% - %" % effect_range if effect_range[0] != effect_range[1] else str(effect_range[0]),
        "*" if can_crit else "",
    ]
