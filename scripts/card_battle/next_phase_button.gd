extends Button

@export
var _slots: BattleCardSlots

@export
var _image: TextureRect

@export
var _any_slotted_image: Texture

@export
var _nothing_slotted_image: Texture

@export
var _any_slotted_tooltip: String = "Click when done slotting cards"

@export
var _nothing_slotted_tooltip: String = "Skip turn but get new hand"

func _ready() -> void:
    if _slots.on_update_slotted.connect(_handle_slotted_updated) != OK:
        push_error("Could not connect update slotted")
    if _slots.on_end_slotting.connect(_handle_nothing_slotted) != OK:
        push_error("Could not connect slotting end")
    if _slots.on_slots_shown.connect(_handle_nothing_slotted) != OK:
        push_error("Could not connect slotting shown")

func _handle_slotted_updated(cards: Array[BattleCard]) -> void:
    if cards.any(func (card: BattleCard) -> bool: return card != null):
        _image.texture = _any_slotted_image
        tooltip_text = _any_slotted_tooltip
    else:
        _image.texture = _nothing_slotted_image
        tooltip_text = _nothing_slotted_tooltip

func _handle_nothing_slotted() -> void:
    _image.texture = _nothing_slotted_image
    tooltip_text = _nothing_slotted_tooltip
