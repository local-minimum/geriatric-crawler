extends Control
class_name BattleEnemyUI

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

const SHOW_CHANGE_TIME: float = 0.5

func connect_enemy(enemy: BattleEnemy) -> void:
    visible = false

    if enemy.on_heal.connect(_handle_heal) != OK:
        push_error("Failed to connect %s on_heal to UI" % enemy)
    if enemy.on_hurt.connect(_handle_hurt) != OK:
        push_error("Failed to connect %s on_hurt to UI" % enemy)
    if enemy.on_death.connect(_handle_death) != OK:
        push_error("Failed to connect %s on_death to UI" % enemy)

    if enemy.on_gain_shield.connect(_handle_gain_shield) != OK:
        push_error("Failed to connect %s on_gain_shield to UI" % enemy)
    if enemy.on_break_shield.connect(_handle_break_shield) != OK:
        push_error("Failed to connect %s on_break_shield to UI" % enemy)

    _set_health(enemy.get_health())
    _set_shield(enemy.get_shields())

    icon.texture = enemy.sprite
    nameUI.text = enemy.variant_name

    await get_tree().create_timer(randf_range(2, 4)).timeout
    visible = true

func disconnect_enemy(enemy: BattleEnemy) -> void:
    enemy.on_heal.disconnect(_handle_heal)
    enemy.on_hurt.disconnect(_handle_hurt)
    enemy.on_death.disconnect(_handle_death)
    visible = false

func _handle_death(_battle_enemy: BattleEnemy) -> void:
    healthUI.text = "XXX DEAD XXX"
    await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    disconnect_enemy(_battle_enemy)

func _handle_heal(_battle_enemy: BattleEnemy, amount: int, new_health: int, _overheal: bool) -> void:
    if amount > 0:
        healthUI.text = "HEALING %s HP" % amount
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_health(new_health)

func _handle_hurt(_battle_enemy: BattleEnemy, amount: int, new_health: int) -> void:
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

func _handle_break_shield(_battle_enemy: BattleEnemy, shields: Array[int], broken_shield: int) -> void:
    if broken_shield > 0:
        defenceUI.text = "BROKEN %s⛨" % broken_shield
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_shield(shields)

func _handle_gain_shield(_battle_enemy: BattleEnemy, shields: Array[int], new_shield: int) -> void:
    if new_shield > 0:
        defenceUI.text = "SHIELDING %s⛨" % new_shield
        await get_tree().create_timer(SHOW_CHANGE_TIME).timeout

    _set_shield(shields)

func _set_shield(shields: Array[int]) -> void:
    if shields.is_empty():
        defenceUI.text = "DEF: EXPOSED"
        return

    var shields_text: Array[String] = shields.map(
        func (shield: int) -> String:
            return "%s⛨" % shield)
    defenceUI.text = "DEF: %s" % " | ".join(shields_text)
