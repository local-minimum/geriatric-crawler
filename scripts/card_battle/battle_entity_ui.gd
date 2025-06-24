extends Control
class_name BattleEntityUI

@export
var healthUI: Label

@export
var defenceUI: Label

@export
var icon: TextureRect

@export
var nameUI: Label

func _ready() -> void:
    visible = false

var interactable: bool:
    set(value):
        interactable = value
        mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND if value else CursorShape.CURSOR_ARROW
        icon.mouse_default_cursor_shape = mouse_default_cursor_shape
        nameUI.mouse_default_cursor_shape = mouse_default_cursor_shape
        healthUI.mouse_default_cursor_shape = mouse_default_cursor_shape
        defenceUI.mouse_default_cursor_shape = mouse_default_cursor_shape

var selected: bool:
    set(value):
        selected = value

const SHOW_CHANGE_TIME: float = 0.5

var _is_monster: bool
var _is_player_ally: bool
var _entity: BattleEntity

func connect_entity(entity: BattleEntity) -> void:
    visible = false

    _entity = entity
    _is_monster = entity is BattleEnemy
    _is_player_ally = entity is BattlePlayer

    if entity.on_heal.connect(_handle_heal) != OK:
        push_error("Failed to connect %s on_heal to UI" % entity)
    if entity.on_hurt.connect(_handle_hurt) != OK:
        push_error("Failed to connect %s on_hurt to UI" % entity)
    if entity.on_death.connect(_handle_death) != OK:
        push_error("Failed to connect %s on_death to UI" % entity)

    if entity.on_gain_shield.connect(_handle_gain_shield) != OK:
        push_error("Failed to connect %s on_gain_shield to UI" % entity)
    if entity.on_break_shield.connect(_handle_break_shield) != OK:
        push_error("Failed to connect %s on_break_shield to UI" % entity)

    if entity.on_start_turn.connect(_handle_start_turn) != OK:
        push_error("Failed to connect %s on_start_turn to UI" % entity)
    if entity.on_end_turn.connect(_handle_end_turn) != OK:
        push_error("Failed to connect %s on_turn_done to UI" % entity)

    _set_health(entity.get_health())
    _set_shield(entity.get_shields())

    if icon != null:
        icon.texture = entity.sprite
    if nameUI != null:
        nameUI.text = entity.get_entity_name()

    await get_tree().create_timer(randf_range(2, 4)).timeout
    visible = true

func disconnect_entity(entity: BattleEntity) -> void:
    entity.on_heal.disconnect(_handle_heal)
    entity.on_hurt.disconnect(_handle_hurt)
    entity.on_death.disconnect(_handle_death)
    visible = false
    _entity = null
    selected = false
    interactable = false

func connect_player_selection(player: BattlePlayer) -> void:
    if player.on_player_select_targets.connect(_handle_entity_selection_start) != OK:
        push_error("Failed to connect %s's on_player_select_targets" % player)
    if player.on_player_select_targets_complete.connect(_handle_entity_selection_end) != OK:
        push_error("Failed to connect %s's on_player_select_targets" % player)

func disconnect_player_selection(player: BattlePlayer) -> void:
    player.on_player_select_targets.disconnect(_handle_entity_selection_start)
    player.on_player_select_targets_complete.disconnect(_handle_entity_selection_end)

var _selection_player: BattlePlayer = null

func _handle_entity_selection_start(player: BattlePlayer, _count: int, player_allies: bool, monsters: bool) -> void:
    _selection_player = player
    if _is_monster:
        interactable = monsters
    elif _is_player_ally:
        interactable = player_allies

func _handle_entity_selection_end() -> void:
    interactable = false
    selected = false

func _handle_start_turn(entity: BattleEntity) -> void:
    if nameUI != null:
        nameUI.text = "-> %s <-" % entity.get_entity_name()

func _handle_end_turn(entity: BattleEntity) -> void:
    if nameUI != null:
        nameUI.text = entity.get_entity_name()

func _handle_death(_battle_entity: BattleEntity) -> void:
    healthUI.text = "XXX DEAD XXX"
    await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    disconnect_entity(_battle_entity)

func _handle_heal(_battle_entity: BattleEntity, amount: int, new_health: int, _overheal: bool) -> void:
    if amount > 0:
        healthUI.text = "HEALING %s HP" % amount
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_health(new_health)

func _handle_hurt(_battle_entity: BattleEntity, amount: int, new_health: int) -> void:
    if amount > 0:
        healthUI.text = "HURT %s HP" % amount
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_health(new_health)

func _set_health(health: int) -> void:
    @warning_ignore_start("integer_division")
    var fivers: int = health / 5
    @warning_ignore_restore("integer_division")
    var remain: int = health % 5
    healthUI.text = "HP: %s%s" % ["♥".repeat(fivers), "♡".repeat(remain)]

func _handle_break_shield(_battle_entity: BattleEntity, shields: Array[int], broken_shield: int) -> void:
    if broken_shield > 0:
        defenceUI.text = "BROKEN %s⛨" % broken_shield
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_shield(shields)

func _handle_gain_shield(_battle_entity: BattleEntity, shields: Array[int], new_shield: int) -> void:
    if new_shield > 0:
        defenceUI.text = "SHIELDING %s⛨" % new_shield
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_shield(shields)

func _set_shield(shields: Array[int]) -> void:
    if shields.is_empty():
        defenceUI.text = "DEF: EXPOSED"
        return

    var shields_text: Array  = shields.map(
        func (shield: int) -> String:
            return "%s⛨" % shield)
    defenceUI.text = "DEF: %s" % " | ".join(shields_text)

func _input(event: InputEvent) -> void:
    if !interactable:
        return

    if event is InputEventMouseButton:
        var btn_event: InputEventMouseButton = event
        if btn_event.button_index == 1:
            if _hovered && btn_event.pressed && !btn_event.is_echo():
                if _selection_player != null:
                    if !selected:
                        selected = _selection_player.add_target(_entity)

var _hovered: bool

func _on_mouse_exited() -> void:
    _hovered = false

func _on_mouse_entered() -> void:
    _hovered = true
