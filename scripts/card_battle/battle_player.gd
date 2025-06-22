extends BattleEntity
class_name BattlePlayer

@export
var _slots: BattleCardSlots

func play_actions(
    _on_complete: Callable,
) -> void:
    print_debug("Start player turn")
    _slots.show_slotted_cards()

func get_entity_name() -> String:
    return "Simon Cyberdeck"
