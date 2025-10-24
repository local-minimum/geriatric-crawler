extends UIDebugSettingsCore

# Gameplay
@export var wall_walking: CheckButton
@export var ceiling_walking: CheckButton

func _on_wall_walking_toggled(toggled_on: bool) -> void:
    if level.player is GridPlayer:
        (level.player as GridPlayer).override_wall_walking = toggled_on

func _on_ceiling_walking_toggled(toggled_on: bool) -> void:
    if toggled_on:
        wall_walking.button_pressed = true
    if level.player is GridPlayer:
        (level.player as GridPlayer).override_ceiling_walking = toggled_on
