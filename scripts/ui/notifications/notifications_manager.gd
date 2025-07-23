extends Node
class_name NotificationsManager

signal on_update_manager(new_manager: NotificationsManager)
signal on_show_message(message: NotificationsData)
signal on_hide_message(id: String)
signal on_queue_updated(queue_size: int)

static var _manager: NotificationsManager

static var _queue: Array[NotificationsData]

enum NotificationType { INFO, IMPORTANT, WARNING }

@export_range(1, 20)
var max_concurrent_messages: int = 5

@export
var _min_time_between_messages: float = 300

@export
var _min_time_visible_message: float = 400

static func notify(message: NotificationsData) -> void:
    if message == null:
        return

    if _manager == null:
        push_warning("Notification %s may be lost because there's no active notifications system" % message)

    _queue.append(message)
    if _manager != null:
        _manager.on_queue_updated.emit(_queue.size())

static func info(title: String, message: String, duration: float = 2000) -> void:
    notify(NotificationsData.new(title, message, NotificationType.INFO, duration))

static func important(title: String, message: String, duration: float = 2000) -> void:
    notify(NotificationsData.new(title, message, NotificationType.IMPORTANT, duration))

static func warn(title: String, message: String, duration: float = 2000) -> void:
    notify(NotificationsData.new(title, message, NotificationType.WARNING, duration))

static func force_remove_message(id: String) -> bool:
    if _queue.any(func (msg: NotificationsData) -> bool: return msg.id == id):
        var idx: int = _queue.find_custom(func (msg: NotificationsData) -> bool: return msg.id == id)
        _queue.erase(_queue[idx])

        if _manager != null:
            _manager.on_queue_updated.emit(_queue.size())

        return true

    if _manager == null:
        push_warning("There's no manager, cannot remove message %s since there's no active manager and not in queue" % id)
        return false

    return _manager._force_remove_message_by_id(id)

@export
var inherit_queue: bool

class NotificationsData:
    var id: String

    var title: String
    var message: String
    var type: NotificationType

    var _show_duration: float
    var dismiss_time: float
    var show_time: float

    func temporal() -> bool:
        return _show_duration > 0

    func should_hide() -> bool:
        if !temporal():
            return false

        return Time.get_ticks_msec() >= dismiss_time

    func could_hide(min_show_duration: float) -> bool:
        if !temporal():
            return false

        return Time.get_ticks_msec() >= min(dismiss_time, show_time + min_show_duration)


    func set_shown() -> void:
        show_time = Time.get_ticks_msec()

        if temporal():
            dismiss_time = show_time + _show_duration

    func _init(p_title: String, p_message: String, p_type: NotificationType, p_duration: float = 2000) -> void:
        id = "%s-%s" % [hash(title), Time.get_ticks_usec()]
        title = p_title
        message = p_message
        type = p_type
        _show_duration = p_duration

func _ready() -> void:
    if _manager != self && !inherit_queue:
        _queue.clear()

    if _manager != self && _manager != null:
        _manager.on_update_manager.emit(self)

    _manager = self

static var _active_messages: Dictionary[String, NotificationsData] = {}

var _next_show_time: float

func _process(_delta: float) -> void:
    if !_active_messages.is_empty():
        _hide_timed_out_messages()

    _process_message_queue()

func _hide_timed_out_messages() -> void:
    for msg_id: String in _active_messages:
        if _active_messages[msg_id].should_hide():
            if !_active_messages.erase(msg_id):
                push_error("Failed to remove %s from active messages" % msg_id)
            on_hide_message.emit(msg_id)

func _force_timeout_messages(count: int) -> int:
    var removed: int = 0
    for msg_id: String in _active_messages:
        if _active_messages[msg_id].could_hide(_min_time_visible_message):
            if !_active_messages.erase(msg_id):
                push_error("Failed to remove %s from active messages" % msg_id)
            on_hide_message.emit(msg_id)
            count -= 1
            removed += 1

        if count == 0:
            break

    return removed

func _process_message_queue() -> void:
    if Time.get_ticks_msec() < _next_show_time || _queue.is_empty():
        return

    var showing: int = _active_messages.size()
    if showing < max_concurrent_messages:
        _show_next_message()

    showing -= _force_timeout_messages(_queue.size())

    if showing < max_concurrent_messages:
        _show_next_message()

func _show_next_message() -> void:
    if _queue.size() == 0:
        return

    var msg: NotificationsData = _queue.pop_front()
    if msg == null:
        return

    on_show_message.emit(msg)
    _next_show_time = Time.get_ticks_msec() + _min_time_between_messages

func _force_remove_message_by_id(id: String) -> bool:
    if _active_messages.has(id):
        var msg: NotificationsData = _active_messages[id]
        on_hide_message.emit(msg)
        return _active_messages.erase(id)

    return false
