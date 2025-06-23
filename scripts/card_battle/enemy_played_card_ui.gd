extends Node
class_name EnemyPlayedCardUI

@export
var battle: BattleMode

const _battle_card_resource: PackedScene = preload("res://scenes/battle_card.tscn")

var _battle_card: BattleCard

func _ready() -> void:
    if battle.on_entity_join_battle.connect(_connect_new_enemy) != OK:
        push_error("Failed to connect to entity join battle event")
    if battle.on_entity_leave_battle.connect(_remove_new_enemy) != OK:
        push_error("Failed to connect to entity join battle event")

    _battle_card = _battle_card_resource.instantiate()
    _battle_card.visible = false
    _battle_card.interactable = false
    self.add_child(_battle_card)
    _battle_card.owner = self.get_tree().root

func _connect_new_enemy(entity: BattleEntity) -> void:
    if entity is not BattleEnemy:
        return

    var enemy: BattleEnemy = entity

    if enemy.on_play_card.connect(_show_card) != OK:
        push_error("Failed to connect to %s's on play card event" % enemy.name)

func _remove_new_enemy(entity: BattleEntity) -> void:
    if entity is not BattleEnemy:
        return

    var enemy: BattleEnemy = entity

    enemy.on_play_card.disconnect(_show_card)

var _tween: Tween

func _show_card(card: BattleCardData, suit_bonus: int, pause: float) -> void:
    _battle_card.data = card
    _battle_card.sync_display(suit_bonus)
    _battle_card.position = Vector2.ZERO
    _battle_card.scale = Vector2.ZERO
    _battle_card.rotation_degrees = 0
    _battle_card.visible = true

    if _tween != null:
        _tween.kill()

    _tween = get_tree().create_tween()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(
        _battle_card,
        "scale",
        Vector2.ONE * 1.5,
        pause * 0.6).set_trans(Tween.TRANS_ELASTIC) #.set_ease(Tween.EASE_OUT_IN)

    var secondary_tween: Tween = _tween.parallel()

    secondary_tween.tween_property(
        _battle_card,
        "rotation_degrees",
        360,
        pause * 0.4).set_trans(Tween.TRANS_CUBIC)

    @warning_ignore_restore("return_value_discarded")

    if _tween.connect(
        "finished",
        func () -> void:
            await get_tree().create_timer(2).timeout
            _battle_card.visible = false
    ) != OK:

        push_error("Show card completion event not connected")

    _tween.play()
