extends Node

@export var exploration_view: ExplorationView

@export var menu_base: Control

@export var menu_button: Control

# Movement
@export var queue_moves: CheckButton

@export var replays: CheckButton

@export var replays_replace: CheckButton

@export var smooth_movement: CheckButton

@export var concurrent_turns: CheckButton

@export var tank_movement: CheckButton

@export var speed: HSlider

# Camera
@export var fov: HSlider

@export var handedness: CheckButton

# Gameplay
@export var wall_walking: CheckButton

@export var ceiling_walking: CheckButton

@export var jump_off: CheckButton

@export var save_system: SaveSystem

@export var accessibility: AccessibilitySettings

var inited: bool

func _on_show_setting_menu() -> void:
    menu_base.show()
    menu_button.hide()

func _on_hide_setting_menu() -> void:
    menu_base.hide()
    menu_button.show()

var level: GridLevel
func _ready() -> void:
    _on_hide_setting_menu.call_deferred()

    level = GridLevel.active_level
    if exploration_view.on_change_level.connect(_handle_new_level) != OK:
        push_error("Failed to connect level switching")

    _sync.call_deferred()

func _handle_new_level(_old: GridLevel, new: GridLevel) -> void:
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


func _on_wall_walking_toggled(toggled_on: bool) -> void:
    level.player.override_wall_walking = toggled_on

func _on_ceiling_walking_toggled(toggled_on: bool) -> void:
    if toggled_on:
        wall_walking.button_pressed = true
    level.player.override_ceiling_walking = toggled_on


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
    save_system.save_last_slot()


func _on_load_button_pressed() -> void:
    if !save_system.load_last_save():
        pass

func _on_handedness_toggled(toggled_on:bool) -> void:
    accessibility.set_handedness(AccessibilitySettings.Handedness.RIGHT if toggled_on else AccessibilitySettings.Handedness.LEFT)
