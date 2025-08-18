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
@export_range(0, 1) var connector_anchor_pos: float = 0.1

var drawing: bool
var targets_global_rect: Rect2

signal on_redrawn

func _draw() -> void:
    var pos: Vector2 = Vector2.ZERO
    var end: Vector2 = Vector2.ZERO

    if targets.size() == 0:
        drawing = false
        on_redrawn.emit()
        return

    var first: bool = true
    for target: Control in targets:
        if target == null:
            continue

        var t_rect: Rect2 = target.get_global_rect()
        var t_pos: Vector2 = t_rect.position
        var t_end: Vector2 = t_rect.end

        if first:
            pos.x = min(t_pos.x, t_end.x)
            pos.y = min(t_pos.y, t_end.y)
            end.x = max(t_pos.x, t_end.x)
            end.y = max(t_pos.y, t_end.y)
            first = false
        else:
            pos.x = min(t_pos.x, t_end.x, pos.x)
            pos.y = min(t_pos.y, t_end.y, pos.y)
            end.x = max(t_pos.x, t_end.x, end.x)
            end.y = max(t_pos.y, t_end.y, end.y)

    pos -= Vector2.ONE * margin
    end += Vector2.ONE * margin

    targets_global_rect = Rect2(pos, end - pos)

    pos = get_global_transform().affine_inverse().basis_xform(pos)
    end = get_global_transform().affine_inverse().basis_xform(end)

    var outline_corners: Array[Vector2] = [
        pos,
        Vector2(pos.x, end.y),
        end,
        Vector2(end.x, pos.y),
    ]

    # Outliner
    draw_polyline([outline_corners[0], outline_corners[1], outline_corners[2], outline_corners[3], outline_corners[0]], line_color, width)

    if source != null:
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

        outline_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return (
                    min(
                        a.distance_squared_to(source_corners[0]),
                        a.distance_squared_to(source_corners[1]),
                        a.distance_squared_to(source_corners[2]),
                        a.distance_squared_to(source_corners[3]),
                    ) <
                    min(
                        b.distance_squared_to(source_corners[0]),
                        b.distance_squared_to(source_corners[1]),
                        b.distance_squared_to(source_corners[2]),
                        b.distance_squared_to(source_corners[3]),
                    )
                )
        )

        source_corners.sort_custom(
            func (a: Vector2, b: Vector2) -> bool:
                return (
                    min(
                        a.distance_squared_to(outline_corners[0]),
                        a.distance_squared_to(outline_corners[1]),
                        a.distance_squared_to(outline_corners[2]),
                        a.distance_squared_to(outline_corners[3]),
                    ) <
                    min(
                        b.distance_squared_to(outline_corners[0]),
                        b.distance_squared_to(outline_corners[1]),
                        b.distance_squared_to(outline_corners[2]),
                        b.distance_squared_to(outline_corners[3]),
                    )
                )
        )

        var from: Vector2 = outline_corners[0].lerp(outline_corners[1], connector_anchor_pos)
        var to: Vector2 = source_corners[0].lerp(source_corners[1], connector_anchor_pos)

        if to.x == from.x || to.y == from.y:
            # Connector is straight line
            draw_line(
                from,
                to,
                line_color,
                connector_width,
            )
        else:
            var outline_side: Vector2 = outline_corners[0] - outline_corners[1]
            var source_side: Vector2 = source_corners[0] - source_corners[1]

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
    on_redrawn.emit()

func _process(_delta: float) -> void:
    if live:
        queue_redraw()
