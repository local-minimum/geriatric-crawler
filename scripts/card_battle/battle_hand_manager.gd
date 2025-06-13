extends Node
class_name BattleHandManager

signal on_hand_drawn

@export
var _target_controls: Array[Control]

@export
var _draw_time: float = 0.3

@export
var _draw_delta: float = 0.2

@export
var _draw_origin: Control

var _hand: Array[BattleCard] = []
var _connected_cards: Array[BattleCard] = []

func draw_hand(cards: Array[BattleCard]) -> void:
    _hand.clear()

    for card: BattleCard in cards:
        if _connected_cards.has(card):
            continue
        _connected_cards.append(card)
        if card.on_drag_card.connect(handle_card_dragged) != OK:
            push_error("Failed to connect on drag card signal for %s" % card)
        if card.on_drag_end.connect(handle_card_drag_end) != OK:
            push_error("Failed to connect on drag end card signal for %s" % card)

    var n_cards: int = cards.size()
    var n_controls: int = _target_controls.size()

    if n_cards > n_controls:
        push_error("Hand only supports %s cards, we got %s" % [n_controls, n_cards])

    # Center layouts
    if n_cards % 2 != n_controls % 2:
        _target_controls[n_controls - 1].visible = false
        n_controls -= 1

    @warning_ignore_start("integer_division")
    var card_idx: int = (n_controls - n_cards) / 2
    @warning_ignore_restore("integer_division")
    var last_card_idx: int = card_idx + n_cards - 1

    _draw_hand.call_deferred(cards, card_idx, n_controls, last_card_idx)

func hide_hand() -> void:
    for card: BattleCard in _hand:
        card.visible = false
    _hand.clear()

func _draw_hand(cards: Array[BattleCard], card_idx: int, n_controls: int, last_card_idx: int) -> void:
    for card: BattleCard in cards:
        if card_idx >= n_controls:
            break

        card.global_position = get_centered_position(card, _draw_origin)
        card.visible = true
        var tween: Tween = tween_card_to_position(card, card_idx, _draw_time)

        print_debug("Draw card idx %s (last %s)" % [card_idx, last_card_idx])

        if card_idx == last_card_idx:
            @warning_ignore_start("return_value_discarded")
            tween.connect(
                "finished",
                func() -> void:
                    on_hand_drawn.emit()
            )
            @warning_ignore_restore("return_value_discarded")

        tween.play()

        _hand.append(card)

        await get_tree().create_timer(_draw_delta).timeout
        card_idx += 1

var _card_tweens: Dictionary[BattleCard, Tween] = {}
var card_positions: Dictionary[BattleCard, int] = {}
var reverse_card_positions: Dictionary[int, BattleCard] = {}

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
    card_positions[card] = target_index
    reverse_card_positions[target_index] = card

    return tween

static func get_centered_position(subject: Control, target: Control) ->  Vector2:
    return  target.get_global_rect().get_center() - subject.get_global_rect().size * 0.5

const DRAG_DEADZONE: float = 10

func handle_card_dragged(card: BattleCard) -> void:
    var card_index: int = card_positions[card]
    var offset: Vector2 = card.global_position - get_centered_position(card, _target_controls[card_index])

    if offset.x > DRAG_DEADZONE:
        if reverse_card_positions.has(card_index + 1):
            var other: BattleCard = reverse_card_positions[card_index + 1]
            if other.global_position.x < card.global_position.x:
                card_positions[card] = card_index + 1
                reverse_card_positions[card_index + 1] = card
                tween_card_to_position(other, card_index, 0.1).play()
    elif offset.x < -DRAG_DEADZONE:
        if reverse_card_positions.has(card_index - 1):
            var other: BattleCard = reverse_card_positions[card_index - 1]
            if other.global_position.x > card.global_position.x:
                card_positions[card] = card_index - 1
                reverse_card_positions[card_index - 1] = card
                tween_card_to_position(other, card_index, 0.1).play()

func handle_card_drag_end(card: BattleCard) -> void:
    tween_card_to_position(card, card_positions[card], 0.05).play()
