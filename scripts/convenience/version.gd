extends Resource
class_name Version

@export
var _version: String

var _version_tuple: Array[int]
var _tuple_trail: String

func _parse() -> void:
    var r: RegEx = RegEx.new()
    if r.compile("(\\d+)\\.(\\d+).(\\d+)(.*)") != OK:
        push_error("Version parsing regex not correct")
        return

    var m: RegExMatch = r.search(_version)
    var major: int = m.get_string(1).to_int()
    var minor: int = m.get_string(2).to_int()
    var patch: int = m.get_string(3).to_int()
    _version_tuple = [major, minor, patch]
    _tuple_trail = m.get_string(4)

func set_version(version: String) -> void:
    _version = version
    _parse()

func get_version() -> String:
    return _version

func same(other: Version) -> bool:
    return _version_tuple == other._version_tuple && _tuple_trail == other._tuple_trail

func higher(other: Version) -> bool:
    if _version_tuple[0] < other._version_tuple[0]: return false
    if _version_tuple[1] < other._version_tuple[1]: return false
    if _version_tuple[2] < other._version_tuple[2]: return false

    if _tuple_trail < other._tuple_trail: return false

    return !same(other)

func higher_or_equal(other: Version) -> bool:
    if same(other):
        return true

    if _version_tuple[0] < other._version_tuple[0]: return false
    if _version_tuple[1] < other._version_tuple[1]: return false
    if _version_tuple[2] < other._version_tuple[2]: return false

    if _tuple_trail < other._tuple_trail: return false

    return true

func lower(other: Version) -> bool:
    if _version_tuple[0] > other._version_tuple[0]: return false
    if _version_tuple[1] > other._version_tuple[1]: return false
    if _version_tuple[2] > other._version_tuple[2]: return false

    if _tuple_trail > other._tuple_trail: return false

    return !same(other)

func lower_or_equal(other: Version) -> bool:
    if same(other):
        return true

    if _version_tuple[0] > other._version_tuple[0]: return false
    if _version_tuple[1] > other._version_tuple[1]: return false
    if _version_tuple[2] > other._version_tuple[2]: return false

    if _tuple_trail > other._tuple_trail: return false

    return true
