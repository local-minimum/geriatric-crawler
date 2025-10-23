extends Node
class_name GridEncounterEffect

var encounter: GridEncounterCore

@export var hide_encounter_on_trigger: bool

## Called when the encounter is ready
func prepare(_encounter: GridEncounterCore) -> void:
    pass

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounterCore, _player: GridEntity) -> bool:
    encounter = triggering_encounter
    return false

## Optional on complete clean up of effect
func complete() -> void:
    pass
