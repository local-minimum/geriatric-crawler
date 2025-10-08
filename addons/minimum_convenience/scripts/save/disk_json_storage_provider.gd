@tool
extends SaveStorageProvider

@export var save_file_pattern: String = "user://save_game_%s.json"

func _get_file_path(slot: int) -> String:
    if save_file_pattern.contains("%s"):
        return save_file_pattern % slot

    if slot > 0:
        push_warning("Save file pattern doesn't allow for mulitple slots, ignoring requested slot %s" % slot)

    return save_file_pattern

func store_data(slot: int, save_data: Dictionary) -> bool:
    var path: String = _get_file_path(slot)
    var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if save_file != null:
        var success: bool = save_file.store_line(JSON.stringify(JSON.from_native(save_data)))
        if success:
            print_debug("Saved to '%s' (asked for %s)" % [save_file.get_path_absolute(), path])
        return success

    push_error("Could not create file access '%s' with write permissions" % path)
    return false

func retrieve_data(slot: int = 0, warn_missing: bool = true) -> Dictionary:
    var path: String = _get_file_path(slot)
    if !FileAccess.file_exists(path):
        if warn_missing:
            push_warning("There is no file at '%s'" % path)
        return {}

    var save_file: FileAccess = FileAccess.open(path, FileAccess.READ)

    if save_file == null:
        push_error("Could not open file at '%s' with read permissions" % path)
        return {}

    var json: JSON = JSON.new()
    if json.parse(save_file.get_line()) == OK:
        return JSON.to_native(json.data)

    push_error("JSON corrupted in '%s'" % path)
    return {}
