class_name UIUtils

static func clear_control(control: Control) -> void:
    for child_idx: int in range(control.get_child_count()):
        control.get_child(child_idx).queue_free()

static func get_last_control(control: Control) -> Control:
    for idx: int in range(control.get_child_count() - 1, -1, -1):
        var child: Node = control.get_child(idx)
        if child is Control:
            return child as Control

    return null

static func get_first_control(control: Control) -> Control:
    for idx: int in range(control.get_child_count()):
        var child: Node = control.get_child(idx)
        if child is Control:
            return child as Control

    return null
