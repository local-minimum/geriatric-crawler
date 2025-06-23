extends Control
class_name BattleHandManager

signal on_hand_drawn
signal on_hand_actions_complete

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

var _hand: Array[BattleCard] = []
var _connected_cards: Array[BattleCard] = []

var _card_tweens: Dictionary[BattleCard, Tween] = {}
var _card_positions: Dictionary[BattleCard, int] = {}
var _reverse_card_positions: Dictionary[int, BattleCard] = {}

func _ready() -> void:
    if slots.on_return_card_to_hand.connect(return_card_to_hand) != OK:
        push_error("Hand could not connect to return card to hand event")
    if slots.on_slots_shown.connect(_hand_ready) != OK:
        push_error("Hand could not connect to return card to hand event")
    if slots.on_end_slotting.connect(_handle_end_slotting) != OK:
        push_error("Hand could not connect to slotting ended event")
    clear_hand()

func cards_in_hand() -> int:
    return _hand.size()

func _handle_end_slotting() -> void:
    for card: BattleCard in _hand:
        card.interactable = false

    slots.lock_cards()

    for card: BattleCard in _hand:
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
    for card: BattleCard in _hand:
        card.interactable = true

func draw_hand(
    new_cards: Array[BattleCard],
    emit_event: bool = true,
    draw_from_origin: bool = true
) -> void:
    visible = true
    for tween: Tween in _card_tweens.values():
        tween.kill()

    _card_tweens.clear()
    _reverse_card_positions.clear()
    _card_positions.clear()
    _hand.clear()

    for card: BattleCard in new_cards:
        if _connected_cards.has(card):
            continue
        _connected_cards.append(card)
        if card.on_drag_card.connect(handle_card_dragged) != OK:
            push_error("Failed to connect on drag card signal for %s" % card)
        if card.on_drag_end.connect(_handle_card_drag_end) != OK:
            push_error("Failed to connect on drag end card signal for %s" % card)
        if card.on_click.connect(_handle_card_click) != OK:
            push_error("Failed to connect on drag end card signal for %s" % card)

    var n_cards: int = new_cards.size()
    var n_controls: int = _target_controls.size()

    if n_cards > n_controls:
        push_error("Hand only supports %s cards, we got %s" % [n_controls, n_cards])

    # Center layouts
    var matching_min_count: bool = (min_slots % 2) == (n_cards % 2)
    n_controls = clampi(n_cards, min_slots if matching_min_count else min_slots + 1, n_controls)
    for slot_idx: int in range(_target_controls.size()):
        _target_controls[slot_idx].visible = slot_idx < n_controls

    @warning_ignore_start("integer_division")
    var card_idx: int = (n_controls - n_cards) / 2
    @warning_ignore_restore("integer_division")
    var last_card_idx: int = card_idx + n_cards - 1

    _draw_hand.call_deferred(new_cards, card_idx, n_controls, last_card_idx, emit_event, draw_from_origin)

func clear_hand() -> void:
    round_end_cleanup()
    for card: BattleCard in _hand:
        card.visible = false
    _hand.clear()
    visible = false
    slots.hide_ui()

func _draw_hand(
    cards: Array[BattleCard],
    card_idx: int,
    n_controls: int,
    last_card_idx: int,
    emit_event: bool,
    draw_from_origin: bool,
) -> void:
    for card: BattleCard in _hand + cards:
        if card_idx >= n_controls:
            break

        if draw_from_origin:
            card.global_position = get_centered_position(card, _draw_origin)

        card.card_played = false

        card.visible = true
        var tween: Tween = tween_card_to_position(card, card_idx, _draw_time)

        # print_debug("Draw card idx %s (last %s)" % [card_idx, last_card_idx])

        if card_idx == last_card_idx && emit_event:
            @warning_ignore_start("return_value_discarded")
            tween.connect(
                "finished",
                func() -> void:
                    on_hand_drawn.emit()
            )
            @warning_ignore_restore("return_value_discarded")

        tween.play()

        if !_hand.has(card):
            _hand.append(card)

        if draw_from_origin:
            await get_tree().create_timer(_draw_delta).timeout
        card_idx += 1

func _last_card_position() -> int:
    return _card_positions.values().max()

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
    _card_positions[card] = target_index
    _reverse_card_positions[target_index] = card

    # print_debug("%s now  #%s %s %s" % [card, target_index, _card_positions, _reverse_card_positions])
    return tween

