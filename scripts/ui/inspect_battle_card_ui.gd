extends Control
class_name InspectBattleCardUI

@export
var card: BattleCard

@export
var label: Label

func _ready() -> void:
    card.interactable = false

func sync(data: BattleCardData, count: int) -> void:
    card.data = data
    if count > 1:
        label.text = "%s card%s" % [count, "" if count == 1 else "s"]
        label.visible = true
    else:
        label.visible = false
