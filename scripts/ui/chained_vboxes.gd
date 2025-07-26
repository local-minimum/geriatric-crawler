extends Container
class_name ChainedVBoxes

@export
var _boxes: Array[VBoxContainer]

@export
var _static_child_height: bool

func _process(_delta: float) -> void:
    for idx: int in range(_boxes.size()):
        var box: VBoxContainer = _boxes[idx]
        var next_box: VBoxContainer = _boxes[idx + 1] if idx + 1 < _boxes.size() else null

        if next_box == null:
            continue

        var n_children: int = box.get_child_count()

        if n_children == 0:
            if next_box.get_child_count() > 0:
                next_box.get_child(0).reparent(box, false)
            continue

        var last_child: Node = box.get_child(n_children - 1)
        if last_child is Control && _overflows((last_child as Control).get_global_rect()):
            last_child.reparent(next_box, false)
            continue

        var next_first_child: Node = next_box.get_child(0) if next_box.get_child_count() > 0 else null
        if next_first_child != null && next_first_child is Control:
            next_first_child.reparent(box, false)

func _overflows(rect: Rect2) -> bool:
    return get_global_rect().end.y < rect.end.y

func _scaled_height(box: VBoxContainer, rect: Rect2) -> float:
    var box_width: float = box.get_global_rect().size.x
    var r_size: Vector2 = rect.size
    return r_size.y * r_size.x / box_width

func _fits(box: VBoxContainer, last_child_rect: Rect2, new_rect: Rect2) -> bool:
    var extra_height: float = new_rect.size.y if _static_child_height else _scaled_height(box, new_rect)
    extra_height += box.get_theme_constant("separation")
    var box_end: float = box.get_global_rect().end.y
    var last_rect_end: float = last_child_rect.end.y

    return box_end - last_rect_end >= extra_height

func add_child_to_box(child: Control) -> void:
    var prev_box: VBoxContainer = null
    for idx: int in range(_boxes.size()):
        var box: VBoxContainer = _boxes[idx]
        if box.get_child_count() == 0:
            if prev_box == null:
                box.add_child(child)
            else:
                prev_box.add_child(child)

            return

        prev_box = box

    if prev_box != null:
        prev_box.add_child(child)
