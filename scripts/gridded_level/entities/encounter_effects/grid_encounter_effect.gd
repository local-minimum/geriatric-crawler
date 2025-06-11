extends Node
class_name GridEncounterEffect

var encounter: GridEncounter

@export
var hide_encounter_on_trigger: bool

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounter, _player: GridEntity) -> bool:
    encounter = triggering_encounter
    return false

## Optional on complete clean up of effect
func complete() -> void:
    pass
