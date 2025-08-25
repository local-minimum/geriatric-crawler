extends Node
class_name ExplorationInventoryUI

@export var _chained_boxes: ChainedVBoxes

var _previous_labels: Array[Control]

func list_inventory() -> void:
    for label: Control in _previous_labels:
        label.queue_free()
    _previous_labels.clear()

    if Inventory.active_inventory == null:
        push_warning("There's no active inventory so nothing to show")
        return

    for listing: Inventory.InventoryListing in Inventory.active_inventory.list_inventory():
        var label: RichTextLabel = RichTextLabel.new()
        label.scroll_active = false
        label.bbcode_enabled = true
        label.fit_content = true
        label.text = "[b]%s[/b][p align=right][code]%1.2f %s[/code][/p]" % [
            Inventory.inventory_item_id_to_text(listing.id),
            listing.amount,
            Inventory.inventory_item_id_to_unit(listing.id),
        ]

        _previous_labels.append(label)
        _chained_boxes.add_child_to_box(label)
