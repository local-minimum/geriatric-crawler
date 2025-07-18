extends GridEvent
class_name GridRamp

@export
var climbing_requirement: int = 0

func manages_triggering_translation() -> bool:
    return true

func trigger(entity: GridEntity) -> void:
    super.trigger(entity)
    entity.cinematic = true
