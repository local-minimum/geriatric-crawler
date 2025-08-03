extends Node
class_name KeyRing

var _keys: Dictionary[String, int]

func has_key(key: String) -> bool:
    return _keys.get(key, 0) > 0

func consume_key(key: String) -> bool:
    if has_key(key):
        _keys[key] -= 1
        return true
    return false

func gain(key: String, amount: int = 1) -> void:
    if _keys.has(key):
        _keys[key] += amount
    else:
        _keys[key] = amount

func collect_save_data() -> Dictionary[String, int]:
    return _keys.duplicate()

func load_from_save(data: Variant) -> void:
    if data is Dictionary[String, int]:
        @warning_ignore_start("unsafe_cast")
        _keys = (data as Dictionary[String, int]).duplicate()
        @warning_ignore_restore("unsafe_cast")
