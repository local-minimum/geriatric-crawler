extends SaveStorageProvider

@export
var save_file_pattern: String = "user://savegame%s.save"

func store_data(slot: int, save_data: Dictionary) -> bool:
    var save_file: FileAccess = FileAccess.open(save_file_pattern % slot, FileAccess.WRITE)
    if save_file != null:
        return save_file.store_line(JSON.stringify(save_data))

    push_error("Could not create file access '%s' with write permissions" % (save_file_pattern % slot))
    return false

func retrieve_data(slot: int) -> Dictionary:
    if !FileAccess.file_exists(save_file_pattern % slot):
        push_error("There is no file at '%s'" % (save_file_pattern % slot))
        return {}

    var save_file: FileAccess = FileAccess.open(save_file_pattern % slot, FileAccess.READ)

    if save_file == null:
        push_error("Could not open file at '%s' with read permissions" % (save_file_pattern % slot))
        return {}

    var json: JSON = JSON.new()
    if json.parse(save_file.get_line()) == OK:
        return json.data

    push_error("JSON corrupted in '%s'" % (save_file_pattern % slot))
    return {}
