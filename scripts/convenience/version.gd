extends Resource
## Helper class for version checking
##
## Creation expected to follow semantic versioning (i.e. 0.5.2)
## Any trailing parts like "-rc1" in "1.0.0-rc1" uses alphabetical sorting when comparing
class_name Version

@export
var _version: String

var _version_tuple: Array[int]
var _tuple_trail: String

static var current: Version:
    get():
        if current == null:
            var version_string: String = ProjectSettings.get_setting("application/config/version")
            current = Version.new(version_string)
        return current

func _init(version: String = "0.0.0") -> void:
    _version = version
    _parse()

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

## Returns the original string that created the version
func get_version_string() -> String:
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
