extends Control
class_name NotificationUI

@export
var _background: Control

@export
var _info_color: Color

@export
var _important_color: Color

@export
var _warning_color: Color

@export
var title: RichTextLabel

@export
var body: RichTextLabel

@export
var close_button: Button

var message_id: String

func _get_color(type: NotificationsManager.NotificationType) -> Color:
    match type:
        NotificationsManager.NotificationType.INFO: return _info_color
        NotificationsManager.NotificationType.IMPORTANT: return _warning_color
        NotificationsManager.NotificationType.WARNING: return _important_color
        _: return _info_color

func show_message(
    msg: NotificationsManager.NotificationData,
    from_x_offset: float,
    tween_duration: float,
) -> void:
    message_id = msg.id
    _format_notifictaion(msg)
    _tween_in_message(from_x_offset, tween_duration)

func _format_notifictaion(
    msg: NotificationsManager.NotificationData,
) -> void:
    _update_background(msg.type)

    title.text = msg.title
    title.visible = !msg.title.is_empty()

    body.text = msg.message
    body.visible = !msg.title.is_empty()

    close_button.visible = !msg.temporal()

func _update_background(type: NotificationsManager.NotificationType) -> void:
    var color: Color = _get_color(type)
    if _background is ColorRect:
        var c_rect: ColorRect = _background
        c_rect.color = color
    elif _background is TextureRect:
        var t_rect: TextureRect = _background
        t_rect.self_modulate = color

var _tween: Tween
func _tween_in_message(from_x_offset: float, duration: float) -> void:
    var scale_fade_time: float = duration * 0.5
    _tween = create_tween()
    scale = Vector2.RIGHT
    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(self, "scale", Vector2.ONE, scale_fade_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _tween.parallel().tween_property(self, "modulate:a", 1.0, scale_fade_time)

    var original_pos: Vector2 = position
    position.x += from_x_offset
    _tween.parallel().tween_property(self, "position:x", original_pos.x, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    @warning_ignore_restore("return_value_discarded")


func hide_message(to_x_offset: float, tween_duration: float) -> void:
    if _tween:
        _tween.kill()

    _tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(self, "modulate:a", 0, tween_duration)

    var target_pos: Vector2 = position
    target_pos.x += to_x_offset
    _tween.parallel().tween_property(self, "position:x", target_pos.x, tween_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    _tween.tween_callback(queue_free)
    @warning_ignore_restore("return_value_discarded")
