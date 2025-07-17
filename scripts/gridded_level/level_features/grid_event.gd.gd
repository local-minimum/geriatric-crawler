extends GridNodeFeature
class_name GridEvent

@export
var _repeatable: bool = true

@export
var _trigger_entire_node: bool

@export
var _trigger_sides: Array[CardinalDirections.CardinalDirection]

# TODO: Might need to handle rotation to not have to set manually always

## Both attachment and entry from the side
@export
var _blocks_sides: Array[CardinalDirections.CardinalDirection]

var _triggered: bool

func available() -> bool: return _repeatable || !_triggered

## If a translation should trigger the event
func should_triggers(
    from: GridNode,
    from_side: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if !_repeatable && _triggered:
        return false

    if _trigger_entire_node:
        return from != get_grid_node()

    return _trigger_sides.has(to_side) && (!_trigger_sides.has(from_side) || from != get_grid_node())

## If event blocks entry translation
func blocks_entry_translation(
    from_direction: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if _blocks_sides.has(to_side): return true

    var entry_from: CardinalDirections.CardinalDirection = CardinalDirections.invert(from_direction)
    return _blocks_sides.has(entry_from)

## If event blocks entry translation
func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return _blocks_sides.has(exit_direction)

func trigger(_entity: GridEntity) -> void:
    _triggered = true
