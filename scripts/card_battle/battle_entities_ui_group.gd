extends Control
class_name BattleEntitiesUIGroup

@export
var _entityUIs: Array[BattleEntityUI] = []

@export
var _battle: BattleMode

@export
var _enemy_group: bool

@export
var _delay_show_enemy: float = 3

@export
var _delay_hide_enemy: float = 1

var _connected_entities: Dictionary[BattleEntity, BattleEntityUI] = {}
var _inverse_connected_entities: Dictionary[BattleEntityUI, BattleEntity] = {}


func _ready() -> void:
    if _battle.on_entity_join_battle.connect(_handle_join_entity) != OK:
        push_error("Failed to connect enemy joins battle event")
    if _battle.on_entity_leave_battle.connect(_handle_entity_leave) != OK:
        push_error("Failed to connect enemy leaves battle event")
    if _battle.on_battle_start.connect(_handle_battle_start) != OK:
        push_error("Failed to conntect battle start")
    if _battle.on_battle_end.connect(_handle_battle_end) != OK:
        push_error("Failed to conntect battle end")

func _handle_battle_start() -> void:
    for ui: BattleEntityUI in _entityUIs:
        ui.visible = false

func _get_unused_ui() -> BattleEntityUI:
    for ui: BattleEntityUI in _entityUIs:
        if !_inverse_connected_entities.has(ui):
            return ui

    return null

func _handle_join_entity(entity: BattleEntity) -> void:
    if _enemy_group && entity is not BattleEnemy || !_enemy_group && entity is BattleEnemy:
        return

    # TODO: Fancy entry into battle, some delays

    if _connected_entities.has(entity):
        push_error("%s already in battle" % entity)
        return

    var ui: BattleEntityUI = _get_unused_ui()
    if ui == null:
        push_error("We only have space for %s enemies in battle, and all spots are used" % _entityUIs.size)
        return

    ui.connect_entity(entity)
    ui.connect_player_selection(_battle.battle_player)

    _connected_entities[entity] = ui
    _inverse_connected_entities[ui] = entity

    await get_tree().create_timer(_delay_show_enemy).timeout
    ui.visible = true

func _handle_entity_leave(entity: BattleEntity, with_timer: bool = true) -> void:
    # TODO: Fancy exit from battle??
    if _connected_entities.has(entity):
        var ui: BattleEntityUI = _connected_entities[entity]
        if with_timer:
            await get_tree().create_timer(_delay_hide_enemy).timeout

        ui.disconnect_entity(entity)
        ui.disconnect_player_selection(_battle.battle_player)

        @warning_ignore_start("return_value_discarded")
        _connected_entities.erase(entity)
        _inverse_connected_entities.erase(ui)
        @warning_ignore_restore("return_value_discarded")

        ui.visible = false

func _handle_battle_end() -> void:
    for entity: BattleEntity in _connected_entities.keys():
        _handle_entity_leave(entity, false)
