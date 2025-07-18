extends GridEvent
class_name GridRamp

@export
var climbing_requirement: int = 0

@export
var up_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.UP

## If entity is wallwalking we need to trigger event on inverse upper exit direction walls
@export
var upper_exit_direction: CardinalDirections.CardinalDirection

@export
var lower_exit_direction: CardinalDirections.CardinalDirection

func manages_triggering_translation() -> bool:
    return true

func trigger(entity: GridEntity) -> void:
    super.trigger(entity)
    entity.cinematic = true

func blocks_entry_translation(
    from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if super.blocks_entry_translation(from, move_direction, to_side):
        return true

    var expected_from: Vector3i = CardinalDirections.translate(
        CardinalDirections.translate(coordinates(), up_direction),
        upper_exit_direction,
    )

    if expected_from == from.coordinates:
        var elevation: int = CardinalDirections.vectori_axis_value(
            CardinalDirections.translate(coordinates(), up_direction),
            up_direction,
        )

        if elevation != CardinalDirections.vectori_axis_value(from.coordinates, up_direction):
            print_debug("Walking in to ramp %s" % CardinalDirections.name(upper_exit_direction))
            return true

        print_debug("Entering ramp properly from %s" % CardinalDirections.name(upper_exit_direction))
        return false

    print_debug("Not entering ramp at %s from %s was %s" % [coordinates(), expected_from, from.coordinates])
    return false
