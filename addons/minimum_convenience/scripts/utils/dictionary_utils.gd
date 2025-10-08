class_name DictionaryUtils

static func safe_geti(dict: Dictionary, key: String, default: int = 0, warn: bool = true) -> int:
    if dict.has(key):
        if dict[key] is int:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected an int" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_getf(dict: Dictionary, key: String, default: float = 0, warn: bool = true) -> float:
    if dict.has(key):
        if dict[key] is float:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a float" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_getb(dict: Dictionary, key: String, default: bool = false, warn: bool = true) -> bool:
    if dict.has(key):
        if dict[key] is bool:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a bool" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_gets(dict: Dictionary, key: String, default: String = "", warn: bool = true) -> String:
    if dict.has(key):
        if dict[key] is String:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a string" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_getv3i(dict: Dictionary, key: String, default: Vector3i = Vector3i.ZERO, warn: bool = true) -> Vector3i:
    if dict.has(key):
        if dict[key] is Vector3i:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected an vector 3i" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_geta(dict: Dictionary, key: String, default: Array = [], warn: bool = true) -> Array:
    if dict.has(key):
        if dict[key] is Array:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected an array" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_getd(dict: Dictionary, key: String, default: Dictionary = {}, warn: bool = true) -> Dictionary:
    if dict.has(key):
        if dict[key] is Dictionary:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a dictionary" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_get_packed_string_array(dict: Dictionary, key: String, default: PackedStringArray = [], warn: bool = true) -> PackedStringArray:
    if dict.has(key):
        if dict[key] is PackedStringArray:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a PackedStringArray" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default
