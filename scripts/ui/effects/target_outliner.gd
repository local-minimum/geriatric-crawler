extends Control
class_name TargetOutliner

@export var source: Control:
    set (value):
        source = value
        queue_redraw()

@export var targets: Array[Control]:
    set(values):
        targets = values
        queue_redraw()

@export var line_color: Color
@export var margin: float = 2
@export var width: float = 1.0
@export var live: bool = false
@export var connector_width: float = 1.0
@export var connector_anchor_radius: float = 0
@export var connector_min_distance: float = 15
@export_range(0, 1) var connector_anchor_pos: float = 0.1

var drawing: bool
var targets_global_rect: Rect2
var final_targets_global_rect: Rect2

var pos: Vector2
var end: Vector2

var tweening: bool
var post_tweeing: bool
var tween_start: float
var tween_duration: float

signal on_redrawn(tween_progress: float)

func _ready() -> void:
    reset_outlining()

func reset_outlining() -> void:
    pos = get_viewport_rect().size / 2
    end = pos
    if !live:
        targets = []

func _draw() -> void:
    var new_pos: Vector2 = Vector2.ZERO
    var new_end: Vector2 = Vector2.ZERO

    if targets.size() == 0:
        drawing = false
        on_redrawn.emit(1)
        return

    var first: bool = true
    for target: Control in targets:
        if target == null:
            continue

        var t_rect: Rect2 = target.get_global_rect()
        var t_pos: Vector2 = t_rect.position
        var t_end: Vector2 = t_rect.end

        if first:
            new_pos.x = min(t_pos.x, t_end.x)
            new_pos.y = min(t_pos.y, t_end.y)
            new_end.x = max(t_pos.x, t_end.x)
            new_end.y = max(t_pos.y, t_end.y)
            first = false
        else:
            new_pos.x = min(t_pos.x, t_end.x, new_pos.x)
            new_pos.y = min(t_pos.y, t_end.y, new_pos.y)
            new_end.x = max(t_pos.x, t_end.x, new_end.x)
            new_end.y = max(t_pos.y, t_end.y, new_end.y)

    # No valid target
    if first:
        drawing = false
        on_redrawn.emit(1)
        return

    new_pos -= Vector2.ONE * margin
    new_end += Vector2.ONE * margin
    final_targets_global_rect = Rect2(new_pos, new_end - new_pos)

    var progress: float = 1
    if tweening:
        progress = clampf((Time.get_ticks_msec() - tween_start) / tween_duration, 0, 1)
        tweening = progress < 1
        new_pos = pos.lerp(new_pos, progress)
        new_end = end.lerp(new_end, progress)

    if !tweening:
        pos = new_pos
        end = new_end

    targets_global_rect = Rect2(new_pos, new_end - new_pos)

    new_pos = get_global_transform().affine_inverse().basis_xform(new_pos)
    new_end = get_global_transform().affine_inverse().basis_xform(new_end)

    var outline_corners: Array[Vector2] = [
        new_pos,
        Vector2(new_pos.x, new_end.y),
        new_end,
        Vector2(new_end.x, new_pos.y),
    ]

    # Outliner
    draw_polyline([outline_corners[0], outline_corners[1], outline_corners[2], outline_corners[3], outline_corners[0]], line_color, width)

    if source != null && progress == 1 && !post_tweeing:
        # Connector line
        var s_rect: Rect2 = source.get_global_rect()
        var s_pos: Vector2 = s_rect.position
        var s_end: Vector2 = s_rect.end
        var source_corners: Array[Vector2] = [
            s_pos,
            Vector2(s_pos.x, s_end.y),
            s_end,
            Vector2(s_end.x, s_pos.y),
        ]

        var s_center: Vector2 = s_rect.get_center()

        outline_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return a.distance_squared_to(s_center) < b.distance_squared_to(s_center)
        )

        var outline_best: Vector2 = outline_corners[0]

        outline_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return a.distance_squared_to(outline_best) < b.distance_squared_to(outline_best)
        )

        source_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return a.distance_squared_to(outline_corners[0]) < b.distance_squared_to(outline_corners[0])
        )


        var d: Vector2 = source_corners[0] - outline_corners[0]
        var outline_idx2: int = 1 if absf(d.dot(outline_corners[1] - outline_corners[0])) > absf(d.dot(outline_corners[2] - outline_corners[0])) else 2

        var from: Vector2 = outline_corners[0].lerp(
            outline_corners[outline_idx2],
            connector_anchor_pos,
        )

        source_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return a.distance_squared_to(from) < b.distance_squared_to(from)
        )

        var d1: float = VectorUtils.inv_chebychev_distance2f(from, source_corners[1])
        var d2: float = VectorUtils.inv_chebychev_distance2f(from, source_corners[2])
        var source_idx2: int = 1
        if d1 < connector_min_distance:
            source_idx2 = 2
        elif d2 < connector_min_distance:
            source_idx2 = 1
        elif d1 < d2:
            source_idx2 = 1
        else:
            source_idx2 = 2

        var to: Vector2 = source_corners[0].lerp(source_corners[source_idx2], connector_anchor_pos)

        if to.x == from.x || to.y == from.y:
            # Connector is straight line
            draw_line(
                from,
                to,
                line_color,
                connector_width,
            )
        else:
            var outline_side: Vector2 = outline_corners[0] - outline_corners[outline_idx2]
            var source_side: Vector2 = source_corners[0] - source_corners[source_idx2]

            # Orthogonal sides makes elbow
            if source_side.x == 0 && outline_side.y == 0 || source_side.y == 0 && outline_side.x == 0:
                var mid: Vector2 = Vector2(to.x, from.y) if outline_side.x == 0 else Vector2(from.x, to.y)
                draw_polyline([from, mid, to], line_color, connector_width)

            # Parallell lines need Z shape
            else:
                var horizontal_sides: bool = source_side.x == 0
                var mid: Vector2 = from.lerp(to, 0.5)
                var m1: Vector2 = Vector2(mid.x, from.y) if horizontal_sides else Vector2(from.x, mid.y)
                var m2: Vector2 = Vector2(mid.x, to.y) if horizontal_sides else Vector2(to.x, mid.y)
                draw_polyline([from, m1, m2, to], line_color, connector_width)


        if connector_anchor_radius > 0:
            draw_circle(from, connector_anchor_radius, line_color)
            draw_circle(to, connector_anchor_radius, line_color)

    drawing = true
    # print_debug("Draw outline")
    on_redrawn.emit(progress)

func _process(_delta: float) -> void:
    if visible && live || tweening || post_tweeing:
        if !tweening && post_tweeing:
            post_tweeing = false
            await get_tree().create_timer(0.1).timeout
        queue_redraw()

func tween_to(new_targets: Array[Control], duration_seconds: float) -> void:
    tweening = true
    post_tweeing = true
    tween_start = Time.get_ticks_msec()
    tween_duration = duration_seconds * 1000
    targets = new_targets

func snap_to(new_targets: Array[Control]) -> void:
    tweening = false
    post_tweeing = false
    targets = new_targets
