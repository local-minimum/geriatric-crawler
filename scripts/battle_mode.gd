extends Node
class_name BattleMode

@export
var animator: AnimationPlayer

var trigger: GridEncounterEffect

func enter_battle(battle_trigger: GridEncounterEffect) -> void:
    trigger = battle_trigger

    animator.play("fade_in_battle")
    await get_tree().create_timer(1.0).timeout
    if trigger.free_encounter_on_complete:
        trigger.encounter.visible = false
    # Show battle
    await get_tree().create_timer(1.0).timeout
    # Let player battle
    # For now return to explore
    await get_tree().create_timer(0.5).timeout
    # Return to explore
    exit_battle()


func exit_battle() -> void:
    animator.play("fade_out_battle")
    await get_tree().create_timer(0.5).timeout
    trigger.complete()
