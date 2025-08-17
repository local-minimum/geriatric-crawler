class_name UIUtils

static func clear_control(control: Control) -> void:
    for child_idx: int in range(control.get_child_count()):
        control.get_child(child_idx).queue_free()
