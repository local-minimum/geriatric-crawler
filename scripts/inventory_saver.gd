extends SaveExtension
class_name InventorySaver

@export
var _save_key: String = "exploration-inventory"

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(extentsion_save_data: Dictionary) -> Dictionary:
    if Inventory.active_inventory == null:
        return extentsion_save_data

    return Inventory.active_inventory.collect_save_data()

func initial_data(extentsion_save_data: Dictionary) -> Dictionary:
    return extentsion_save_data

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if Inventory.active_inventory == null:
        return

    if extentsion_save_data is Dictionary[String, float]:
        Inventory.active_inventory.load_from_save(extentsion_save_data)
    else:
        push_error("Couldn't load %s as %s inventory because it's not the expected type" % [extentsion_save_data, _save_key])
