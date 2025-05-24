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

@export_flags("Walking", "Flying", "Climbing", "Wall Walking", "Ceiling Walking", "Squeezing", "Swimming")
var mode: int = 0

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
