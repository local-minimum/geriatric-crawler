extends Control
class_name EnemyPlayedCardUI

@export var battle: BattleMode
@export var show_index: int
@export var tween_in_duration: float = 0.4
@export var tween_out_duration: float = 0.2
@export var tween_play_duration: float = 0.2
@export var show_size: float = 1.25
@export var play_size: float = 1.5


var _battle_card: BattleCard

func _ready() -> void:
    _load_card()

    if __SignalBus.on_show_enemy_card.connect(_show_card) != OK:
        push_error("Failed to connect to enemy show card")

    if __SignalBus.on_play_enemy_card.connect(_play_card) != OK:
        push_error("Failed to connect to enemy play card")

    if __SignalBus.on_hide_enemy_card.connect(_hide_card) != OK:
        push_error("Failed to connect to enemy hide card")

    if __SignalBus.on_prepare_enemy_hand.connect(_prepare_hand) != OK:
        push_error("Failed to connect to enemy prepare hand")

func _load_card() -> void:
    var _battle_card_resource: PackedScene = load("res://scenes/battle_card.tscn")
    _battle_card = _battle_card_resource.instantiate()
    _battle_card.visible = false
    _battle_card.interactable = false
    self.add_child(_battle_card)
    # _battle_card.owner = self.get_tree().root

var _tween: Tween

func _prepare_hand(_enemy: BattleEntity, slotted_cards: Array[BattleCardData]) -> void:
    visible = show_index < slotted_cards.size()

func _show_card(_enemy: BattleEnemy, card_idx: int, card: BattleCardData, suit_bonus: int, rank_bonus: int) -> void:
    if show_index != card_idx:
        return

    _battle_card.data = card
    _battle_card.sync_display(suit_bonus + rank_bonus)
    _battle_card.position = Vector2.ZERO
    _battle_card.scale = Vector2.ZERO
    _battle_card.rotation_degrees = 0
    _battle_card.visible = true

    if _tween != null && _tween.is_running():
        _tween.kill()

    _tween = get_tree().create_tween()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(
        _battle_card,
        "scale",
        Vector2.ONE * show_size,
        tween_in_duration).set_trans(Tween.TRANS_ELASTIC) #.set_ease(Tween.EASE_OUT_IN)

    var secondary_tween: Tween = _tween.parallel()

    secondary_tween.tween_property(
        _battle_card,
        "rotation_degrees",
        360,
        tween_in_duration * 0.6).set_trans(Tween.TRANS_CUBIC)

    @warning_ignore_restore("return_value_discarded")

    _tween.play()

func _play_card(_battle_enemy: BattleEnemy, card_idx: int) -> void:
    if show_index != card_idx:
        return

    if _tween != null && _tween.is_running():
        _tween.kill()

    _tween = get_tree().create_tween()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(
        _battle_card,
        "scale",
        Vector2.ONE * play_size,
        tween_play_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    @warning_ignore_restore("return_value_discarded")

func _hide_card(_battle_enemy: BattleEnemy, card_idx: int) -> void:
    if show_index != card_idx:
        return

    if _tween != null && _tween.is_running():
        _tween.kill()

    _tween = get_tree().create_tween()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(
        _battle_card,
        "scale",
        Vector2.ZERO,
        tween_out_duration).set_trans(Tween.TRANS_ELASTIC) #.set_ease(Tween.EASE_OUT_IN)
    @warning_ignore_restore("return_value_discarded")

    if _tween.connect(
        "finished",
        func () -> void:
            _battle_card.visible = false
    ) != OK:
        _battle_card.visible = false
        push_error("Could not hide card after tween")
