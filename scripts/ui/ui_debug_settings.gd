extends Node

@export
var menu_base: Control

@export
var menu_button: Control

# Movement
@export
var queue_moves: CheckButton

@export
var replays: CheckButton

@export
var replays_replace: CheckButton

@export
var smooth_movement: CheckButton

@export
var concurrent_turns: CheckButton

@export
var tank_movement: CheckButton

@export
var speed: HSlider

# Camera
@export
var fov: HSlider

# Gameplay
@export
var wall_walking: CheckButton

@export
var ceiling_walking: CheckButton

@export
var jump_off: CheckButton

@export
var level: GridLevel

var inited: bool

func _on_show_setting_menu() -> void:
    menu_base.show()
    menu_button.hide()

func _on_hide_setting_menu() -> void:
    menu_base.hide()
    menu_button.show()

func _init() -> void:
    _on_hide_setting_menu.call_deferred()
    _sync.call_deferred()

func _sync() -> void:
    queue_moves.button_pressed = level.player.queue_moves
    replays.button_pressed = level.player.allow_replays
    replays_replace.button_pressed = !level.player.persist_repeat_moves
    smooth_movement.button_pressed = !level.player.instant_step
    concurrent_turns.button_pressed = level.player.concurrent_turns
    tank_movement.button_pressed = level.player.planner.tank_movement
    speed.value = level.player.planner.animation_speed

    fov.value = level.player.camera.fov

    wall_walking.button_pressed = level.player.transportation_abilities.has_flag(TransportationMode.WALL_WALKING)
    ceiling_walking.button_pressed = level.player.transportation_abilities.has_flag(TransportationMode.CEILING_WALKING)
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
    if toggled_on:
        level.player.transportation_abilities.set_flag(TransportationMode.WALL_WALKING)
    else:
        level.player.transportation_abilities.remove_flag(TransportationMode.WALL_WALKING)

func _on_ceiling_walking_toggled(toggled_on: bool) -> void:
    if toggled_on:
        level.player.transportation_abilities.set_flag(TransportationMode.CEILING_WALKING)
    else:
        level.player.transportation_abilities.remove_flag(TransportationMode.CEILING_WALKING)


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
