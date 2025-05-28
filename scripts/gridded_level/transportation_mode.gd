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

const ALL_FLAGS: Array[int] = [WALKING, FLYING, CLIMBING, WALL_WALKING, CEILING_WALKING, SQUEEZING, SWIMMING]

const EXOTIC_WALKS: Array[int] = [WALL_WALKING, CEILING_WALKING]

@export_flags("Walking", "Flying", "Climbing", "Wall Walking", "Ceiling Walking", "Squeezing", "Swimming")
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

static func get_flag_name(flag: int) -> String:
    match flag:
        NONE: return "None"
        WALKING: return "Walking"
        FLYING: return "Flying"
        CLIMBING: return "Climbing"
        WALL_WALKING: return "Wall Walking"
        CEILING_WALKING: return "Ceiling Walking"
        SQUEEZING: return "Squeezing"
        SWIMMING: return "Swimming"
        _:
            push_error("%s is not a transportation mode flag")
            print_stack()
            return ""

func get_flag_names() -> Array[String]:
    var flags: Array[String] = []

    for flag: int in ALL_FLAGS:
        if has_flag(flag):
            flags.append(get_flag_name(flag))

    return flags

## Return of one transportation mode with another
func intersection(other: TransportationMode) -> int:
    return mode & other.mode

func humanize() -> String:
    return ", ".join(get_flag_names())
