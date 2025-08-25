extends Button

@export var _slots: BattleCardSlots

@export var _image: TextureRect

@export var _any_slotted_image: Texture

@export var _nothing_slotted_image: Texture

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
        tooltip_text = tr("HAS_SLOTTED_TOOLTIP")
    else:
        _image.texture = _nothing_slotted_image
        tooltip_text = tr("SWAP_HAND_TOOLTIP")

func _handle_nothing_slotted() -> void:
    _image.texture = _nothing_slotted_image
    tooltip_text = tr("SWAP_HAND_TOOLTIP")
