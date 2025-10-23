extends Control
class_name BattleEntitiesUIGroup

@export
var _entityUIs: Array[BattleEntityUI] = []

@export
var _enemy_group: bool

@export
var _delay_show_enemy: float = 3

@export
var _delay_hide_enemy: float = 1

var _connected_entities: Dictionary[BattleEntity, BattleEntityUI] = {}
var _inverse_connected_entities: Dictionary[BattleEntityUI, BattleEntity] = {}


func _ready() -> void:
    if __SignalBus.on_entity_join_battle.connect(_handle_join_entity) != OK:
        push_error("Failed to connect enemy joins battle event")
    if __SignalBus.on_entity_leave_battle.connect(_handle_entity_leave) != OK:
        push_error("Failed to connect enemy leaves battle event")
    if __SignalBus.on_battle_start.connect(_handle_battle_start) != OK:
        push_error("Failed to conntect battle start")

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
        push_error("%s already in battle group" % entity)
        return

    var ui: BattleEntityUI = _get_unused_ui()
    if ui == null:
        push_error("We only have space for %s enemies in battle, and all spots are used" % _entityUIs.size)
        return

    ui.connect_entity(entity)

    _connected_entities[entity] = ui
    _inverse_connected_entities[ui] = entity

    await get_tree().create_timer(_delay_show_enemy).timeout
    ui.visible = true

func _handle_entity_leave(entity: BattleEntity, battle_end: bool) -> void:
    # TODO: Fancy exit from battle at least when with timer

    print_debug("[Battle Group UI %s] %s leaves battle is mine=%s (%s)" % [
        name,
        entity.name,
        _connected_entities.has(entity),
        _connected_entities.keys().map(func (e: BattleEntity) -> String: return e.name),
    ])

    if _connected_entities.has(entity):
        var ui: BattleEntityUI = _connected_entities[entity]
        if !battle_end:
            await get_tree().create_timer(_delay_hide_enemy).timeout

        ui.disconnect_entity(entity)

        @warning_ignore_start("return_value_discarded")
        _connected_entities.erase(entity)
        _inverse_connected_entities.erase(ui)
        @warning_ignore_restore("return_value_discarded")

        ui.visible = false
