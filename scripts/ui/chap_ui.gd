extends Control
class_name ChapUI

@export var _story_main: Resource
@export var _ink_adapter: InkAdapter

@export var title: Label
@export var scroll_container: ScrollContainer
@export var messages: VBoxContainer
@export var message_font_size: int = 10
@export var animation: TextUtils.Segment
@export_range(0, 1) var letter_pause: float = 0.05
@export_range(0, 1) var word_pause: float = 0.1
@export_range(0, 1) var sentence_pause: float = 0.3

var _animating: bool
var _queue: Array[String]

func _ready() -> void:
    TextUtils.init()

    if _ink_adapter.on_display_text.connect(_display_story) != OK:
        push_error("Failed to connect display story")

    await get_tree().create_timer(1).timeout
    _ink_adapter.load_story(_story_main, true, { "knows_chap": true })

func _display_story(text: String, _tags: Array) -> void:
    add_message(text)

func add_message(message: String) -> void:
    if _animating || _queue.size() > 0:
        _queue.append(message)
        return

    _add_message(message)

func _add_message(message: String) -> void:
    var label: Label = _get_message_label()
    label.text = message
    if animation != TextUtils.Segment.NONE:
        _animate_message(label, message)
    else:
        label.visible_characters = -1
        _animating = false
    messages.add_child(label)

func _animate_message(label: Label, message: String) -> void:
    _animating = true

    var start: int = 0
    var end: int = TextUtils.find_message_segment_end(message, start, animation)
    while end < message.length():
        end = TextUtils.find_message_segment_end(message, start, animation)

        label.visible_characters = end
        if get_tree().create_timer(0.1).connect("timeout", _scroll_to_bottom) != OK:
            pass

        var part: String = message.substr(start, end - start)

        var delay: float = (end - start) * letter_pause
        delay += part.count(" ") * word_pause
        if part.contains(".") || part.contains("?") || part.contains("!"):
            delay += sentence_pause

        if end < message.length():
            await get_tree().create_timer(delay).timeout
        start = end

    label.visible_characters = -1

    if _queue.size() > 0:
        var next_message: String = _queue.pop_front()
        _add_message.call_deferred(next_message)
    else:
        _animating = false

func _scroll_to_bottom() -> void:
    scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func _get_message_label() -> Label:
    var label: Label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(100, 0)
    label.add_theme_font_size_override("font_size", message_font_size)
    return label
