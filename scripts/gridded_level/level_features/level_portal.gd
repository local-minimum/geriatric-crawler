extends GridEvent
class_name LevelPortal

@export var id: String
@export var exit_level_target: String
@export var entry_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN
@export var entry_lookdirection: CardinalDirections.CardinalDirection
@export var allow_exit: bool
@export var fail_exit_notice_title: String = "NOTICE_AIRLOCK"
@export var fail_exit_notice_message: String = "AIRLOCK_FAIL_TO_CYCLE"

func exit_level() -> void:
    _triggered = true

    var level: GridLevel = get_level()
    level.player.cinematic = true
    level.activated_exit_portal = self

    var setup: bool = true
    if __SignalBus.on_save_complete.connect(_handle_saved) != OK:
        push_warning("Will not be able to swap scenes after save")
        setup = false

    if __SignalBus.on_load_fail.connect(_handle_saved) != OK:
        push_warning("Failed to connect fail load")
        setup = false

    __SaveSystemWrapper.autosave()

    if !setup:
        _fail_exit_level()

func _handle_saved() -> void:
    __SignalBus.on_save_complete.disconnect(_handle_saved)

    if !(__SceneSwapper as SceneSwapper).transition_to_next_scene():
        _fail_exit_level()
        return

    if __SignalBus.on_load_fail.is_connected(_fail_exit_level):
        __SignalBus.on_load_fail.disconnect(_fail_exit_level)

func _fail_exit_level() -> void:
    var level: GridLevel = get_level()
    NotificationsManager.warn(tr(fail_exit_notice_title), tr(fail_exit_notice_message))

    if level.activated_exit_portal == self:
        level.activated_exit_portal = null

    level.player.cinematic = false

    if __SignalBus.on_load_fail.is_connected(_fail_exit_level):
        __SignalBus.on_load_fail.disconnect(_fail_exit_level)

    if __SignalBus.on_save_complete.is_connected(_handle_saved):
        __SignalBus.on_save_complete.disconnect(_handle_saved)
