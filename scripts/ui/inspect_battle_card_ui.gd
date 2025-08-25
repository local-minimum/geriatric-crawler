extends Control
class_name InspectBattleCardUI

@export var card: BattleCard

@export var label: Label

func _ready() -> void:
    card.interactable = false

func sync(data: BattleCardData, count: int) -> void:
    card.data = data
    if count > 1:
        label.text = tr("ON_CARD") if count == 1 else tr("CARD_COUNT").format({"count": count})
        label.visible = true
    else:
        label.visible = false
