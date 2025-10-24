extends Node
class_name ExplorationInventoryUI

@export var _chained_boxes: ChainedVBoxes

var _inv: Inventory.InventorySubscriber
var _need_to_update_listing: bool

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()
    if __SignalBus.on_load_inventory.connect(_handle_inventory_loaded) != OK:
        push_error("Failed to connect inventory loaded")
    if __SignalBus.on_add_to_inventory.connect(_handle_add_to_inventory) != OK:
        push_error("Failed to connect inventory item added")
    if __SignalBus.on_remove_from_inventory.connect(_handle_remove_from_inventory) != OK:
        push_error("Failed to connect inventory item added")
    _need_to_update_listing = true

func _handle_add_to_inventory(inventory: Inventory, _id: String, _amount: float, _total: int) -> void:
    if inventory == _inv.inventory:
        _need_to_update_listing = true

func _handle_remove_from_inventory(inventory: Inventory, _id: String, _amount: float, _total: int) -> void:
    if inventory == _inv.inventory:
        _need_to_update_listing = true

func _handle_inventory_loaded(inventory: Inventory) -> void:
    if inventory != _inv.inventory:
        return

    _need_to_update_listing = true
    list_inventory()

func list_inventory() -> void:
    if !_need_to_update_listing:
        return

    _chained_boxes.clear_boxes()

    if _inv.inventory == null:
        push_warning("There's no active inventory so nothing to show")
        return

    _list_inventory.call_deferred()

func _list_inventory() -> void:
    for listing: Inventory.InventoryListing in _inv.inventory.list_inventory():
        var label: RichTextLabel = RichTextLabel.new()
        label.scroll_active = false
        label.bbcode_enabled = true
        label.fit_content = true
        label.text = "[b]%s[/b][p align=right][code]%1.2f %s[/code][/p]" % [
            GCLootableManager.translate(listing.id),
            listing.amount,
            GCLootableManager.unit(listing.id),
        ]
        label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED

        _chained_boxes.add_child_to_box(label)

    _need_to_update_listing = false
