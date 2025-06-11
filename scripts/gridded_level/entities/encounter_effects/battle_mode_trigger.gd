extends GridEncounterEffect

var level: GridLevel

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounter, player: GridEntity) -> bool:
    print_debug("Entering battle with %s" % triggering_encounter.name)

    @warning_ignore_start("return_value_discarded")
    super(triggering_encounter, player)
    @warning_ignore_restore("return_value_discarded")

    level = triggering_encounter.get_level()
    level.paused = true
    level.battle_mode.enter_battle(self)
    return true

func complete() -> void:
    super()

    level.paused = false
    print_debug("Battle ended, returned to exploring")
