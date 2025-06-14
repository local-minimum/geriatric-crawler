extends Control
class_name BattleCardSlots

signal on_return_card_to_hand(card: BattleCard, position_holder: BattleCard)
signal on_slots_shown

@export
var _slot_rects: Array[Control] = []

@export
var _max_y_delta: float = 80

func show_slots(visible_slots: int) -> void:
    slotted_cards.clear()

    if slotted_cards.resize(visible_slots) != OK:
        push_error("Couldn't resize slotted cards to be %s long" % visible_slots)

    for tween: Tween in _card_tweens.values():
        tween.kill()

    _card_tweens.clear()

    for slot: Control in _slot_rects:
        slot.visible = false

    visible = true

    var idx: int = 0
    for slot: Control in _slot_rects:
        slot.visible = idx < visible_slots
        idx += 1
        await get_tree().create_timer(0.05).timeout

    if idx < visible_slots:
        push_warning("Requested %s slots, but only has %s configured" % [visible_slots, idx])

    on_slots_shown.emit()

func is_over_slots(card: BattleCard) -> bool:

    var card_rect: Rect2 = card.get_global_rect()

    for slot: Control in _slot_rects:
        if !slot.visible:
            continue

        var slot_rect: Rect2 = slot.get_global_rect()
        if card_rect.intersects(slot_rect):
            return true
    return false

func take(card: BattleCard, first_empty: bool = false) -> bool:
    var best_slot: Control = null
    var best_dist_sq: float
    var card_rect: Rect2 = card.get_global_rect()

    var slot_idx: int = 0
    for slot: Control in _slot_rects:
        if !slot.visible:
            break

        if first_empty:
            if slotted_cards[slot_idx] == null:
                best_slot = slot
                break
            else:
                slot_idx += 1
                continue

        var slot_rect: Rect2 = slot.get_global_rect()
        if card_rect.intersects(slot_rect):
            var dist_sq: float = slot_rect.get_center().distance_squared_to(card_rect.get_center())
            var y_delta: float = card_rect.get_center().y - slot_rect.get_center().y
            if (best_slot == null || dist_sq < best_dist_sq) && y_delta < _max_y_delta:
                best_slot = slot
                best_dist_sq = dist_sq

        slot_idx += 1

    if best_slot == null:
        return false

    tween_card_to_slot(card, best_slot, 0.1).play()

    return true

var _card_tweens: Dictionary[BattleCard, Tween] = {}
var slotted_cards: Array[BattleCard] = []

func tween_card_to_slot(card: BattleCard, target: Control, duration: float) -> Tween:
    var tween: Tween = get_tree().create_tween()

    if _card_tweens.has(card):
        _card_tweens[card].kill()

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        card,
        "global_position",
        BattleHandManager.get_centered_position(card, target),
        duration,
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    @warning_ignore_restore("return_value_discarded")

    var slot_idx: int = _slot_rects.find(target)
    var old_slot: int = unslot_card(card)
    if slotted_cards[slot_idx] != null:
        # Swap slotted cards
        if old_slot >= 0:
            tween_card_to_slot(
                slotted_cards[slot_idx],
                _slot_rects[old_slot],
                duration,
            ).play()
        else:
            on_return_card_to_hand.emit(slotted_cards[slot_idx], card)

    slotted_cards[slot_idx] = card
    _card_tweens[card] = tween

    return tween

func has_card(card: BattleCard) -> bool:
    return slotted_cards.has(card)

func unslot_card(card: BattleCard) -> int:
    var slot_idx: int = slotted_cards.find(card)
    if slot_idx >= 0:
        slotted_cards[slot_idx] = null
    return slot_idx
