extends GridNodeFeature
class_name GridEvent

const GRID_EVENT_GROUP: String = "grid-events"

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

func _init() -> void:
    add_to_group(GRID_EVENT_GROUP)

func available() -> bool: return _repeatable || !_triggered

## If a translation should trigger the event
func should_trigger(
    _entity: GridEntity,
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
    _entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if _blocks_sides.has(to_side):
        print_debug("Event %s blocks entry to side %s" % [name, CardinalDirections.name(to_side)])
        return true

    var entry_from: CardinalDirections.CardinalDirection = CardinalDirections.invert(move_direction)
    if _blocks_sides.has(entry_from):
        print_debug("Event %s blocks entry from %s" % [name, CardinalDirections.name(entry_from)])
        return true

    return false

## If event blocks entry translation
func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return _blocks_sides.has(exit_direction)

func side_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return _blocks_sides.has(side)

func manages_triggering_translation() -> bool:
    return false

func trigger(_entity: GridEntity, _movement: Movement.MovementType) -> void:
    _triggered = true

func needs_saving() -> bool:
    return false

func save_key() -> String:
    return ""

func collect_save_data() -> Dictionary:
    return {}

func load_save_data(_data: Dictionary) -> void:
    pass
