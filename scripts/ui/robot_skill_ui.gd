extends Control
class_name RobotSkillUI

@export
var _icon: TextureRect

@export
var _generic_icon: Texture

@export
var _title: Label

@export
var _description: Label

@export
var _buy_button: Button

@export
var _background: ColorRect

@export
var _option_color: Color

@export
var _buyable_color: Color

@export
var _bought_color: Color

@export
var _not_bought_color: Color

enum State { Option, Buyable, Bought, NotBought }

func _state_to_color(state: State) -> Color:
    match  state:
        State.Option: return _option_color
        State.Buyable: return _buyable_color
        State.Bought: return _bought_color
        State.NotBought: return _not_bought_color
        _:
            push_warning("State %s doesn't have a color" % state)
            return _option_color

func _state_to_button_text(state: State, cost: int) -> String:
    match state:
        State.Option: return "BUY ₳%s" % cost
        State.Buyable: return "BUY ₳%s" % cost
        State.Bought: return "ACTIVE"
        State.NotBought: return "NOT ACTIVE"
        _:
            push_warning("State %s doesn't have a color" % state)
            return "BUY ₳%s" % cost

func sync(ability: RobotAbility, state: State, cost: int = 1000) -> void:
    _title.text = ability.full_skill_name()
    _description.text = ability.description
    _icon.texture = _generic_icon if ability.icon == null else ability.icon
    _background.color = _state_to_color(state)
    _buy_button.disabled = state != State.Buyable
    _buy_button.text = _state_to_button_text(state, cost)
