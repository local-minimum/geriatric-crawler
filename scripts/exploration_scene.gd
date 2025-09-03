extends Node
class_name ExplorationScene

static var instance: ExplorationScene

@export var settings: GameSettings

@export var subviewport: Control
@export var exploration_ui: Control

var _view_split: float

var level: GridLevel
var level_ready: bool:
    get():
        return level != null

func _enter_tree() -> void:
    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null

func _ready() -> void:
    _view_split = subviewport.anchor_right

    if settings.accessibility.on_update_handedness.connect(_handle_handedness_change) != OK:
        push_error("Failed to connect on update handedness")

    _handle_handedness_change(AccessibilitySettings.handedness)

static func find_exploration_scene(current: Node, inclusive: bool = true) ->  ExplorationScene:
    if inclusive && current is ExplorationScene:
        return current as ExplorationScene

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is ExplorationScene:
        return parent as ExplorationScene

    return find_exploration_scene(parent, false)

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
