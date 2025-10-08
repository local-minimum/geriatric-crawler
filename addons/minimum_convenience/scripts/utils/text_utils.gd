class_name TextUtils

const _SPACERS: String = " -_:/[]().,;\\/?!*&"

static var _next_word: RegEx = RegEx.new()
static var _next_sentence: RegEx = RegEx.new()
static var _paragraph: RegEx = RegEx.new()

enum Segment { NONE, DEFAULT, PARAGRAPH, SENTENCE, WORD, CHARACTER }

static func init() -> void:
    if _next_word.compile("[^ \n]*[ \n]?") != OK:
        push_error("Next word pattern didn't compile")
    if _next_sentence.compile(".*?[.!?]+([ \n]|$)") != OK:
        push_error("Next sentence pattern didn't compile")
    if _paragraph.compile("\n*(.|\n)*?(\n\n|\\Z)") != OK:
        push_error("Next paragraph pattern didn't compile")

## Return end of next text segment
## NOTE: TextUtils.init() must have been called first for proper operations
static func find_message_segment_end(text: String, start: int, segment: Segment) -> int:
    match segment:
        Segment.CHARACTER:
            return start + (2 if start < text.length() && _SPACERS.contains(text[start]) else 1)

        Segment.WORD:
            var match: RegExMatch = _next_word.search(text, start)
            if match:
                return match.get_end()
            return text.length()

        Segment.SENTENCE:
            var match: RegExMatch = _next_sentence.search(text, start)
            if match:
                return match.get_end()
            return text.length()

        Segment.PARAGRAPH:
            var match: RegExMatch = _paragraph.search(text, start)
            if match:
                return match.get_start(2)
            return text.length()

    return text.length()
