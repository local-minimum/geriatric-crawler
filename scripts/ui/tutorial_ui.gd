extends CanvasLayer
class_name TutorialUI

@export var outliner: TargetOutliner
@export var peephole: PeepHole
@export var box: PanelContainer
@export var box_label: Label
@export var next_btn: Button
@export var prev_btn: Button

func _ready() -> void:
    # _hide_parts()
    pass

var _tutorial_id: int = 0

var _on_next: Variant
var _on_prev: Variant

func show_tutorial(message: String, on_previous: Variant, on_next: Variant, targets: Array[Control], autohide_time: float = -1) -> void:
    box_label.text = message
    outliner.targets = targets

    _on_next = on_next
    _on_prev = on_previous

    next_btn.disabled = on_next is not Callable
    prev_btn.disabled = on_previous is not Callable

    var id : int = _tutorial_id
    if autohide_time > 0:
        await get_tree().create_timer(autohide_time).timeout
        if _tutorial_id == id && on_next is Callable:
            _hide_parts()
            @warning_ignore_start("unsafe_cast")
            (on_next as Callable).call()
            @warning_ignore_restore("unsafe_cast")

    box.show()
    peephole.show()
    outliner.show()

    print_debug("Tutorial: %s" % message)

func _hide_parts() -> void:
    box.hide()
    peephole.hide()
    outliner.hide()

func _on_next_button_pressed() -> void:
    _tutorial_id += 1
    _hide_parts()
    if _on_next is Callable:
        @warning_ignore_start("unsafe_cast")
        (_on_next as Callable).call()
        @warning_ignore_restore("unsafe_cast")

func _on_prev_button_pressed() -> void:
    _tutorial_id += 1
    _hide_parts()
    if _on_prev is Callable:
        @warning_ignore_start("unsafe_cast")
        (_on_prev as Callable).call()
        @warning_ignore_restore("unsafe_cast")
