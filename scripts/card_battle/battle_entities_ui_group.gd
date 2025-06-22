extends Control
class_name BattleEntitiesUIGroup

@export
var _entityUIs: Array[BattleEntityUI] = []

@export
var _battle: BattleMode

@export
var _enemy_group: bool

var _connected_entities: Dictionary[BattleEntity, BattleEntityUI] = {}
var _inverse_connected_entities: Dictionary[BattleEntityUI, BattleEntity] = {}


func _ready() -> void:
    if _battle.on_entity_join_battle.connect(_handle_join_entity) != OK:
        push_error("Failed to connect enemy joins battle event")
    if _battle.on_entity_leave_battle.connect(_handle_entity_leave) != OK:
        push_error("Failed to connect enemy leaves battle event")

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
    _connected_entities[entity] = ui
    _inverse_connected_entities[ui] = entity

func _handle_entity_leave(entity: BattleEntity) -> void:
    # TODO: Fancy exit from battle??
    if _connected_entities.has(entity):
        var ui: BattleEntityUI = _connected_entities[entity]
        ui.disconnect_entity(entity)

        @warning_ignore_start("return_value_discarded")
        _connected_entities.erase(entity)
        _inverse_connected_entities.erase(ui)
        @warning_ignore_restore("return_value_discarded")
