extends Control
class_name ExplorationKeysUI

@export
var _chained_boxes: ChainedVBoxes

var _previous_keys: Array[Control]

func list_keys(key_ring: KeyRing) -> void:
    for key: Control in _previous_keys:
        key.queue_free()

    _previous_keys.clear()

    var keys: Dictionary[String, int] = key_ring.all()

    for key_id: String in keys:
        var label: RichTextLabel = RichTextLabel.new()
        label.scroll_active = false
        label.bbcode_enabled = true
        label.fit_content = true
        label.text = "[b]%s[/b][p align=right][code]%s[/code][/p]" % [
            KeyMasterCore.instance.get_description(key_id),
            keys[key_id],
        ]
        label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED

        _previous_keys.append(label)
        _chained_boxes.add_child_to_box(label)
