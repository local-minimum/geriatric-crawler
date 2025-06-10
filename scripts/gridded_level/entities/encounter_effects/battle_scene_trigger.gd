extends GridEncounterEffect

# TODO: 1. Trigger overlay animation 2. Give control to overlay

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(encounter: GridEncounter, _player: GridEntity) -> bool:
    var level: GridLevel = encounter.get_level()
    level.paused = true
    return true
