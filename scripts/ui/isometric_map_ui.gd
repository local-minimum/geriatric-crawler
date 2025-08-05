extends Control
class_name IsometricMapUI

var _player: GridPlayer
var _seen: Array[Vector3i]

@export
var draw_box_half: Vector3i = Vector3i(3, 1, 3)

@export
var view_distance: float = 5:
    set(value):
        view_distance = value
        queue_redraw()

@export
var camera_direction: Vector3

@export
var floor_color: Color

@export
var illusion_color: Color

@export
var other_side_color: Color

@export_range(0, 1)
var elevation_difference_alpha_factor: float = 0.8

@export_range(0, 100)
var plane_to_canvas_scale: float = 1

func trigger_redraw(player: GridPlayer, seens_coordinates: Array[Vector3i]) -> void:
    _player = player
    _seen = seens_coordinates

    queue_redraw()

func _draw() -> void:
    if _player == null:
        return

    var level: GridLevel = _player.get_level()

    var cam_plane: Plane = _calculate_virtual_camera_plane()
    var cam_position: Vector3 = cam_plane.get_center()

    var node_half_size: Vector3 = Vector3.ONE * 0.5

    var center: Vector3i = _player.coordinates()
    var up: Vector3i = CardinalDirections.direction_to_vector(CardinalDirections.invert(_player.down))

    # We need plane up and plane right which can be done with some pitching and yawing the vector to the player
    var cam_plane_up: Vector3 = cam_plane.project(center + up).normalized()
    var cam_plane_right: Vector3 = cam_plane.normal.cross(cam_plane_up)

    var plane: Vector3i = CardinalDirections.direction_to_ortho_plane(_player.down)
    if VectorUtils.is_negative_cardinal_axis(up):
        plane *= -1

    var sign_flipped_plane: Vector3i = VectorUtils.flip_sign_first_non_null(plane)

    var area: Rect2 = get_rect()
    var area_center: Vector2 = area.get_center()

    var get_canvas_point: Callable = func(plane_position: Vector3) -> Vector2:
        var offset: Vector2 = Vector2(
            cam_plane_right.dot(plane_position - cam_position),
            cam_plane_up.dot(plane_position - cam_position))

        offset *= plane_to_canvas_scale
        return area_center + offset

    # print_debug("Redrawing isometric map with player at %s onto plane %s" % [center, cam_plane])

    for elevation_offset: int in range(-draw_box_half.y, draw_box_half.y + 1):
        var elevation_center: Vector3i = center + up * elevation_offset

        # print_debug("Drawing elevation %s" % elevation_center)

        for primary_offset: int in range(-draw_box_half.x, draw_box_half.x + 1):
            var primary: Vector3i = Vector3i.ZERO
            if plane.x != 0:
                primary.x = plane.x
            elif plane.y != 0:
                primary.y = plane.y
            else:
                primary.z = plane.z

            for secondary_offset: int in range(-draw_box_half.z, draw_box_half.z +1):
                var secondary: Vector3i = Vector3i.ZERO
                if primary.x != 0:
                    if plane.y != 0:
                        secondary.y = plane.y
                    else:
                        secondary.z = plane.z
                else:
                    secondary.z = plane.z

                var coords: Vector3i = elevation_center + primary * primary_offset + secondary * secondary_offset

                if !_seen.has(coords):
                    continue

                var node: GridNode = level.get_grid_node(coords)
                if node == null:
                    continue
                # Determine side type / color
                var color: Color
                var alpha_factor: float = elevation_difference_alpha_factor ** (1 + abs(elevation_offset))
                match node.has_side(_player.down):
                    GridNode.NodeSideState.SOLID:
                        color = floor_color
                        color.a *= alpha_factor
                    GridNode.NodeSideState.ILLUSORY:
                        if _seen.has(CardinalDirections.translate(coords, _player.down)):
                            color = illusion_color
                        else:
                            color = floor_color
                            color.a *= alpha_factor
                    _:
                        continue

                # 1. Get corners
                var side_center: Vector3 = (coords as Vector3) + (-up as Vector3) * node_half_size
                var corners: PackedVector3Array = [
                    side_center + (plane as Vector3) * node_half_size,
                    side_center + (sign_flipped_plane as Vector3) * node_half_size,
                    side_center + (plane as Vector3) * -node_half_size,
                    side_center + (sign_flipped_plane as Vector3) * -node_half_size,
                ]
                # 2. Check all positive side
                var over: Array[bool] = [
                    cam_plane.is_point_over(corners[0]),
                    cam_plane.is_point_over(corners[1]),
                    cam_plane.is_point_over(corners[2]),
                    cam_plane.is_point_over(corners[3]),
                ]

                # print_debug("%s floor has corners %s which are %s" % [coords, corners, over])

                var n_over: int = 0
                for is_over: bool in over:
                    if is_over:
                        n_over += 1

                # 2a. If none skip
                if n_over == 0:
                    continue

                # 2b. If one draw a triangle
                elif n_over == 1:
                    var pt: Vector3
                    var r1_target: Vector3
                    var r2_target: Vector3
                    if over[0]:
                        pt = corners[0]
                        r1_target = corners[1]
                        r2_target = corners[3]
                    elif over[1]:
                        pt = corners[1]
                        r1_target = corners[2]
                        r2_target = corners[0]
                    elif over[2]:
                        pt = corners[2]
                        r1_target = corners[3]
                        r2_target = corners[1]
                    else:
                        pt = corners[3]
                        r1_target = corners[0]
                        r2_target = corners[2]

                    corners = [
                        pt,
                        cam_plane.intersects_ray(pt, r1_target),
                        cam_plane.intersects_ray(pt, r2_target),
                    ]

                # 2c. If two draw a reduced rect
                elif n_over == 2:
                    if !over[0]:
                        if !over[1]:
                            corners[0] = cam_plane.intersects_ray(corners[0], corners[3] - corners[0])
                            corners[1] = cam_plane.intersects_ray(corners[1], corners[2] - corners[1])
                        # 3 must be below too
                        else:
                            corners[0] = cam_plane.intersects_ray(corners[0], corners[1] - corners[0])
                            corners[3] = cam_plane.intersects_ray(corners[3], corners[2] - corners[3])
                    # Since we are over on 0 must not be over on 2
                    elif !over[1]:
                        corners[1] = cam_plane.intersects_ray(corners[0], corners[1] - corners[0])
                        corners[2] = cam_plane.intersects_ray(corners[2], corners[3] - corners[2])
                    # can only be 2 and 3 below now
                    else:
                        corners[2] = cam_plane.intersects_ray(corners[2], corners[1] - corners[2])
                        corners[3] = cam_plane.intersects_ray(corners[3], corners[0] - corners[3])

                # 2e If not do intersections and draw polygon
                elif n_over == 3:
                    if !over[0]:
                        var pt1: Vector3 = cam_plane.intersects_ray(corners[0], corners[3] - corners[0])
                        var pt2: Vector3 = cam_plane.intersects_ray(corners[0], corners[1] - corners[0])
                        corners = [pt2, corners[1], corners[2], corners[3], pt1]
                    elif !over[1]:
                        var pt1: Vector3 = cam_plane.intersects_ray(corners[1], corners[0] - corners[1])
                        var pt2: Vector3 = cam_plane.intersects_ray(corners[1], corners[2] - corners[1])
                        corners = [corners[0], pt1, pt2, corners[2], corners[3]]
                    elif !over[2]:
                        var pt1: Vector3 = cam_plane.intersects_ray(corners[2], corners[1] - corners[2])
                        var pt2: Vector3 = cam_plane.intersects_ray(corners[2], corners[3] - corners[2])
                        corners = [corners[0], corners[1], pt1, pt2, corners[3]]
                    else:
                        var pt1: Vector3 = cam_plane.intersects_ray(corners[3], corners[2] - corners[3])
                        var pt2: Vector3 = cam_plane.intersects_ray(corners[3], corners[0] - corners[3])
                        corners = [corners[0], corners[1], corners[3], pt1, pt2]

                var points_valid: bool = true
                var points: PackedVector2Array = []
                @warning_ignore_start("return_value_discarded")
                points.resize(corners.size())
                @warning_ignore_restore("return_value_discarded")

                for idx: int in range(corners.size()):
                    # 3. Calculate plane 3D positions
                    # print_debug("projecting %s -> %s" % [corners[idx], cam_plane.project(corners[idx])])

                    corners[idx] = cam_plane.project(corners[idx])

                    # 4. Scale plane positions to canvas positions
                    var point: Variant = get_canvas_point.call(corners[idx])
                    if point is Vector2:
                        points[idx] = point
                    else:
                        push_error("Failed to append point %s of %s" % [corners[idx], coords])
                        points_valid = false
                        break

                if !points_valid:
                    push_error("Failed to draw %s" % coords)
                    continue

                # 5. Draw shape
                if points.size() > 4:
                    # print_debug("Drawing %s -> %s polygon %s" % [corners, points, coords])
                    draw_polygon(points, [color])
                else:
                    # print_debug("Drawing %s -> %s primitive %s" % [corners, points, coords])
                    draw_primitive(points, [color], [Vector2.ZERO])


func _calculate_virtual_camera_plane() -> Plane:
    var center: Vector3 = _player.coordinates()
    var up_offset: Vector3 = CardinalDirections.direction_to_look_vector(CardinalDirections.invert(_player.down))
    var offset_plane: Vector3 = CardinalDirections.direction_to_ortho_plane(_player.down)
    if VectorUtils.is_negative_cardinal_axis(up_offset):
        offset_plane *= -1

    up_offset *= camera_direction.y

    if offset_plane.x != 0:
        offset_plane.x *= camera_direction.x
        if offset_plane.y != 0:
            offset_plane.y *= camera_direction.z
        else:
            offset_plane.z *= camera_direction.z
    else:
        offset_plane.y *= camera_direction.x
        offset_plane.z *= camera_direction.z

    var offset: Vector3 = up_offset + offset_plane

    var cam_position: Vector3 = center + offset.normalized() * view_distance
    var cam_look_direction: Vector3 = center - cam_position

    print_debug("Plane construction from pos %s and normal %s" % [cam_position, cam_look_direction.normalized()])
    return Plane(
        cam_look_direction.normalized(),
        cam_position,
    )
