extends Node
class_name GridEncounterEffect

@export
var free_encounter_on_complete: bool

var encounter: GridEncounter

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounter, _player: GridEntity) -> bool:
    encounter = triggering_encounter
    return false

## Optional on complete clean up of effect
func complete() -> void:
    if free_encounter_on_complete:
        encounter.queue_free()
