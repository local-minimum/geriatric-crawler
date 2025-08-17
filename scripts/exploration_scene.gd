extends Node
class_name ExplorationScene

@export var accessibility: AccessibilitySettings

@export var subviewport: Control
@export var exploration_ui: Control

var _view_split: float

func _ready() -> void:
    _view_split = subviewport.anchor_right

    if accessibility.on_update_handedness.connect(_handle_handedness_change) != OK:
        push_error("Failed to connect on update handedness")

    _handle_handedness_change(AccessibilitySettings.handedness)


func _handle_handedness_change(handedness: AccessibilitySettings.Handedness) -> void:
    match handedness:
        AccessibilitySettings.Handedness.LEFT:
            subviewport.anchor_left = 1 - _view_split
            subviewport.anchor_right = 1
            exploration_ui.anchor_left = 0
            exploration_ui.anchor_right = 1 - _view_split
        AccessibilitySettings.Handedness.RIGHT:
            subviewport.anchor_left = 0
            subviewport.anchor_right = _view_split
            exploration_ui.anchor_left = _view_split
            exploration_ui.anchor_right = 1
