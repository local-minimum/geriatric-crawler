extends SaveExtension
## Clears out an inventory in the save state when saving and transfers the content of loaded inventory into the active
class_name InventoryTransferSaver

@export var _save_key: String = "exploration-inventory"

var _inv: Inventory.InventorySubscriber
var _loadout: Dictionary[String, float]

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()

func _ready() -> void:
    if __SignalBus.on_finalize_loadout.connect(_handle_loadout) != OK:
        push_error("Failed to connect finalize loadout")

func _handle_loadout(loadout: Dictionary[String, float]) -> void:
    _loadout = loadout

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return _loadout

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if _inv.inventory == null:
        push_warning("[Inventory Transfer Saver] there's no registered inventory to recieve %s" % extentsion_save_data)
        return

    if extentsion_save_data is Dictionary[String, float]:
        if _inv.inventory.add_many_to_inventory(extentsion_save_data):
            print_debug("[Inventory Transfer Saver] %s transferred into %s" % [extentsion_save_data, _inv.inventory])