static func get_centered_position(subject: Control, target: Control) ->  Vector2:
    return  target.get_global_rect().get_center() - subject.get_global_rect().size * 0.5

const DRAG_DEADZONE: float = 10

func _get_card_position_index(card: BattleCard) -> int:
    if _card_positions.has(card):
        return _card_positions[card]

    var best: int = -1
    var best_delta: int = _target_controls.size()
    var mid: float = float(_target_controls.size()) / 2
    for idx: int in range(_target_controls.size()):
        if _reverse_card_positions.has(idx) && _reverse_card_positions[idx] != null:
            continue

        var delta: int = absi(roundi(idx - mid))
        if delta < best_delta:
            best_delta = delta
            best = idx

    if best < 0:
        best = _target_controls.size() - 1

    _target_controls[best].visible = true

    return best


func handle_card_dragged(card: BattleCard) -> void:
    # Moved card goes last, not great
    var card_index: int = _get_card_position_index(card)
    _handle_card_dragged.call_deferred(card, card_index)

func _handle_card_dragged(card: BattleCard, card_index: int) -> void:
    if slots.is_over_slots(card):
        return

    var origin: Vector2 = get_centered_position(card, _target_controls[card_index])
    var offset: Vector2 = card.global_position - origin

    if offset.x > DRAG_DEADZONE:
        if _reverse_card_positions.has(card_index + 1):
            var other: BattleCard = _reverse_card_positions[card_index + 1]
            if other.global_position.x < card.global_position.x:
                _card_positions[card] = card_index + 1
                _reverse_card_positions[card_index + 1] = card
                tween_card_to_position(other, card_index, 0.1).play()
    elif offset.x < -DRAG_DEADZONE:
        if _reverse_card_positions.has(card_index - 1):
            var other: BattleCard = _reverse_card_positions[card_index - 1]
            if other.global_position.x > card.global_position.x:
                _card_positions[card] = card_index - 1
                _reverse_card_positions[card_index - 1] = card
                tween_card_to_position(other, card_index, 0.1).play()

func _handle_card_drag_end(card: BattleCard) -> void:
    if slots.take(card):
        if _card_positions.has(card):
            _remove_card(card)
    else:
        var card_idx: int = _get_card_position_index(card)

        if slots.has_card(card):
            @warning_ignore_start("return_value_discarded")
            slots.unslot_card(card)
            @warning_ignore_restore("return_value_discarded")

            _reverse_card_positions[card_idx] = card
            _organize_hand()
            return

        var action: Callable = func () -> void:
            tween_card_to_position(card, card_idx, 0.05).play()

        action.call_deferred()

func _handle_card_click(card: BattleCard) -> void:
    if slots.has_card(card):
        @warning_ignore_start("return_value_discarded")
        slots.unslot_card(card)
        @warning_ignore_restore("return_value_discarded")
        return_card_to_hand(card, null)
        return

    if slots.take(card, true):
        if _card_positions.has(card):
            _remove_card(card)

func return_card_to_hand(card: BattleCard, position_holder: BattleCard) -> void:
    var idx: int = _get_card_position_index(position_holder)

    # We neeed to set this here so that it gets returned correctly when redrawing cards
    # as a result of taking another
    _card_positions[card] = idx
    _reverse_card_positions[idx] = card

    _organize_hand()

func _remove_card(removed_card: BattleCard) -> void:
    if !_card_positions.has(removed_card):
        push_error("%s not known card in %s" % [removed_card, _card_positions])
        return

    if !_reverse_card_positions.erase(_card_positions[removed_card]):
        push_error("%s not known reverse card position %s in reverse card positions %s" % [removed_card, _card_positions[removed_card], _card_positions])
        return

    if !_card_positions.erase(removed_card):
        push_error("%s not known card position %s in reverse card positions %s" % [removed_card, _card_positions[removed_card], _card_positions])

    _organize_hand()

func _organize_hand() -> void:
    var positions: Array[int] =_reverse_card_positions.keys()
    positions.sort()

    var cards: Array[BattleCard] = []
    for pos: int in positions:
        if _reverse_card_positions[pos] != null:
            cards.append(_reverse_card_positions[pos])

    draw_hand(cards, false, false)

func round_end_cleanup() -> void:
    for card: BattleCard in slots.slotted_cards:
        if card == null:
            continue

        @warning_ignore_start("return_value_discarded")
        slots.unslot_card(card)
        @warning_ignore_restore("return_value_discarded")
        card.visible = false
