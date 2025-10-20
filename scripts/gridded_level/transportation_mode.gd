extends Resource
class_name TransportationMode

const NONE : int  = 0
const WALKING : int = 1
const FLYING : int = 2
const CLIMBING : int = 4
const WALL_WALKING : int = 8
const CEILING_WALKING : int = 16
const SQUEEZING : int = 32
const SWIMMING : int = 64
const FALLING : int = 128

const ALL_FLAGS: Array[int] = [WALKING, FLYING, CLIMBING, WALL_WALKING, CEILING_WALKING, SQUEEZING, SWIMMING, FALLING]

const EXOTIC_WALKS: Array[int] = [WALL_WALKING, CEILING_WALKING]

@export_flags("Walking", "Flying", "Climbing", "Wall Walking", "Ceiling Walking", "Squeezing", "Swimming", "Falling")
var mode: int = 0

func set_flag(flag: int) -> void:
    mode = mode | flag

func remove_flag(flag: int) -> void:
    mode = mode & ~flag

func has_flag(flag: int) -> bool:
    return (mode & flag) == flag

func has_any(flags: Array[int]) -> bool:
    for flag: int in flags:
        if has_flag(flag):
            return true
    return false

func has_all(flags: Array[int]) -> bool:
    for flag: int in flags:
        if !has_flag(flag):
            return false
    return true

func get_flags() -> Array[int]:
    var flags: Array[int] = []

    for flag: int in ALL_FLAGS:
        if has_flag(flag):
            flags.append(flag)

    return flags

func can_walk(direction: CardinalDirections.CardinalDirection) -> bool:
    match direction:
        CardinalDirections.CardinalDirection.NONE:
            return has_flag(FLYING)
        CardinalDirections.CardinalDirection.DOWN:
            return has_flag(WALKING)
        CardinalDirections.CardinalDirection.UP:
            return has_flag(CEILING_WALKING)
        _:
            return has_flag(WALL_WALKING)

static func get_flag_name(flag: int, localized: bool = false) -> String:
    match flag:
        NONE: return __GlobalGameState.tr("TRANSPORTATION_MODE_NONE") if localized else "None"
        WALKING: return __GlobalGameState.tr("TRANSPORTATION_MODE_WALKING") if localized else "Walking"
        FLYING: return __GlobalGameState.tr("TRANSPORTATION_MODE_FLYING") if localized else "Flying"
        CLIMBING: return __GlobalGameState.tr("TRANSPORTATION_MODE_CLIMBING") if localized else "Climbing"
        WALL_WALKING: return __GlobalGameState.tr("TRANSPORTATION_MODE_WALL_WALKING") if localized else "Wall Walking"
        CEILING_WALKING: return __GlobalGameState.tr("TRANSPORTATION_MODE_CEILING_WALKING") if localized else "Ceiling Walking"
        SQUEEZING: return __GlobalGameState.tr("TRANSPORTATION_MODE_SQUEEZING") if localized else "Squeezing"
        SWIMMING: return __GlobalGameState.tr("TRANSPORTATION_MODE_SWIMMING") if localized else "Swimming"
        FALLING: return __GlobalGameState.tr("TRANSPORTATION_MODE_FALLING") if localized else "Falling"
        _:
            push_error("%s is not a transportation mode flag")
            print_stack()
            return __GlobalGameState.tr("TRANSPORTATION_MODE_UNKNOWN") if localized else "Unknown"

func get_flag_names(localized: bool = false) -> Array[String]:
    var flags: Array[String] = []

    for flag: int in ALL_FLAGS:
        if has_flag(flag):
            flags.append(get_flag_name(flag, localized))

    return flags

## Return of one transportation mode with another
func intersection(other: TransportationMode) -> int:
    return mode & other.mode

func humanize(localized: bool = false) -> String:
    return ", ".join(get_flag_names(localized))

static func create_from_direction(direction: CardinalDirections.CardinalDirection, fly_in_air: bool = true) -> TransportationMode:
    var new_mode: TransportationMode = TransportationMode.new()
    if CardinalDirections.is_planar_cardinal(direction):
        new_mode.set_flag(WALL_WALKING)
    elif direction == CardinalDirections.CardinalDirection.UP:
        new_mode.set_flag(CEILING_WALKING)
    elif direction == CardinalDirections.CardinalDirection.DOWN:
        new_mode.set_flag(WALKING)
    elif direction == CardinalDirections.CardinalDirection.NONE:
        if fly_in_air:
            new_mode.set_flag(FLYING)
        else:
            new_mode.set_flag(FALLING)

    return new_mode
