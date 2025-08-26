extends NinePatchRect
class_name BattleCard

signal on_drag_card(card: BattleCard)
signal on_drag_start(card: BattleCard)
signal on_drag_end(card: BattleCard)
signal on_click(card: BattleCard)
signal on_hover_start(card: BattleCard)
signal on_hover_end(card: BattleCard)
signal on_debug_card(card: BattleCard, msg: String)

const CLICK_DURATION: float = 0.075

static var _next_drag: float
static var _dragged: BattleCard = null:
    set(value):
        if _dragged != value && _dragged != null:
            var t: float = Time.get_unix_time_from_system()
            if t < _next_drag:
                return

            _next_drag = t + 0.1
            if _dragged != null:
                _dragged.on_debug_card.emit(_dragged, "drag end")
                _dragged.on_drag_end.emit(_dragged)

        _dragged = value
        if value != null:
            value.on_debug_card.emit(_dragged, "drag start")
            value.on_drag_start.emit(value)

static var _next_hover: float
static var _hovered: BattleCard:
    set(value):
        if value == _hovered:
            return

        if value == null || _hovered == null:
            if _hovered != null:
                _hovered.on_hover_end.emit(_hovered)
            if value != null:
                value.on_hover_start.emit(value)
            _hovered = value
            return

        var t: float = Time.get_unix_time_from_system()
        if t > _next_hover:
            _next_hover = t + 0.1

            if _hovered != null:
                _hovered.on_hover_end.emit(_hovered)
            if value != null:
                value.on_hover_start.emit(value)

            _hovered = value

@export var suite_icon: TextureRect
@export var suite_electricity: Texture
@export var suite_metal: Texture
@export var suite_data: Texture
@export var suite_electricity_metal: Texture
@export var suite_metal_data: Texture
@export var suite_data_electricity: Texture
@export var suite_data_electricity_metal: Texture

@export var rank_label: Label
@export var card_icon: TextureRect
@export var title: Label

@export var primary_effects: Array[BattleCardPrimaryEffectUI]
@export var main_divider: Control

@export var secondary_effects: Array[Label]
@export var secondary_effects_dividers: Array[Control]

var card_played: bool

var interactable: bool :
    set (value):
        interactable = value
        mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND if value else CursorShape.CURSOR_ARROW
        suite_icon.mouse_default_cursor_shape = mouse_default_cursor_shape
        rank_label.mouse_default_cursor_shape = mouse_default_cursor_shape
        card_icon.mouse_default_cursor_shape = mouse_default_cursor_shape
        title.mouse_default_cursor_shape = mouse_default_cursor_shape

        for effect: BattleCardPrimaryEffectUI in primary_effects:
            effect.mouse_default_cursor_shape = mouse_default_cursor_shape

        for effect: Label in secondary_effects:
            effect.mouse_default_cursor_shape = mouse_default_cursor_shape

        for divider: Control in secondary_effects_dividers:
            divider.mouse_default_cursor_shape = mouse_default_cursor_shape

        main_divider.mouse_default_cursor_shape = mouse_default_cursor_shape
        (main_divider.get_parent() as Control).mouse_default_cursor_shape = mouse_default_cursor_shape


var data: BattleCardData:
    set(value):
        data = value
        sync_display(0)

func sync_display(bonus: int) -> void:
        name = "Card %s" % data.id
        suite_icon.visible = data.suit != BattleCardData.SUIT_NONE
        suite_icon.texture = _get_suite_icon_texture(data.suit)

        rank_label.text = str(data.rank)
        card_icon.texture = data.icon

        title.text = data.localized_name()

        for idx: int in range(primary_effects.size()):
            if idx == 0 || idx < data.primary_effects.size():
                primary_effects[idx].sync(data.primary_effects[idx] if idx < data.primary_effects.size() else null, bonus)
                primary_effects[idx].visible = true
            else:
                primary_effects[idx].visible = false

        var effects: Array[String] = data.secondary_effect_names()
        var tooltips: Array[String] = data.secondary_effect_tooltips()

        for idx: int in range(secondary_effects.size()):
            if idx < effects.size():
                secondary_effects[idx].visible = true
                secondary_effects[idx].text = effects[idx]
                secondary_effects[idx].tooltip_text = tooltips[idx]
            else:
                secondary_effects[idx].visible = false
        for idx: int in range(secondary_effects_dividers.size()):
            secondary_effects_dividers[idx].visible = idx < effects.size() - 1

        main_divider.visible = !effects.is_empty()

