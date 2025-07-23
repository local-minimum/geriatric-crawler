extends Control
class_name NotificationsPanelUI

@export_range(0, 2)
var _tween_notifiction_duration: float = 0.3

@export_range(0, 2)
var _tween_offset_width_factor: float = 1.2

var _notification: PackedScene = preload("res://scenes/ui/notification.tscn")

func _ready() -> void:
    if NotificationsManager.active_manager == null:
        NotificationsManager.await_manager(_handle_update_manager)
    else:
        _handle_update_manager(null, NotificationsManager.active_manager)

func _handle_update_manager(old_manager: NotificationsManager, new_manager: NotificationsManager) -> void:
    if old_manager != null:
        old_manager.on_update_manager.disconnect(_handle_update_manager)
        old_manager.on_queue_updated.disconnect(_handle_update_queue)
        old_manager.on_show_message.disconnect(_show_message)
        old_manager.on_hide_message.disconnect(_hide_message)
        print_debug("Disconnected from %s" % old_manager)

    if new_manager.on_update_manager.connect(_handle_update_manager) != OK:
        push_warning("Failed to connect on update manager")

    if new_manager.on_queue_updated.connect(_handle_update_queue) != OK:
        push_warning("Failed to connect on queue updated")

    if new_manager.on_show_message.connect(_show_message) != OK:
        push_warning("Failed to connect on show message")

    if new_manager.on_hide_message.connect(_hide_message) != OK:
        push_warning("Failed to connect on hide message")

    print_debug("Connected to %s" % old_manager)


var _active_notifications: Array[NotificationUI] = []

func _handle_update_queue(queue_size: int) -> void:
    if queue_size > 0:
        print_debug("%s messages waiting" % queue_size)

func _get_tween_offset() -> float:
    # TODO: Offset side direction should be based on settings
    return -1 * _tween_offset_width_factor * get_rect().size.x

func _show_message(mgs: NotificationsManager.NotificationData) -> void:
    var to_show: NotificationUI = _notification.instantiate()

    add_child(to_show)

    to_show.show_message.call_deferred(mgs, _get_tween_offset(), _tween_notifiction_duration)
    _active_notifications.append(to_show)

func _hide_message(id: String) -> void:
    var notification_idx: int = _active_notifications.find_custom(func (noti: NotificationUI) -> bool: return noti.message_id == id)
    if notification_idx == -1:
        return

    var to_hide: NotificationUI = _active_notifications[notification_idx]
    if to_hide == null:
        return

    to_hide.hide_message(
        _get_tween_offset(),
        _tween_notifiction_duration,
    )

    _active_notifications.erase(to_hide)
