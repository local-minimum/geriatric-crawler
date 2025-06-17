extends Control
class_name BattleEnemiesUI

@export
var _enemyUIs: Array[BattleEnemyUI] = []

@export
var _battle: BattleMode

var _connected_enemies: Dictionary[BattleEnemy, BattleEnemyUI] = {}
var _inverse_connected_enemies: Dictionary[BattleEnemyUI, BattleEnemy] = {}


func _ready() -> void:
    if _battle.on_enemy_join_battle.connect(_handle_join_enemy) != OK:
        push_error("Failed to connect enemy joins battle event")
    if _battle.on_enemy_leave_battle.connect(_handle_enemy_leave) != OK:
        push_error("Failed to connect enemy leaves battle event")

func _get_unused_ui() -> BattleEnemyUI:
    for ui: BattleEnemyUI in _enemyUIs:
        if !_inverse_connected_enemies.has(ui):
            return ui

    return null

func _handle_join_enemy(enemy: BattleEnemy) -> void:
    # TODO: Fancy entry into battle, some delays

    if _connected_enemies.has(enemy):
        push_error("%s already in battle" % enemy)
        return

    var ui: BattleEnemyUI = _get_unused_ui()
    if ui == null:
        push_error("We only have space for %s enemies in battle, and all spots are used" % _enemyUIs.size)
        return

    ui.connect_enemy(enemy)
    _connected_enemies[enemy] = ui
    _inverse_connected_enemies[ui] = enemy

func _handle_enemy_leave(enemy: BattleEnemy) -> void:
    # TODO: Fancy exit from battle??
    if _connected_enemies.has(enemy):
        var ui: BattleEnemyUI = _connected_enemies[enemy]
        ui.disconnect_enemy(enemy)

        @warning_ignore_start("return_value_discarded")
        _connected_enemies.erase(enemy)
        _inverse_connected_enemies.erase(ui)
        @warning_ignore_restore("return_value_discarded")
