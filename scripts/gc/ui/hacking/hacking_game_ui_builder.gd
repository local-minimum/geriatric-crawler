class_name HackingGameUIBuilder

static func get_shift_button(parent: Container, localized_direction: String, tex: Texture) -> Button:
    var container: Container = get_empty_container()
    var btn: Button = Button.new()
    btn.icon = tex
    btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    btn.expand_icon = true
    btn.tooltip_text = __GlobalGameState.tr("SHIFT_CODES").format({"direction": localized_direction.to_lower()})
    btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
    size_playing_field_item(btn)

    container.add_child(btn)
    parent.add_child(container)
    return btn

static func get_empty_container() -> Control:
    var container: AspectRatioContainer = AspectRatioContainer.new()
    size_playing_field_item(container)
    container.ratio = 1
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return container

static func size_playing_field_item(control: Control) -> void:
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func get_spacer(color: Color) -> Control:
    var container: Container = get_empty_container()
    var rect: ColorRect = ColorRect.new()
    rect.color = color
    size_playing_field_item(rect)

    container.add_child(rect)
    return container

static func get_texture_spacer(bg_color: Color, config_texturerect: Callable) -> Control:
    var container: Container = get_spacer(bg_color)
    var t_rect: TextureRect = TextureRect.new()
    size_playing_field_item(t_rect)

    config_texturerect.call(t_rect)
    t_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT

    container.add_child(t_rect)
    return container

static func add_word_ui_to_container(parent: Container, word: String, parts_assignment: Variant = null) -> void:
    var container: Container = get_empty_container()

    var bg: TextureRect = TextureRect.new()
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

    size_playing_field_item(bg)
    container.add_child(bg)

    var label: Label = Label.new()
    label.text = word
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED

    size_playing_field_item(label)
    container.add_child(label)

    parent.add_child(container)

    if parts_assignment != null && parts_assignment is Callable:
        @warning_ignore_start("unsafe_cast")
        (parts_assignment as Callable).call(label, bg, container)
        @warning_ignore_restore("unsafe_cast")
