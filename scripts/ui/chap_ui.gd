extends Control
class_name ChapUI
@export var _story_main: Resource
@export var _ink_adapter: InkAdapter

@export var title: Label
@export var scroll_container: ScrollContainer
@export var messages: VBoxContainer
@export var message_font_size: int = 10
@export var animation: TextUtils.Segment
@export var ignore_empty_messages: bool = true
@export_range(0, 1) var letter_pause: float = 0.05
@export_range(0, 1) var word_pause: float = 0.1
@export_range(0, 1) var sentence_pause: float = 0.3
@export_range(0, 1) var option_pause: float = 0.5

var _animating: bool
var _fast_forward: bool
var _choosing: bool
var _story_queue: Array[String]
var _awaiting_choice: Array[InkAdapter.Choice]
var _option_buttons: Array[Button]
var _story_state: Dictionary[String, Variant]

const _OPTION_KEYS: Array[Key] = [KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const _BTN_META_CHOICE: String = "choice"
const _BTN_META_HOTKEY: String = "hot_key"
const _MAIN_STORY_KNOWS_CHAP: String = "knows_chap"
const _MAIN_STORY_KNOWS_PREMIUM: String = "knows_premium"
const _MAIN_STORY_KNOWS_SHORT_MONTHS: String = "knows_short_months"
const _MAIN_STORY_COLLECTION_QUEST: String = "collection_quest"
const _STORY_CREDITS: String = "credits"
const _STORY_LOANED_CREDITS: String = "loaned_credits"
const _STORY_FUNCTION_LOAN: String = "take_out_loan"

var _busy: bool:
    get():
        return _animating || _choosing || _story_queue.size() > 0

func _ready() -> void:
    TextUtils.init()

    if _ink_adapter.on_display_text.connect(_display_story_part) != OK:
        push_error("Failed to connect display story")

    if _ink_adapter.on_display_choices.connect(_display_story_choice) != OK:
        push_error("Failed to connect display choice")

    if _ink_adapter.on_variable_changed.connect(_handle_story_variable_change) != OK:
        push_error("Failed to connect variable changed")

    if _ink_adapter.on_load_story.connect(_handle_story_loaded) != OK:
        push_error("Failed to connect story loaded")

    if _ink_adapter.on_story_end.connect(_handle_story_ended) != OK:
        push_error("Failed to connect story ended")

    await get_tree().create_timer(1).timeout
    _ink_adapter.load_story(_story_main, false, _get_main_story_state())

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return

    if _choosing && event is InputEventKey:
        var key: InputEventKey = event

        if key.pressed && _OPTION_KEYS.has(key.keycode):
            var option_id: int = _OPTION_KEYS.find(key.keycode)
            var btn_idx: int = _option_buttons.find_custom(func (btn: Button) -> bool: return btn.get_meta(_BTN_META_HOTKEY) == option_id)
            # print_debug("[CHAP] Key %s is option %s and that gives btn %s" % [key.keycode, option_id, btn_idx])
            if btn_idx >= 0:
                @warning_ignore_start("unsafe_call_argument")
                _handle_choice(_option_buttons[btn_idx].get_meta(_BTN_META_CHOICE))
                @warning_ignore_restore("unsafe_call_argument")

    if (_animating || _choosing) && event.is_action_pressed("ui_select"):
        _fast_forward = true

func _handle_story_loaded() -> void:
    _ink_adapter.register_story_function(_STORY_FUNCTION_LOAN, self, "_handle_new_loan")

    _ink_adapter.continue_story()

func _handle_new_loan(amount: int) -> void:
    __GlobalGameState.take_out_loan(amount)

func _handle_story_ended() -> void:
    _ink_adapter.unregister_story_function(_STORY_FUNCTION_LOAN)

func _get_main_story_state() -> Dictionary[String, Variant]:
    if _story_state.is_empty():
        return {
            _MAIN_STORY_KNOWS_CHAP: false,
            _MAIN_STORY_KNOWS_PREMIUM: 0,
            _MAIN_STORY_COLLECTION_QUEST: "",
            _MAIN_STORY_KNOWS_SHORT_MONTHS: !__GlobalGameState.is_first_month,
            _STORY_CREDITS: __GlobalGameState.total_credits,
            _STORY_LOANED_CREDITS: __GlobalGameState.loans,
        }
    else:
        _story_state[_MAIN_STORY_KNOWS_SHORT_MONTHS] = !__GlobalGameState.is_first_month
        _story_state[_STORY_CREDITS] = __GlobalGameState.total_credits
        _story_state[_STORY_LOANED_CREDITS] = __GlobalGameState.loans

        return _story_state

func _handle_story_variable_change(variable: String, value: Variant) -> void:
    if variable in _story_state:
        _story_state[variable] = value

func _display_story_part(text: String, _tags: Array) -> void:
    if _busy:
        if text.strip_edges().is_empty():
            return
        _story_queue.append(text.strip_edges())
        return

    if text.strip_edges().is_empty():
        _ink_adapter.continue_story()
        return

    _add_message(text.strip_edges())

func _display_story_choice(options: Array[InkAdapter.Choice]) -> void:
    print_debug("[CHAP] Received %s options choice" % options.size())

    _awaiting_choice = options

    if _busy:
        print_debug("[CHAP] Busy, waiting with the stories")
        return

    _display_options()

func _display_options() -> void:
    _choosing = true
    _fast_forward = false

    var hot_key: int = 1
    for choice: InkAdapter.Choice in _awaiting_choice:
        var btn: Button = _get_option_buttion()
        btn.text = "%s. %s" % [hot_key, choice.text.strip_edges()]
        btn.set_meta(_BTN_META_CHOICE, choice)
        btn.set_meta(_BTN_META_HOTKEY, hot_key)

        if btn.connect(
            "pressed",
            func () -> void:
                _handle_choice(choice)
                ,
        ) != OK:
            push_error("Failed to connect callback for pressing option %s" % hot_key)

        _option_buttons.append(btn)
        messages.add_child(btn)
        if get_tree().create_timer(0.1).connect("timeout", _scroll_to_bottom) != OK:
            pass

        if !_fast_forward:
            await get_tree().create_timer(option_pause).timeout

        hot_key += 1

    print_debug("[CHAP] %s choices presented" % _awaiting_choice.size())

func _handle_choice(choice: InkAdapter.Choice) -> void:
    if !_choosing:
        push_error("Should not be allowed to choose at this moment")

    for btn: Button in _option_buttons:
        if btn.get_meta(_BTN_META_CHOICE).choice_index == choice.choice_index:
            btn.disabled = true
        else:
            btn.queue_free()

    _option_buttons.clear()
    _awaiting_choice.clear()
    _choosing = false

    _ink_adapter.select_choice(choice.choice_index)

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
    _fast_forward = false

    label.visible_characters = 0

    var start: int = 0
    var end: int = 0

    while end < message.length() && !_fast_forward:
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

    if _story_queue.size() > 0:
        var next_message: String = _story_queue.pop_front()
        _add_message.call_deferred(next_message)
    elif _awaiting_choice.size() > 0:
        _display_options()
        _animating = false
    else:
        print_debug("[CHAP] All waiting items processed")
        _animating = false
        _ink_adapter.continue_story()

func _scroll_to_bottom() -> void:
    scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

const _MIN_COMPONENT_SIZE: Vector2 = Vector2(100, 0)

func _get_message_label() -> Label:
    var label: Label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = _MIN_COMPONENT_SIZE
    label.add_theme_font_size_override("font_size", message_font_size)
    return label

func _get_option_buttion() -> Button:
    var btn: Button = Button.new()
    btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    btn.custom_minimum_size = _MIN_COMPONENT_SIZE
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn.add_theme_font_size_override("font_size", message_font_size)

    return btn

func collect_save_state() -> Dictionary[String, Variant]:
    var state: Dictionary[String, Variant] = _get_main_story_state().duplicate()
    @warning_ignore_start("return_value_discarded")
    state.erase(_STORY_CREDITS)
    state.erase(_STORY_LOANED_CREDITS)
    state.erase(_MAIN_STORY_KNOWS_SHORT_MONTHS)
    @warning_ignore_restore("return_value_discarded")

    return state

func load_save_state(state: Dictionary) -> void:
    _story_state.clear()
    for key: String in [_MAIN_STORY_COLLECTION_QUEST, _MAIN_STORY_KNOWS_CHAP, _MAIN_STORY_KNOWS_PREMIUM]:
        if state.has(key):
            var value: Variant = state[key]
            match key:
                _MAIN_STORY_KNOWS_CHAP:
                    if value is not bool:
                        continue
                _MAIN_STORY_COLLECTION_QUEST:
                    if value is not String:
                        continue
                _MAIN_STORY_KNOWS_PREMIUM:
                    if value is not int:
                        continue
            _story_state[key] = value
