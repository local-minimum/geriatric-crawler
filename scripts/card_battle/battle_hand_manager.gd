extends Control
class_name BattleHandManager

signal on_hand_drawn
signal on_hand_actions_complete
signal on_hand_debug(msg: String)

@export
var _target_controls: Array[Control]

@export
var _draw_time: float = 0.3

@export
var _draw_delta: float = 0.2

@export
var _draw_origin: Control

@export
var slots: BattleCardSlots

@export
var min_slots: int = 5

var hand: Array[BattleCard] = []
var _connected_cards: Array[BattleCard] = []

var _card_tweens: Dictionary[BattleCard, Tween] = {}
var _card_positions: Dictionary[BattleCard, int] = {}
var _reverse_card_positions: Dictionary[int, BattleCard] = {}

func _ready() -> void:
    if slots.on_return_card_to_hand.connect(_return_card_to_hand) != OK:
        push_error("Hand could not connect to return card to hand event")
    if slots.on_slots_shown.connect(_hand_ready) != OK:
        push_error("Hand could not connect to return card to hand event")
    if slots.on_end_slotting.connect(_handle_end_slotting) != OK:
        push_error("Hand could not connect to slotting ended event")

    @warning_ignore_start("return_value_discarded")
    clear_hand()
    @warning_ignore_restore("return_value_discarded")

func cards_in_hand() -> int:
    return hand.size()

