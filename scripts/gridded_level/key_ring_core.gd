extends Node
class_name KeyRingCore

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
        NotificationsManager.info(tr("NOTICE_KEYRING"), tr("GAINED_KEY_COUNT").format({"key": KeyMasterCore.instance.get_description(key), "amount": amount}))
    else:
        _keys[key] = amount
        NotificationsManager.important(tr("NOTICE_KEYRING"), tr("GAINED_NEW_KEY_COUNT").format({"key": KeyMasterCore.instance.get_description(key), "amount": amount}))

func collect_save_data() -> Dictionary[String, int]:
    return _keys.duplicate()

func load_from_save(data: Variant) -> void:
    if data is Dictionary[String, int]:
        @warning_ignore_start("unsafe_cast")
        _keys = (data as Dictionary[String, int]).duplicate()
        @warning_ignore_restore("unsafe_cast")

func all() -> Dictionary[String, int]:
    return _keys.duplicate()
