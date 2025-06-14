extends NinePatchRect
class_name BattleCard

signal on_drag_card(card: BattleCard)
signal on_drag_start(card: BattleCard)
signal on_drag_end(card: BattleCard)
signal on_click(card: BattleCard)

const CLICK_DURATION: float = 0.075

@export
var suite_icon: TextureRect

@export
var suite_electricity: Texture

@export
var suite_metal: Texture

@export
var suite_data: Texture

@export
var suite_electricity_metal: Texture

@export
var suite_metal_data: Texture

@export
var suite_data_electricity: Texture

@export
var suite_data_electricity_metal: Texture

@export
var rank_label: Label

@export
var card_icon: TextureRect

@export
var primary_effect: RichTextLabel

@export
var divider: Control

@export
var secondary_effect: RichTextLabel

var interactable: bool

var data: BattleCardData:
    set(value):
        data = value
        sync_display(0)

func sync_display(crit_multiplyer: int) -> void:
        suite_icon.visible = data.suit != BattleCardData.SUIT_NONE
        suite_icon.texture = _get_suite_icon_texture(data.suit)

        rank_label.text = str(data.rank)
        card_icon.texture = data.icon

        var primary_effect_parts: Array[String] = [data.name]
        for effect: BattleCardPrimaryEffect in data.primary_effects:
            primary_effect_parts.append(_get_primary_effect_text(effect, crit_multiplyer))
        primary_effect.text = "%s\n%s" % primary_effect_parts

        if data.secondary_effects.is_empty():
            divider.visible = false
            secondary_effect.visible = false
        else:
            divider.visible = true
            secondary_effect.visible = true
            secondary_effect.text = "\n".join(data.secondary_effect_names())

func _get_suite_icon_texture(suite: int) -> Texture:
    match suite:
        BattleCardData.SUIT_ELECTRICITY: return suite_electricity
        BattleCardData.SUIT_DATA: return suite_data
        BattleCardData.SUIT_METAL: return suite_metal

        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_DATA: return suite_data_electricity
        BattleCardData.SUIT_ELECTRICITY | BattleCardData.SUIT_METAL: return suite_electricity_metal
        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL: return suite_metal_data

        BattleCardData.SUIT_DATA | BattleCardData.SUIT_METAL | BattleCardData.SUIT_ELECTRICITY: return suite_data_electricity_metal

        _:
            push_error("Suite %s (%s) doesn't have an icon" % [BattleCardData.suit_name(suite), suite])
            print_stack()
            return null

func _get_primary_effect_text(effect: BattleCardPrimaryEffect, crit_multiplyer: int) -> String:
    var target_range: String = BattleCardPrimaryEffect.target_range_text(effect.get_target_range())
    var effect_range: Array[int] = effect.get_effect_range(crit_multiplyer)

    var can_crit: bool = effect.can_crit()

    return "%s %s %s for %s%s" % [
        effect.mode_name(),
        target_range,
        effect.target_type_text(),
        "% - %" % effect_range if effect_range[0] != effect_range[1] else str(effect_range[0]),
        "*" if can_crit else "",
    ]

var _dragging: bool
var _may_drag: bool
var _active_device: int = -1

func _input(event: InputEvent) -> void:
    if !interactable:
        return

    if event is InputEventMouseButton:
        var btn_event: InputEventMouseButton = event
        if btn_event.button_index == 1:
            if !_dragging && _hovered && btn_event.pressed && !btn_event.is_echo():
                _active_device = btn_event.device
                print_debug("Press start of %s" % _active_device)
                var timer: SceneTreeTimer = get_tree().create_timer(CLICK_DURATION)
                if timer.connect("timeout", self._check_start_drag) != OK:
                    push_error("Couldn't set callback of timer")

            elif !btn_event.pressed && _active_device == btn_event.device:
                print_debug("Press end of %s, dragging %s" % [_active_device, _dragging])
                _active_device = -1
                if _dragging:
                    _dragging = false
                    on_drag_end.emit(self)
                else:
                    on_click.emit(self)

    elif event is InputEventMouseMotion:
        var motion_event: InputEventMouseMotion = event
        if (_may_drag || _dragging) && motion_event.device == _active_device:
            var relative: Vector2 = motion_event.screen_relative

            if _may_drag:
                # A bit of deadzoneing
                _dragging = relative.length_squared() > 5
                if _dragging:
                    _may_drag = false
                    move_to_front()
                    on_drag_start.emit(self)

            if _dragging:
                global_position += relative

                on_drag_card.emit(self)

func _check_start_drag() -> void:
    if _active_device < 0:
        return
    _may_drag = true

var _hovered: bool

func _on_mouse_exited() -> void:
    _hovered = false

func _on_mouse_entered() -> void:
    _hovered = true
