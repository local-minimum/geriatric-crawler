extends GridEncounterEffect

var level: GridLevel
var encounter: GridEncounter

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounter, _player: GridEntity) -> bool:
    print_debug("Entering battle with %s" % triggering_encounter.name)
    encounter = triggering_encounter
    level = triggering_encounter.get_level()
    level.paused = true
    level.battle_mode.enter_battle(self)
    return true

func complete() -> void:
    level.paused = false
    print_debug("Battle ended, returned to exploring")
