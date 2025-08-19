extends CanvasLayer
class_name TutorialUI

@export var outliner: TargetOutliner
@export var peephole: PeepHole
@export var box: PanelContainer
@export var box_label: Label
@export var next_btn: Button
@export var prev_btn: Button
@export var tween_time: float = 0.8

func _ready() -> void:
    _hide_parts()
    if outliner.on_redrawn.connect(_handle_outliner_redrawn) != OK:
        push_error("Failed to connect outliner redrawn")

func _input(event: InputEvent) -> void:
    if event.is_echo() || !box.visible:
        return

    if event.is_action_pressed("crawl_strafe_left"):
        if !prev_btn.disabled:
            _on_prev_button_pressed()

    elif event.is_action_pressed("crawl_strafe_right"):
        if !next_btn.disabled:
            _on_next_button_pressed()

var _tutorial_id: int = 0

var _on_next: Variant
var _on_prev: Variant
var _prev_text: String
var _current_text: String
var _box_start_position: Vector2

func reset_tutorial() -> void:
    _hide_parts()
    outliner.reset_outlining()
    box.global_position = box.get_viewport_rect().get_center() - box.get_global_rect().size / 2
    box_label.text = ""
    _prev_text = ""
    _current_text = ""

func show_tutorial(message: String, on_previous: Variant, on_next: Variant, targets: Array[Control], autohide_time: float = -1) -> void:
    _prev_text = _current_text
    _current_text = message
    _box_start_position = box.global_position

    if tween_time > 0:
        outliner.tween_to(targets, tween_time)
    else:
        outliner.snap_to(targets)
        box_label.text = message

    _on_next = on_next
    _on_prev = on_previous


    var id : int = _tutorial_id

    box.show()
    peephole.show()
    outliner.show()

    if tween_time > 0:
        next_btn.disabled = true
        prev_btn.disabled = true
        await get_tree().create_timer(tween_time).timeout

    next_btn.disabled = on_next is not Callable
    prev_btn.disabled = on_previous is not Callable

    if autohide_time > 0:
        await get_tree().create_timer(autohide_time).timeout
        if _tutorial_id == id && on_next is Callable:
            _hide_parts()
            @warning_ignore_start("unsafe_cast")
            (on_next as Callable).call()
            @warning_ignore_restore("unsafe_cast")


    print_debug("Tutorial: %s" % message)

func _hide_parts() -> void:
    box.hide()
    peephole.hide()
    outliner.hide()

func _on_next_button_pressed() -> void:
    _tutorial_id += 1
    _hide_parts()
    if _on_next is Callable:
        @warning_ignore_start("unsafe_cast")
        (_on_next as Callable).call()
        @warning_ignore_restore("unsafe_cast")

func _on_prev_button_pressed() -> void:
    _tutorial_id += 1
    _hide_parts()
    if _on_prev is Callable:
        @warning_ignore_start("unsafe_cast")
        (_on_prev as Callable).call()
        @warning_ignore_restore("unsafe_cast")

func _handle_outliner_redrawn(tween_progress: float) -> void:
    if tween_progress == 1:
        box_label.text = _current_text
        if outliner.tweening:
            box.size = Vector2.ZERO
            _position_box.call_deferred(tween_progress)
        return

    var l_prev: float = _prev_text.length()
    var l_cur: float = _current_text.length()

    var length_cur_part: int = roundi(lerpf(0, l_cur, tween_progress))
    var length_prev_part: int = roundi(lerpf(maxf(l_prev, l_cur), l_cur, tween_progress)) - length_cur_part
    box_label.text = _current_text.substr(0, length_cur_part) + _prev_text.substr(length_cur_part, length_prev_part)
    box.size = Vector2.ZERO
    _position_box.call_deferred(tween_progress)

const _PLACE_OUTSIDE_THRESHOLD: float = 0.5
const _OFFSET_SCALE: float = 0.75
const _MARGIN: float = 10

func _position_box(tween_progress: float) -> void:
    var outline_target: Rect2 = outliner.final_targets_global_rect
    var viewport: Rect2 = box.get_viewport_rect()
    var box_rect: Rect2 = box.get_global_rect()

    var target_to_viewport_scale: Vector2 = outline_target.size / viewport.size

    if target_to_viewport_scale.x < _PLACE_OUTSIDE_THRESHOLD || target_to_viewport_scale.y < _PLACE_OUTSIDE_THRESHOLD:
        var direction: Vector2 = (viewport.get_center() - outline_target.get_center()) / viewport.size
        direction = direction.normalized()
        if direction == Vector2.ZERO:
            direction = Vector2.DOWN

        if target_to_viewport_scale.x >= _PLACE_OUTSIDE_THRESHOLD && direction.y == 0:
            direction = Vector2.DOWN
        elif target_to_viewport_scale.y >= _PLACE_OUTSIDE_THRESHOLD && direction.x == 0:
            direction = Vector2.LEFT

        var target_pos: Vector2 = ((box_rect.size + outline_target.size) * _OFFSET_SCALE) * direction + outline_target.get_center() - box_rect.size /2
        if target_pos.x < viewport.position.x + _MARGIN:
            target_pos.x = viewport.position.x + _MARGIN
        elif target_pos.x + box_rect.size.x > viewport.end.x - _MARGIN:
            target_pos.x = viewport.position.x - _MARGIN - box_rect.size.x

        if target_pos.y < viewport.position.y + _MARGIN:
            target_pos.y = viewport.position.y + _MARGIN
        elif target_pos.y + box_rect.size.y > viewport.end.y + _MARGIN:
            target_pos.y = viewport.end.y - _MARGIN - box_rect.size.y

        box.global_position = _box_start_position.lerp(target_pos, tween_progress)
    else:
        box.global_position = _box_start_position.lerp(outline_target.get_center() - box_rect.size / 2, tween_progress)
