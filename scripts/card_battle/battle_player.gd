extends BattleEntity
class_name BattlePlayer

@export
var _slots: BattleCardSlots

func play_actions(
    on_complete: Callable,
) -> void:
    pass