#region INTERACTIVITY
func _handle_end_slotting() -> void:
    on_hand_debug.emit("End slotting")
    for card: BattleCard in hand:
        card.interactable = false
        on_hand_debug.emit("%s not interactable" % card.data.id)

    slots.lock_cards()
    on_hand_debug.emit("Locked slotted cards %s" % [slots.slotted_cards])

    for card: BattleCard in hand:
        var tween: Tween = get_tree().create_tween()

        if _card_tweens.has(card):
            _card_tweens[card].kill()

        @warning_ignore_start("return_value_discarded")
        tween.tween_property(
            card,
            "global_position",
            get_centered_position(card, _draw_origin),
            _draw_time,
        ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        @warning_ignore_restore("return_value_discarded")

        tween.play()

        await get_tree().create_timer(_draw_delta).timeout

    slots.lower_slots(func () -> void: on_hand_actions_complete.emit())

func _hand_ready() -> void:
    for card: BattleCard in hand:
        card.interactable = true
#endregion INTERACTIVITY

#region DRAW HAND
func draw_hand(
    cards: Array[BattleCard],
    emit_event: bool = true,
    draw_from_origin: bool = true
) -> void:
    # print_debug("\nNew hand")
    # print_stack()
    visible = true

    for tween: Tween in _card_tweens.values():
        tween.kill()

    _card_tweens.clear()
    _reverse_card_positions.clear()
    _card_positions.clear()
    hand.clear()
    hand.append_array(cards)

    for card: BattleCard in cards:
        card.scale = Vector2.ONE

        if _connected_cards.has(card):
            continue

        on_hand_debug.emit("Hooking up callbacks for %s actions" % card.data.id)

        _connected_cards.append(card)
        if card.on_drag_start.connect(_handle_card_drag_start) != OK:
            push_error("Failed to connect on drag card signal for %s" % card)
        if card.on_drag_card.connect(handle_card_dragged) != OK:
            push_error("Failed to connect on drag card signal for %s" % card)
        if card.on_drag_end.connect(_handle_card_drag_end) != OK:
            push_error("Failed to connect on drag end card signal for %s" % card)
        if card.on_click.connect(_handle_card_click) != OK:
            push_error("Failed to connect on drag end card signal for %s" % card)
        if card.on_debug_card.connect(_handle_card_debug) != OK:
            push_error("Failed to connect on card debug for %s" % card)


    on_hand_debug.emit("\nNew hand is %s" % [cards.map(func (c: BattleCard) -> String: return c.data.id)])
    var n_controls: int = _calculate_slots_range(cards.size())

    _draw_hand.call_deferred(cards, n_controls, emit_event, draw_from_origin)

var _first_card_idx: int
var _last_card_idx: int

func _handle_card_debug(card: BattleCard, msg: String) -> void:
    on_hand_debug.emit("%s: %s" % [card.data.id, msg])

func _calculate_slots_range(n_cards: int) -> int:
    var n_controls: int = _target_controls.size()

    if n_cards > n_controls:
        push_error("Hand only supports %s cards, we got %s" % [n_controls, n_cards])

    # Center layouts
    var matching_min_count: bool = (min_slots % 2) == (n_cards % 2)
    n_controls = clampi(n_cards + _hand_size_offset, min_slots if matching_min_count else min_slots + 1, n_controls)
    for slot_idx: int in range(_target_controls.size()):
        _target_controls[slot_idx].visible = slot_idx < n_controls

    @warning_ignore_start("integer_division")
    _first_card_idx = (n_controls - n_cards) / 2
    @warning_ignore_restore("integer_division")
    _last_card_idx = _first_card_idx + n_cards - 1

    return n_controls

func _draw_hand(
    new_cards: Array[BattleCard],
    n_controls: int,
    emit_event: bool,
    draw_from_origin: bool,
) -> void:
    var card_idx: int = _first_card_idx
    _card_positions.clear()
    _reverse_card_positions.clear()

    for card: BattleCard in new_cards:
        if card_idx >= n_controls:
            var msg: String = "Card %s (idx %s) doesn't fit in hand with %s controls last idx %s" % [card.data.id, card_idx, n_controls, _last_card_idx]
            push_error(msg)
            on_hand_debug.emit(msg)
            break

        # on_hand_debug.emit("Adding %s to hand index %s (max %s)" % [card.data.id, card_idx, _last_card_idx])

        if draw_from_origin:
            card.global_position = get_centered_position(card, _draw_origin)

        card.card_played = false

        card.visible = true
        var tween: Tween = tween_card_to_position(card, card_idx, _draw_time)

        # print_debug("Draw card idx %s (last %s)" % [card_idx, last_card_idx])

        if card_idx == _last_card_idx && emit_event:
            @warning_ignore_start("return_value_discarded")
            tween.connect(
                "finished",
                func() -> void:
                    on_hand_drawn.emit()
            )
            @warning_ignore_restore("return_value_discarded")

        tween.play()

        if draw_from_origin:
            await get_tree().create_timer(_draw_delta).timeout
        card_idx += 1
#endregion DRAW HAND

#region MOVE CARD
func tween_card_to_position(card: BattleCard, target_index: int, duration: float) -> Tween:
    var tween: Tween = get_tree().create_tween()
    var target: Control = _target_controls[target_index]

    if _card_tweens.has(card):
        _card_tweens[card].kill()

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(
        card,
        "global_position",
        get_centered_position(card, target),
        duration,
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    @warning_ignore_restore("return_value_discarded")

    _card_tweens[card] = tween

    if _card_positions.has(card):
        var old_index: int = _card_positions[card]
        if old_index != target_index && _reverse_card_positions.has(old_index) && _reverse_card_positions[old_index] == card:
            @warning_ignore_start("return_value_discarded")
            _reverse_card_positions.erase(old_index)
            @warning_ignore_restore("return_value_discarded")

    _card_positions[card] = target_index

    if  _reverse_card_positions.has(target_index) && _reverse_card_positions[target_index] != card:
        var msg: String = "Card order collision %s (%s replaces %s, index from cache %s)" % [
            target_index, card.data.id, _reverse_card_positions[target_index].data.id, _card_positions.has(card)]
        push_error(msg)
        on_hand_debug.emit(msg)
        _reverse_card_positions[target_index] = card
        _resque_collision(_reverse_card_positions[target_index])
    else:
        _reverse_card_positions[target_index] = card

    # print_debug("%s now  #%s %s %s" % [card, target_index, _card_positions, _reverse_card_positions])
    return tween

static func get_centered_position(subject: Control, target: Control) ->  Vector2:
    return  target.get_global_rect().get_center() - subject.get_global_rect().size * 0.5

const DRAG_DEADZONE: float = 10

func _get_card_position_index(card: BattleCard = null) -> int:
    if _card_positions.has(card) && card != _dragged_card:
        return _card_positions[card]

    if card == null:
        for idx: int in range(_first_card_idx, _last_card_idx + 1):
            if !_reverse_card_positions.has(idx):
                return idx
        return _last_card_idx + 1

    var self_x: float = card.get_global_rect().get_center().x
    var best: int = -1
    var best_delta: float = 0

    for idx: int in range(_first_card_idx, _last_card_idx + 1):
        var control: Control = _target_controls[idx]
        var control_x: float = control.get_global_rect().get_center().x
        var delta: float = abs(self_x - control_x)

        if best < 0 || best_delta > delta:
            best = idx
            best_delta = delta

    if best < 0:
        best = _target_controls.size() - 1

    return clampi(best, _first_card_idx, _last_card_idx)

var _dragged_card: BattleCard

func _handle_card_drag_start(card: BattleCard) -> void:
    _dragged_card = card
    _remove_from_lookups(card)

func handle_card_dragged(card: BattleCard) -> void:
    # _reshape_hand(card)
    var card_index: int = _get_card_position_index(card)
    _handle_card_dragged.call_deferred(card, card_index)

func _remove_from_lookups(card: BattleCard) -> void:
    if _card_positions.has(card):
        var idx: int = _card_positions[card]

        @warning_ignore_start("return_value_discarded")
        _card_positions.erase(card)
        @warning_ignore_restore("return_value_discarded")

        if _reverse_card_positions.has(idx) && _reverse_card_positions[idx] == card:
            @warning_ignore_start("return_value_discarded")
            _reverse_card_positions.erase(idx)
            @warning_ignore_restore("return_value_discarded")

var _hand_size_offset: int = 0

func _reshape_hand(dragged_card: BattleCard) -> void:
    # TODO: Working bad... not sure why
    var _old_size: int = _hand_size_offset

    if slots.is_over_slots(dragged_card):
        _hand_size_offset = 0 # -1 if hand.has(dragged_card) else 0
    else:
        _hand_size_offset = 1 if slots.has_card(dragged_card) else 0

    if _old_size == _hand_size_offset:
        return

    var cards: Array[BattleCard]
    cards.append_array(hand)
    draw_hand(cards, false, false)

func _handle_card_dragged(card: BattleCard, card_index: int) -> void:
    if slots.is_over_slots(card):
        return

    var origin: Vector2 = get_centered_position(card, _target_controls[card_index])
    var offset: Vector2 = card.global_position - origin

    on_hand_debug.emit("Shifting card %s with x offset %s from %s" % [card.data.id, offset.x, card_index])
    if offset.x > DRAG_DEADZONE:
        if _reverse_card_positions.has(card_index):
            var other: BattleCard = _reverse_card_positions[card_index]
            if other.global_position.x < card.global_position.x:
                on_hand_debug.emit("Shifting card right %s (%s) with %s (%s)" % [card.data.id, card.global_position.x, other.data.id, other.global_position.x])
                _remove_from_lookups(other)
                # This will set positions of other to be our old index
                tween_card_to_position(other, card_index + 1, 0.1).play()
    elif offset.x < -DRAG_DEADZONE:
        if _reverse_card_positions.has(card_index):
            var other: BattleCard = _reverse_card_positions[card_index]
            if other.global_position.x > card.global_position.x:
                on_hand_debug.emit("Shifting card left %s (%s) with %s (%s)" % [card.data.id, card.global_position.x, other.data.id, other.global_position.x])
                _remove_from_lookups(other)
                # This will set positions of other to be our old index
                tween_card_to_position(other, card_index - 1, 0.1).play()

func _resque_collision(card: BattleCard) -> void:
    on_hand_debug.emit("Resque collision for %s" % card.data.id)
    _remove_from_lookups(card)
    for idx: int in range(_first_card_idx, _last_card_idx + 1):
        if !_reverse_card_positions.has(idx):
            _card_positions[card] = idx
            _reverse_card_positions[idx] = card
            return

func _handle_card_drag_end(card: BattleCard) -> void:
    if slots.is_over_slots(card):
        hand.erase(card)
        _remove_from_lookups(card)
        if !slots.take(card):
            _return_card_to_hand(card, null)

        # If there was a card in the slot it will organize hand twice in a row
        _organize_hand()

    else:
        var card_idx: int = _get_card_position_index(card)

        if slots.has_card(card):
            @warning_ignore_start("return_value_discarded")
            slots.unslot_card(card)
            @warning_ignore_restore("return_value_discarded")

            hand.append(card)
            _card_positions[card] = card_idx
            if _reverse_card_positions.has(card_idx) && _reverse_card_positions[card_idx] != card:
                _reverse_card_positions[card_idx] = card
                _resque_collision(_reverse_card_positions[card_idx])
            else:
                _reverse_card_positions[card_idx] = card

            _organize_hand()
            return

        on_hand_debug.emit("Releasing card %s onto index %s" % [card.data.id, card_idx])
        var action: Callable = func () -> void:
            tween_card_to_position(card, card_idx, 0.05).play()

        action.call_deferred()

    _dragged_card = null

func _handle_card_click(card: BattleCard) -> void:
    if slots.has_card(card):
        @warning_ignore_start("return_value_discarded")
        slots.unslot_card(card)
        @warning_ignore_restore("return_value_discarded")
        _return_card_to_hand(card, null)
        return

    if slots.take(card, true):
        _remove_from_lookups(card)
        hand.erase(card)
        _organize_hand()

func _return_card_to_hand(card: BattleCard, _position_holder: BattleCard) -> void:
    var idx: int = _get_card_position_index()

    hand.append(card)

    # We neeed to set this here so that it gets returned correctly when redrawing cards
    # as a result of taking another
    _card_positions[card] = idx
    _reverse_card_positions[idx] = card

    on_hand_debug.emit("Returning %s to hand at %s" % [card.data.id, idx])
    _organize_hand()

func _organize_hand() -> void:
    var positions: Array[int] =_reverse_card_positions.keys()
    positions.sort()

    var cards: Array[BattleCard] = []
    for pos: int in positions:
        if _reverse_card_positions[pos] != null:
            cards.append(_reverse_card_positions[pos])

    for card: BattleCard in hand:
        if !cards.has(card):
            cards.append(card)

    draw_hand(cards, false, false)
#endregion MOVE CARD

#region CLEANUP
func round_end_cleanup() -> Array[BattleCardData]:
    return slots.discard_cards()

func clear_hand() -> Array[BattleCardData]:
    var discards: Array[BattleCardData] = []
    for card: BattleCard in hand:
        card.visible = false
        discards.append(card.data)

    hand.clear()
    visible = false
    slots.hide_ui()

    discards.append_array(round_end_cleanup())

    on_hand_debug.emit("Discarding cards %s" % [discards])

    return discards

#endregion
