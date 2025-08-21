extends Control
class_name ChapUI

enum MessageAnimation { NONE, PARAGRAPH, SENTENCE, WORD, CHARACTER }

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

func _ready() -> void:
    if _next_word.compile("[^ \n]*[ \n]?") != OK:
        push_error("Next word pattern didn't compile")
    if _next_sentence.compile(".*?[.!?]+([ \n]|$)") != OK:
        push_error("Next sentence pattern didn't compile")

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
        var part: String = message.substr(start, end - start)

        var delay: float = (end - start) * letter_pause
        delay += part.count(" ") * word_pause
        if part.contains(".") || part.contains("?") || part.contains("!"):
            delay += sentence_pause

        await get_tree().create_timer(delay).timeout
        start = end

    label.visible_characters = -1

func _find_message_part_end(message: String, start: int) -> int:
    match animation:
        MessageAnimation.CHARACTER:
            return start + (2 if start < message.length() && _SPACERS.contains(message[start]) else 1)

        MessageAnimation.WORD:
            var match: RegExMatch = _next_word.search(message, start)
            if match:
                return match.get_end() + 1
            return message.length()

        MessageAnimation.SENTENCE:
            var match: RegExMatch = _next_sentence.search(message, start)
            if match:
                return match.get_end() + 1
            return message.length()

        MessageAnimation.PARAGRAPH:
            var end: int = message.find("\n", start)
            if end > start:
                return end
            return message.length()

    return message.length()

func _get_message_label() -> Label:
    var label: Label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(100, 0)
    label.add_theme_font_size_override("font_size", message_font_size)
    return label
