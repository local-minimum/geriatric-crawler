extends Node
class_name BalanceSheetUI

@export var positive_color: Color
@export var negative_color: Color

@export var credits_value: Label
@export var loans_value: Label

@export var debits_value: Label
@export var interest_value: Label
@export var rent_value: Label

@export var balance_value: Label

@export var due_time_value: Label

func _enter_tree() -> void:
    if __SignalBus.on_update_credits.connect(_handle_credits_update) != OK:
        push_error("Could not listen to credits change")
    if __SignalBus.on_update_day.connect(_handle_update_day) != OK:
        push_error("Could not listen to update day")

    credits_value.add_theme_color_override("font_color", positive_color)
    loans_value.add_theme_color_override("font_color", positive_color)

    debits_value.add_theme_color_override("font_color", negative_color)
    interest_value.add_theme_color_override("font_color", negative_color)
    rent_value.add_theme_color_override("font_color", negative_color)
    _sync()

func _sync() -> void:
    _handle_credits_update(__GlobalGameState.total_credits, __GlobalGameState.loans)
    _handle_update_rent(__GlobalGameState.rent)
    _update_balance()
    _handle_update_day(__GlobalGameState.year, __GlobalGameState.month, __GlobalGameState.day_of_month, __GlobalGameState.days_until_end_of_month)

func _handle_update_day(_year: int, _month: int, _day_of_mont: int, days_until_end_of_month: int) -> void:
    due_time_value.text = "%s" % days_until_end_of_month
    due_time_value.add_theme_color_override("font_color", positive_color if days_until_end_of_month > 3 else negative_color)

func _handle_update_rent(new_rent: int) -> void:
    rent_value.text = GlobalGameState.credits_with_sign(-new_rent)
    debits_value.text = GlobalGameState.credits_with_sign(-(new_rent + __GlobalGameState.calculate_interest()))

func _handle_credits_update(total_credits: int, loans: int) -> void:
    credits_value.text = GlobalGameState.credits_with_sign(total_credits)
    loans_value.text = GlobalGameState.credits_with_sign(loans)
    var interest: int = __GlobalGameState.calculate_interest()
    interest_value.text = GlobalGameState.credits_with_sign(-interest)
    debits_value.text = GlobalGameState.credits_with_sign(-(__GlobalGameState.rent + interest))

func _update_balance() -> void:
    var balance: int = __GlobalGameState.calculate_balance()
    balance_value.text = GlobalGameState.credits_with_sign(balance)
    balance_value.add_theme_color_override("font_color", positive_color if balance >= 0 else negative_color)