func _get_suite_icon_texture(suite: int) -> Texture:
    match suite:
        BattleCardData.SUIT_ELECTRICITY: return suite_electricity
        BattleCardData.SUIT_DATA: return suite_data
        BattleCardData.SUIT_METAL: return suite_metal

        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_DATA: return suite_data_electricity
        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_METAL: return suite_electricity_metal
        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL: return suite_metal_data

        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL | BattleCardData.SUIT_ELECTRICITY: return suite_data_electricity_metal

        BattleCardData.SUIT_NONE: return null

        _:
            push_error("Suite %s (%s) doesn't have an icon" % [BattleCardData.suit_name(suite), suite])
            print_stack()
            return null

func _get_primary_effect_text(effect: BattleCardPrimaryEffect, crit_multiplyer: int) -> String:
    var target_range: String = BattleCardPrimaryEffect.target_range_text(effect.get_target_range())
    var effect_range: Array[int] = effect.get_effect_range(crit_multiplyer)

    var can_crit: bool = effect.can_crit()
    var mode: String = effect.mode_name()
    var target_type: String = effect.target_type_text()
    var effect_range_text: String ="%s - %s" % effect_range if effect_range[0] != effect_range[1] else str(effect_range[0])

    return "%s %s %s %s" % [
        mode,
        target_range,
        target_type,
        tr("FOR_VALUE").format({"value": "%s%s" % [effect_range_text, "★" if can_crit else ""]}),
    ]

var _may_drag: bool
var _active_device: int = -1

func _gui_input(event: InputEvent) -> void:
    if !interactable:
        return

    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event

        on_debug_card.emit(self, "Touched")

        if touch.pressed && _dragged == null:
            _hovered = self

        _handle_click(touch.pressed, touch.device)

        if !touch.pressed && _hovered == self:
            _hovered = null

    if event is InputEventMouseButton:
        var button: InputEventMouseButton = event
        if button.button_index == MOUSE_BUTTON_LEFT:
            _handle_click(button.pressed, button.device)

    elif event is InputEventMouseMotion:
        var mouse_drag: InputEventMouseMotion = event
        if (_may_drag || _dragged == self) && mouse_drag.device == _active_device:
            _handle_drag(mouse_drag.relative)

    elif event is InputEventScreenDrag:
        var touch_drag: InputEventScreenDrag = event
        if (_may_drag || _dragged == self) && touch_drag.device == _active_device:
            _handle_drag(touch_drag.relative)

func _handle_click(pressed: bool, device: int) -> void:
    if _dragged != self && _hovered == self && pressed:
        on_debug_card.emit(self, "Pressed")
        _active_device = device
        var timer: SceneTreeTimer = get_tree().create_timer(CLICK_DURATION)
        if timer.connect("timeout", self._check_start_drag) != OK:
            push_error("Couldn't set callback of timer")

    elif !pressed && _active_device == device:
        on_debug_card.emit(self, "Let go")
        _active_device = -1
        if _dragged == self:
            _dragged = null
        elif _hovered == self && _dragged == null:
            on_debug_card.emit(self, "Clicked")
            on_click.emit(self)

func _handle_drag(relative: Vector2) -> void:
    if _may_drag:
        # A bit of deadzoneing
        if relative.length_squared() > 5:
            _dragged = self
            _may_drag = false
            if _dragged == self:
                move_to_front()

    if _dragged == self:
        global_position += relative

        on_drag_card.emit(self)

func _check_start_drag() -> void:
    if _active_device < 0 || _hovered != self || _dragged != null:
        return
    _may_drag = true

func _on_mouse_exited() -> void:
    if OS.get_name() == "Android":
        return

    if _dragged != null:
        return

    if _hovered == self:
        _hovered = null

func _on_mouse_entered() -> void:
    if OS.get_name() == "Android":
        return

    if _dragged != null:
        return

    _hovered = self
