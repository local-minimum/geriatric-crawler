extends SaveExtension
## Clears out an inventory in the save state when saving and transfers the content of loaded inventory into the active
class_name InventoryTransferSaver

@export
var _save_key: String = "exploration-inventory"

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if Inventory.active_inventory == null:
        return

    var inventory_data: Dictionary = DictionaryUtils.safe_getd(extentsion_save_data, _save_key)
    if inventory_data is Dictionary[String, float]:
        if Inventory.active_inventory.add_many_to_inventory(inventory_data):
            print_debug("inventory %s transferred into %s" % [_save_key, Inventory.active_inventory])
