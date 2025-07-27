extends Container
class_name ChainedVBoxes

enum _Check { NOTHING, GROWTH, SHRINKAGE, HAS_SPACE, STAYS }

@export
var _boxes: Array[VBoxContainer]

@export
var _static_child_height: bool

var _check: Dictionary[VBoxContainer, _Check]

func _get_last_control(box: VBoxContainer) -> Control:
    for idx: int in range(box.get_child_count() - 1, -1, -1):
        var child: Node = box.get_child(idx)
        if child is Control:
            return child as Control

    return null

func _get_first_control(box: VBoxContainer) -> Control:
    for idx: int in range(box.get_child_count()):
        var child: Node = box.get_child(idx)
        if child is Control:
            return child as Control

    return null

func _process(_delta: float) -> void:
    if !is_visible_in_tree():
        return

    _do_height_checks()

func _old_reparenting() -> void:
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

var _heights: Dictionary[VBoxContainer, float]

func _do_height_checks() -> void:
    var idx: int = 0
    for box: VBoxContainer in _boxes:
        if _check.has(box):
            match _check[box]:
                _Check.GROWTH:
                    if !_check_growth(box, idx):
                        return

                _Check.SHRINKAGE:
                    if !_check_shrinkage(box, idx):
                        return

                _Check.HAS_SPACE:
                    if !_check_has_space(box, idx):
                        return

                _Check.STAYS:
                    if !_check_stays(box, idx):
                        return
        idx += 1

    if _waiting.size() > 0:
        var child: Control = _waiting[0]
        if _add_child(child):
            _waiting.erase(child)

func _reset_box_height_check(box: VBoxContainer) -> void:
    _check[box] = _Check.NOTHING

    @warning_ignore_start("return_value_discarded")
    _heights.erase(box)
    @warning_ignore_restore("return_value_discarded")

func _move_last_to_next_box(box: VBoxContainer, idx: int) -> bool:
    if idx + 1 >= _boxes.size():
        return false

    var next_box: VBoxContainer = _boxes[idx + 1]
    var last_child: Node = _get_last_control(box)

    if last_child == null:
        _reset_box_height_check(box)
        return false

    if !_heights.has(next_box):
        _heights[next_box] = next_box.get_global_rect().size.y
    _check[next_box] = _Check.GROWTH

    last_child.reparent(next_box, false)
    next_box.move_child(last_child, 0)

    return true

func _move_first_in_next_to_me(box: VBoxContainer, idx: int) -> bool:
    if idx + 1 >= _boxes.size():
        return false

    var next_box: VBoxContainer = _boxes[idx + 1]
    var first_child: Node = _get_first_control(next_box)

    if first_child == null:
        _reset_box_height_check(box)
        return false

    if !_heights.has(next_box):
        _heights[next_box] = next_box.get_global_rect().size.y
    _check[next_box] = _Check.HAS_SPACE

    first_child.reparent(box, false)
    box.move_child(first_child, box.get_child_count() - 1)

    return true

func _check_growth(box: VBoxContainer, idx: int) -> bool:
    if !_heights.has(box):
        _reset_box_height_check(box)
        # print_debug("Box %s growth check didn't have any recorded height" % box)
        return true

    if box.get_global_rect().size.y <= _heights[box]:
        # print_debug("Box %s growth check didn't grow (%s vs %s)" % [box, box.get_global_rect().size.y, _heights[box]])
        _reset_box_height_check(box)
        return true

    if _move_last_to_next_box(box, idx):
        # print_debug("Box %s grew from %s and moved last child to next" % [box, _heights[box]])
        _check[box] = _Check.SHRINKAGE
        return false

    # print_debug("Box %s grew but couldn't move anything to next box" % box)
    return true

