extends Node
class_name InkAdapter

signal on_load_story
signal on_load_story_fail
signal on_story_start
signal on_story_end
signal on_display_text(text: String, tags: Array)
signal on_display_choices(choices: Array)
signal on_variable_changed(variable: String, value: Variant)

var _ink_player: InkPlayer = InkPlayerFactory.create()
var _play_on_load: bool
var _initial_variable_state: Dictionary[String, Variant]

func _ready() -> void:
    add_child(_ink_player)
    if _ink_player.connect("loaded", self._story_loaded) != OK:
        push_error("Failed to connect story loaded")
    if _ink_player.connect("continued", self._continued) != OK:
        push_error("Failed to connects story coninued")
    if _ink_player.connect("prompt_choices", self._prompt_choices) != OK:
        push_error("Failed to connect story choices")
    if _ink_player.connect("ended", self._ended) != OK:
        push_error("Failed to connect story ended")

func play() -> void:
    if _ink_player.can_continue:
        @warning_ignore_start("return_value_discarded")
        _ink_player.continue_story()
        @warning_ignore_restore("return_value_discarded")
        on_story_start.emit()

func load_story(
    ink_file: Resource,
    play_on_load: bool = false,
    initial_state: Dictionary[String, Variant] = {},
) -> void:
    _play_on_load = play_on_load
    _initial_variable_state = initial_state

    if ink_file != null:
        _ink_player.ink_file = ink_file
        if _ink_player.create_story() != OK:
            push_error("[InkAdapter] Failed to load story from ink file")
        print_debug("[InkAdapter] Loading ink story")
    else:
        push_error("No story to load")

func _story_loaded(successfully: bool) -> void:
    if !successfully:
        push_warning("Failed to load ink story")
        on_load_story_fail.emit()
        return

    print_debug("[InkAdapter] Story loaded")

    if _ink_player._story.variables_state.variable_changed.connect(_variable_updated) != OK:
        push_error("Failed to connect story variable changed")

    if !_initial_variable_state.is_empty():
        set_variables(_initial_variable_state)

    on_load_story.emit()
    if _play_on_load:
        print_debug("[InkAdapter] Story Auto-plays")
        @warning_ignore_start("return_value_discarded")
        _ink_player.continue_story()
        @warning_ignore_restore("return_value_discarded")
        on_story_start.emit()

func _continued(text: String, tags: Array) -> void:
    print_debug("[InkAdapter] Story continued")
    on_display_text.emit(text, tags)
    @warning_ignore_start("return_value_discarded")
    _ink_player.continue_story()
    @warning_ignore_restore("return_value_discarded")

func _prompt_choices(choices: Array) -> void:
    print_debug("[InkAdapter] %s choices offered" % choices.size())
    if !choices.is_empty():
        on_display_choices.emit(choices)

func select_choice(index: int) -> void:
    _ink_player.choose_choice_index(index)
    @warning_ignore_start("return_value_discarded")
    _ink_player.continue_story()
    @warning_ignore_restore("return_value_discarded")

func _ended() -> void:
    print_debug("[InkAdapter] story ended")
    on_story_end.emit()

var _supress_variable_changed: bool

func set_variables(store: Dictionary[String, Variant]) -> void:
    for variable: String in store:
        _supress_variable_changed = true
        @warning_ignore_start("unsafe_call_argument")
        _ink_player.set_variable(variable, store[variable])
        @warning_ignore_restore("unsafe_call_argument")

func get_variables(variables: Array[String]) -> Dictionary[String, Variant]:
    var result: Dictionary[String, Variant]
    for variable: String in variables:
        result[variable] = _ink_player.get_variable(variable)

    return result

func _variable_updated(variable: String, obj: InkObject) -> void:
    if _supress_variable_changed:
        _supress_variable_changed = false
        return

    if obj is InkValue:
        var value: InkValue = obj
        on_variable_changed.emit(variable, value.value_object)
