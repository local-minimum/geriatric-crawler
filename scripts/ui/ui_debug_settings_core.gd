extends Node
class_name UIDebugSettingsCore

@export var menu_base: Control
@export var menu_button: Control

@export_category("Movement")
@export var queue_moves: CheckButton
@export var replays: CheckButton
@export var replays_replace: CheckButton
@export var smooth_movement: CheckButton
@export var concurrent_turns: CheckButton
@export var tank_movement: CheckButton
@export var speed: HSlider

@export_category("Camera")
@export var fov: HSlider
@export var handedness: CheckButton

# Gameplay
@export_category("Gameplay")
@export var jump_off: CheckButton
@export var settings: GameSettings

var inited: bool

func _on_show_setting_menu() -> void:
    menu_base.show()
    menu_button.hide()

func _on_hide_setting_menu() -> void:
    menu_base.hide()
    menu_button.show()

var level: GridLevelCore
func _ready() -> void:
    _on_hide_setting_menu.call_deferred()

    level = GridLevelCore.active_level
    if __SignalBus.on_level_loaded.connect(_handle_new_level) != OK:
        push_error("Failed to connect level loaded")

    _sync.call_deferred()

func _handle_new_level(new: GridLevelCore) -> void:
    level = new
    _sync()

func _sync() -> void:
    if level == null:
        return
    queue_moves.button_pressed = level.player.queue_moves
    replays.button_pressed = level.player.allow_replays
    replays_replace.button_pressed = !level.player.persist_repeat_moves
    smooth_movement.button_pressed = !level.player.instant_step
    concurrent_turns.button_pressed = level.player.concurrent_turns
    tank_movement.button_pressed = level.player.planner.tank_movement
    speed.value = level.player.planner.animation_speed

    fov.value = level.player.camera.fov
    handedness.button_pressed = AccessibilitySettings.handedness == AccessibilitySettings.Handedness.RIGHT

    jump_off.button_pressed = level.player.can_jump_off_walls

    inited = true

func _on_buffer_toggled(toggled_on: bool) -> void:
    level.player.queue_moves = toggled_on


func _on_hold_replays_toggled(toggled_on: bool) -> void:
    level.player.allow_replays = toggled_on


func _on_new_hold_replaces_toggled(toggled_on: bool) -> void:
    level.player.persist_repeat_moves = !toggled_on


func _on_smooth_movement_toggled(toggled_on: bool) -> void:
    level.player.instant_step = !toggled_on

func _on_concurrent_turning_toggled(toggled_on: bool) -> void:
    level.player.concurrent_turns = toggled_on


func _on_tank_animations_toggled(toggled_on: bool) -> void:
    level.player.planner.tank_movement = toggled_on


func _on_jump_off_walls_toggled(toggled_on: bool) -> void:
    level.player.can_jump_off_walls = toggled_on


func _on_speed_slider_value_changed(value: float) -> void:
    if !inited:
        return
    level.player.planner.animation_speed = value

func _on_fov_slider_value_changed(value: float) -> void:
    if !inited:
        return

    level.player.camera.fov = value

func _on_save_button_pressed() -> void:
    __SaveSystemWrapper.autosave()


func _on_load_button_pressed() -> void:
    __SaveSystemWrapper.load_last_save()

func _on_handedness_toggled(toggled_on:bool) -> void:
    settings.accessibility.set_handedness(AccessibilitySettings.Handedness.RIGHT if toggled_on else AccessibilitySettings.Handedness.LEFT)

func _on_reset_tutorials_pressed() -> void:
    settings.tutorial.reset_all_tutorials()
    NotificationsManager.info(__GlobalGameState.tr("NOTICE_SETTINGS"), __GlobalGameState.tr("TUTORIALS_RESET"))
