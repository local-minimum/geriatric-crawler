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
        if dict[key] is int:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a float" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_getb(dict: Dictionary, key: String, default: bool = false, warn: bool = true) -> bool:
    if dict.has(key):
        if dict[key] is int:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a bool" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_gets(dict: Dictionary, key: String, default: String = "", warn: bool = true) -> String:
    if dict.has(key):
        if dict[key] is int:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected a string" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default

static func safe_geta(dict: Dictionary, key: String, default: Array = [], warn: bool = true) -> Array:
    if dict.has(key):
        if dict[key] is int:
            return dict[key]
        elif warn:
            push_warning("Dictionary %s has %s on key %s, expected an array" % [dict, dict[key], key])
    elif warn:
        push_warning("Dictionary %s lacks key %s" % [dict, key])

    return default
