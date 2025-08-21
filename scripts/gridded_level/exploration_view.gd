extends Node
class_name ExplorationView

static var instance: ExplorationView

signal on_change_level(old: GridLevel, new: GridLevel)

var level: GridLevel:
    set(new):
        var old: GridLevel = level
        level = new
        on_change_level.emit(old, new)

func _ready() -> void:
    if level == null:
        if GridLevel.active_level != null:
            level = GridLevel.active_level
        else:
            for lvl: GridLevel in find_children("", "GridLevel"):
                level = lvl
                break
    elif  level != GridLevel.active_level:
        level = GridLevel.active_level

func _enter_tree() -> void:
    if instance != null && instance != self:
        instance.queue_free()

    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null
