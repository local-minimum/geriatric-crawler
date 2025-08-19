extends Control
class_name PeepHole

@export var outliner: TargetOutliner
@export var color: Color

func _ready() -> void:
    if outliner.on_redrawn.connect(_handle_redrawn) != OK:
        push_error("Could not connect outliner redrawn")
    _handle_redrawn()

func _handle_redrawn(_tween_progress: float = 1.0) -> void:
    if outliner.drawing:
        show()
        queue_redraw()
    else:
        hide()

func _draw() -> void:
    var hole: Rect2 = outliner.targets_global_rect
    var t: Transform2D = get_global_transform().affine_inverse()
    var hole_pos: Vector2 = t.basis_xform(hole.position)
    var hole_end: Vector2 = t.basis_xform(hole.end)
    var origin: Vector2 = t.basis_xform(Vector2.ZERO)
    var view_size: Vector2 = t.basis_xform(get_viewport_rect().size)
    var ur: Vector2 = t.basis_xform(Vector2(get_viewport_rect().size.x, 0))
    var ll: Vector2 = t.basis_xform(Vector2(0, get_viewport_rect().size.y))

    if hole.has_point(Vector2.ZERO):
        draw_rect(Rect2(Vector2(hole_end.x, origin.y) , view_size - Vector2(hole_end.x, origin.y)), color)
        draw_rect(Rect2(Vector2(origin.x, hole_end.y), Vector2(hole_end.x - origin.x, view_size.y - hole_end.y)), color)
    elif hole.has_point(ur):
        draw_rect(Rect2(origin , Vector2(hole_pos.x - origin.x, view_size.y - origin.y)), color)
        draw_rect(Rect2(Vector2(hole_pos.x, hole_end.y), view_size - Vector2(hole_pos.x, hole_end.y)), color)
    elif hole.has_point(view_size):
        print_debug("Draw peep 3")
        draw_rect(Rect2(origin , Vector2(hole_pos.x - origin.x, view_size.y - origin.y)), color)
        draw_rect(Rect2(Vector2(hole_pos.x, origin.y), view_size - Vector2(hole_pos.x, origin.y)), color)
    elif hole.has_point(ll):
        draw_rect(Rect2(origin , Vector2(hole_end.x, hole_pos.y) - origin), color)
        draw_rect(Rect2(Vector2(hole_end.x, origin.y), Vector2(view_size.x - hole_end.x, view_size.y - origin.y)), color)
    else:
        if hole_pos.y > origin.y:
            draw_rect(Rect2(origin, Vector2(size.x - origin.x, hole_pos.y - origin.y)), color)
        if hole_pos.x > origin.x:
            draw_rect(Rect2(Vector2(origin.x, hole_pos.y), Vector2(hole_pos.x - origin.x, hole_end.y - hole_pos.y)), color)
        if hole_end.x < view_size.x:
            draw_rect(Rect2(Vector2(hole_end.x, hole_pos.y), Vector2(view_size.x - hole_end.x, hole_end.y - hole_pos.y)), color)
        if hole_end.y < view_size.y:
            draw_rect(Rect2(Vector2(origin.x, hole_end.y), Vector2(view_size.x - origin.x, view_size.y - hole_end.y)), color)
