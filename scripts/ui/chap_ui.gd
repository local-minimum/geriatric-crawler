extends Control
class_name ChapUI

enum MessageAnimation { NONE, PARAGRAPH, SENTENCE, WORD, CHARACTER }

@export_multiline var start_message: String

@export var title: Label
@export var scroll_container: ScrollContainer
@export var messages: VBoxContainer
@export var message_font_size: int = 10
@export var animation: MessageAnimation
@export_range(0, 1) var letter_pause: float = 0.05
@export_range(0, 1) var word_pause: float = 0.1
@export_range(0, 1) var sentence_pause: float = 0.3

const _SPACERS: String = " -_:/[]().,;\\/?!*&"
var _next_word: RegEx = RegEx.new()
var _next_sentence: RegEx = RegEx.new()
var _paragraph: RegEx = RegEx.new()

func _ready() -> void:
    if _next_word.compile("[^ \n]*[ \n]?") != OK:
        push_error("Next word pattern didn't compile")
    if _next_sentence.compile(".*?[.!?]+([ \n]|$)") != OK:
        push_error("Next sentence pattern didn't compile")
    if _paragraph.compile("\n*(.|\n)*?(\n\n|\\Z)") != OK:
        push_error("Next paragraph pattern didn't compile")

    await get_tree().create_timer(1).timeout
    add_message(start_message)

func add_message(message: String) -> void:
    var label: Label = _get_message_label()
    label.text = message
    if animation != MessageAnimation.NONE:
        _animate_message(label, message)
    else:
        label.visible_characters = -1
    messages.add_child(label)

func _animate_message(label: Label, message: String) -> void:
    var start: int = 0
    var end: int = _find_message_part_end(message, start)
    while end < message.length():
        end = _find_message_part_end(message, start)

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

func _scroll_to_bottom() -> void:
    scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func _find_message_part_end(message: String, start: int) -> int:
    match animation:
        MessageAnimation.CHARACTER:
            return start + (2 if start < message.length() && _SPACERS.contains(message[start]) else 1)

        MessageAnimation.WORD:
            var match: RegExMatch = _next_word.search(message, start)
            if match:
                return match.get_end()
            return message.length()

        MessageAnimation.SENTENCE:
            var match: RegExMatch = _next_sentence.search(message, start)
            if match:
                return match.get_end()
            return message.length()

        MessageAnimation.PARAGRAPH:
            var match: RegExMatch = _paragraph.search(message, start)
            if match:
                return match.get_start(2)
            return message.length()

    return message.length()

func _get_message_label() -> Label:
    var label: Label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(100, 0)
    label.add_theme_font_size_override("font_size", message_font_size)
    return label
