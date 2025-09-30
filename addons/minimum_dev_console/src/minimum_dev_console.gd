extends Node
class_name MinimumDevConsole

@export var container: Control
@export var output: RichTextLabel
@export var output_scroll: ScrollContainer
@export var input_context: Label
@export var input: LineEdit

@export var hide_in_build: bool

@export_multiline var welcome_message: String
@export var commands: Array[MinimumDevCommand]
@export var reserved_up_command: String = "/up"
@export var reserved_home_command: String = "/home"

@export var info_color: Color = Color.WHITE_SMOKE
@export var input_color: Color = Color.LAWN_GREEN
@export var code_color: Color = Color.REBECCA_PURPLE
@export var error_color: Color = Color.CRIMSON

var _history_idx: int = 0
var _history: Array[String]
var _context: Array[String]

var disabled: bool:
    get():
        if hide_in_build && !OS.has_feature("debug"):
            return true
        return disabled

func _ready() -> void:
    container.visible = false

func _input(event: InputEvent) -> void:
    if container.visible && input.has_focus():
        if event is InputEventKey:
            _handle_input_key(event)
    else:
        if event.is_action_pressed("toggle_dev_console"):
            toggle_visible()
            get_viewport().set_input_as_handled()
        elif container.visible && event is InputEventKey:
            _handle_input_key(event)

func _handle_input_key(key: InputEventKey):
    if key.is_pressed() && !key.is_echo():
        match key.keycode:
            KEY_ESCAPE:
                toggle_visible()
                get_viewport().set_input_as_handled()
            KEY_UP, KEY_PAGEUP:
                go_history(-1)
                get_viewport().set_input_as_handled()
            KEY_DOWN, KEY_PAGEDOWN:
                go_history(1)
                get_viewport().set_input_as_handled()


func go_history(step: int) -> void:
    _history_idx = clampi(_history_idx + step, 0, _history.size())
    if _history_idx == _history.size():
        input.text = ""
    else:
        input.text = _history[_history_idx]

    input.caret_column = input.text.length()
    input.grab_focus.call_deferred()


## Connect pressing clear button to this
func handle_clear_console() -> void:
    _context.clear()

    output.text = ""
    input.text = ""
    input_context.text = ""
    input_context.visible = !input_context.text.is_empty()

    _output_line(welcome_message, info_color)
    _scroll_to_end()

func _scroll_to_end() -> void:
    await get_tree().process_frame
    output_scroll.scroll_vertical = int(output_scroll.get_v_scroll_bar().max_value)

func _output_line(text: String, color: Color, new_line: bool = true) -> void:
    output.append_text("[color=#%s]%s[/color]%s" % [color.to_html(), text, "\n" if new_line else ""])

## Connect submitting input to this
func handle_receive_command(command: String) -> void:
    command = command.strip_edges()

    _output_line("", input_color)
    _output_line("> %s" % command, input_color)

    input.text = ""

    if command.is_empty():
        list_commands()
        return

    _history.append(command)
    _history_idx = _history.size()

    if _handle_reserved_commands(command):
        _scroll_to_end()
        return

    var options: Array[MinimumDevCommand] = commands.filter(
        func (c: MinimumDevCommand) -> bool:
            return c.is_command(_context, command)
    )

    if options.is_empty():
        _output_line("Command '%s' not known" % command, error_color)
        list_commands()
        return

    options.sort_custom(
        func (a: MinimumDevCommand, b: MinimumDevCommand) -> bool:
            return a.command.size() > b.command.size()
    )

    var option: MinimumDevCommand = options[0]
    command = option.strip_cmd(command, _context)
    if !option.execute(command, self):
        if !command.is_empty():
            _output_line("Command '%s' failed to exectue with '%s'" % [" ".join(option.command), command], error_color)
        if !option.usage.is_empty():
            _output_line(option.usage, code_color)
        if !option.description.is_empty():
            _output_line(option.description, info_color)

        _scroll_to_end()

func _handle_reserved_commands(command: String) -> bool:
    match command.to_lower():
        reserved_up_command:
            _context.pop_back()
            input_context.text = " ".join(_context)
            input_context.visible = !input_context.text.is_empty()
            return true
        reserved_home_command:
            _context.clear()
            input_context.text = ""
            input_context.visible = !input_context.text.is_empty()
            return true
        _:
            return false

func list_commands() -> void:
    var available: Dictionary[String, MinimumDevCommand]
    var depth: int = _context.size()
    var context_command: MinimumDevCommand

    for command: MinimumDevCommand in commands:
        if command.is_context(_context):
            context_command = command
            continue

        if !command.in_context(_context):
            continue

        var sub_command: String = command.get_subcommand(depth)
        if !sub_command.is_empty():
            if !available.has(sub_command):
                available[sub_command] = command
            elif available[sub_command].command.size() > command.command.size():
                available[command.command[-1]] = command

    if !_context.is_empty():
        _output_line(" ".join(_context), code_color)
        if context_command != null && !context_command.description.is_empty():
            _output_line(context_command.description, info_color)

    for cmd: String in available:
        _output_line("- %s " % available[cmd].visible_command_from_context(depth), input_color, false)
        _output_line(available[cmd].description, info_color)

    _output_line("- %s " % reserved_up_command, input_color, false)
    _output_line("Remove outer context", info_color)
    _output_line("- %s " % reserved_home_command, input_color, false)
    _output_line("Clear all context", info_color)
    _scroll_to_end()

func set_context(context: Array[String]) -> void:
    _context = context.duplicate()
    input_context.text = " ".join(context)
    input_context.visible = !input_context.text.is_empty()

## Connect any UI button that shows/toggles the console to this
func toggle_visible() -> void:
    if container.visible:
        container.visible = false
    else:
        container.visible = true
        if output.text.is_empty():
            _output_line(welcome_message, info_color)
            print_debug("[Minimum Dev Console] Adding welcom to output")
        input.grab_focus.call_deferred()

func output_info(message: String) -> void:
    _output_line(message, info_color)
    _scroll_to_end()

func output_error(message: String) -> void:
    _output_line(message, error_color)
    _scroll_to_end()
