extends Node
class_name ExplorationInventoryUI

@export
var columns: Array[Control] = []

@export
var rows_per_column: int = 8

var _previous_labels: Array[Control]

func list_inventory() -> void:
    for label: Control in _previous_labels:
        label.queue_free()
    _previous_labels.clear()

    if Inventory.active_inventory == null:
        push_warning("There's no active inventory so nothing to show")
        return

    var col_idx: int = 0
    var col_child_count: int = 0
    var column: Control = columns[col_idx]

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

        col_child_count += 1
        column.add_child(label)
        if col_child_count >= rows_per_column && col_idx + 1 < columns.size():
            col_child_count = 0
            col_idx += 1
            column = columns[col_idx]
