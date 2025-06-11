extends Node
class_name GridEncounterEffect

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(_encounter: GridEncounter, _player: GridEntity) -> bool:
    push_warning("Encounter '%s' doesn't have an effect" % _encounter.encounter_id)
    return false

## Optional on complete clean up of effect
func complete() -> void:
    push_warning("Encounter effect %s doesn't complete action" % name)