func _check_shrinkage(box: VBoxContainer, idx: int) -> bool:
    if !_heights.has(box):
        _reset_box_height_check(box)
        # print_debug("Box %s shrink check didn't have any recorded height" % box)
        return true

    var height: float = box.get_global_rect().size.y
    if height < _heights[box]:
        # Move one back and see if height stays...
        # print_debug("Box %s shrink check says we're below size (%s vs %s)" % [box, box.get_global_rect().size.y, _heights[box]])
        if _move_first_in_next_to_me(box, idx):
            # print_debug("Box %s shrink grabbed a child and will do stay check" % box)
            _heights[box] = box.get_global_rect().size.y
            _check[box] = _Check.STAYS
            return false

        # print_debug("Box %s shrink check is done" % box)
        _reset_box_height_check(box)
        return true

    if height == _heights[box]:
        # print_debug("Box %s shrunk to max height" % box)
        _reset_box_height_check(box)
        return true

    if _move_last_to_next_box(box, idx):
        # print_debug("Box %s shrink moved another child" % box)
        return false

    _reset_box_height_check(box)
    # print_debug("Box %s shrink could not move to next" % box)
    return true


func _check_stays(box: VBoxContainer, idx: int) -> bool:
    if !_heights.has(box):
        # print_debug("Box %s stay has not height" % box)
        _reset_box_height_check(box)
        return true

    if box.get_global_rect().size.y == _heights[box]:
        # print_debug("Box %s stay kept height" % box)
        _reset_box_height_check(box)
        return true

    if _move_last_to_next_box(box, idx):
        # print_debug("Box %s stay moved back one child" % box)
        _reset_box_height_check(box)
        return false

    # print_debug("Box %s stay could take no action" % box)
    _reset_box_height_check(box)
    return true

func _check_has_space(box: VBoxContainer, idx: int) -> bool:
    var last_child: Control = _get_last_control(box)
    if !_heights.has(box):
        _heights[box] = box.get_global_rect().size.y

    if last_child == null:
        if _move_first_in_next_to_me(box, idx):
            # print_debug("Box %s has space had no child but got one" % box)
            _check[box] = _Check.GROWTH
            return false

        # print_debug("Box %s has space had no child, end check" % box)
        _reset_box_height_check(box)
        return true

    var child_y: float = last_child.get_global_rect().end.y
    var rect: Rect2 = box.get_global_rect()
    if child_y == rect.end.y:
        # print_debug("Box %s has space perfectly filled up, end check" % box)
        _reset_box_height_check(box)
        return true

    if sign(child_y - rect.position.y) == sign(child_y - rect.end.y):
        if _move_last_to_next_box(box, idx):
            _check[box] = _Check.SHRINKAGE
            # print_debug("Box %s has space overflows, moved child to next" % box)
            return false

        # print_debug("Box %s has space overflows, ends check" % box)
        _reset_box_height_check(box)
        return true

    if _move_first_in_next_to_me(box, idx):
        # print_debug("Box %s has space does and got a child from next" % box)
        _check[box] = _Check.GROWTH
        return false

    # print_debug("Box %s has space does but got no child" % box)
    _reset_box_height_check(box)
    return true


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

var _waiting: Array[Control]

func add_child_to_box(child: Control) -> void:
    if _check.values().any(func (c: _Check) -> bool: return c != _Check.NOTHING):
        _waiting.append(child)
        return

    if !_add_child(child):
        _waiting.append(child)

func _add_child(child: Control) -> bool:
    var prev_box: VBoxContainer = null
    for idx: int in range(_boxes.size()):
        var box: VBoxContainer = _boxes[idx]
        if box.get_global_rect().size.y == 0:
            prev_box = null
            continue

        if box.get_child_count() == 0:
            if prev_box == null:
                _heights[box] = box.get_global_rect().size.y
                box.add_child(child)
                _check[box] = _Check.GROWTH
            else:
                _heights[prev_box] = prev_box.get_global_rect().size.y
                prev_box.add_child(child)
                _check[prev_box] = _Check.GROWTH
            return true

        prev_box = box

    if prev_box != null:
        prev_box.add_child(child)
        return true

    return false
