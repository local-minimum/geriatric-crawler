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

@export
var player_color: Color

@export_range(0, 1)
var elevation_difference_alpha_factor: float = 0.8

@export_range(0, 200)
var to_canvas_scaling: float = 30

@export_range(0, 1)
var line_width: float = 0.05

func trigger_redraw(player: GridPlayer, seens_coordinates: Array[Vector3i]) -> void:
    _player = player
    _seen = seens_coordinates

    queue_redraw()

var cam_position: Vector3

func _draw() -> void:
    if _player == null:
        return

    var level: GridLevel = _player.get_level()

    var node_half_size: Vector3 = Vector3.ONE * 0.47

    var player_coordinates: Vector3i = _player.coordinates()
    var player_up: Vector3i = CardinalDirections.direction_to_vectori(CardinalDirections.invert(_player.down))

    var elevation_plane: Vector3i = CardinalDirections.direction_to_ortho_plane(_player.down)
    if VectorUtils.is_negative_cardinal_axis(player_up):
        elevation_plane *= -1

    var primary: Vector3i = Vector3i.ZERO
    if elevation_plane.x != 0:
        primary.x = elevation_plane.x
    elif elevation_plane.y != 0:
        primary.y = elevation_plane.y
    else:
        primary.z = elevation_plane.z

    var secondary: Vector3i = Vector3i.ZERO
    if primary.x != 0:
        if elevation_plane.y != 0:
            secondary.y = elevation_plane.y
        else:
            secondary.z = elevation_plane.z
    else:
        secondary.z = elevation_plane.z


    # var draw_function: Callable = _create_orthographic_draw_function(player_coordinates, player_up, primary, secondary)
    var draw_function: Callable = _create_isometric_draw_function(player_coordinates, player_up, primary, secondary)

    # print_debug("Redrawing isometric map with player at %s onto plane %s" % [center, cam_plane])

    for elevation_offset: int in range(-draw_box_half.y, draw_box_half.y + 1):
        var elevation_center: Vector3i = player_coordinates + player_up * elevation_offset

        # print_debug("Drawing elevation %s" % elevation_center)

        for primary_offset: int in range(-draw_box_half.x, draw_box_half.x + 1):

            for secondary_offset: int in range(-draw_box_half.z, draw_box_half.z +1):

                var coords: Vector3i = elevation_center + primary * primary_offset + secondary * secondary_offset

                if !_seen.has(coords):
                    continue

                var node: GridNode = level.get_grid_node(coords)
                if node == null:
                    continue
                # Determine side type / color
                var alpha_factor: float = elevation_difference_alpha_factor ** abs(elevation_offset) if elevation_offset != 0 else 1

                for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
                    var is_down: bool = direction == _player.down
                    var color: Color
                    match node.has_side(direction):
                        GridNode.NodeSideState.SOLID:
                            var n_coords: Vector3i = CardinalDirections.direction_to_vectori(direction) + coords
                            if _seen.has(n_coords):
                                var up_node: GridNode = level.get_grid_node(n_coords)
                                if n_coords != null && up_node.has_side(CardinalDirections.invert(direction)) == GridNode.NodeSideState.SOLID:
                                    continue
                            color = floor_color if is_down else other_side_color
                            color.a *= alpha_factor
                        GridNode.NodeSideState.ILLUSORY:
                            if _seen.has(CardinalDirections.translate(coords, direction)):
                                color = illusion_color
                            else:
                                color = floor_color if is_down else other_side_color
                                color.a *= alpha_factor
                        _:
                            continue

                    # 1. Get corners
                    var side_center: Vector3 = coords as Vector3 + CardinalDirections.direction_to_vector(direction) * node_half_size
                    var side_plane: Vector3i = CardinalDirections.direction_to_ortho_plane(direction)
                    var sign_flipped_plane: Vector3i = VectorUtils.flip_sign_first_non_null(side_plane)
                    draw_function.call(
                        [
                            side_center + (side_plane as Vector3) * node_half_size,
                            side_center + (sign_flipped_plane as Vector3) * node_half_size,
                            side_center + (side_plane as Vector3) * -node_half_size,
                            side_center + (sign_flipped_plane as Vector3) * -node_half_size,
                        ],
                        color,
                        !is_down,
                    )

                if coords == player_coordinates:
                    var center: Vector3 = player_coordinates as Vector3 + player_up * -0.25
                    var look: Vector3 = CardinalDirections.direction_to_vector(_player.look_direction) * 0.45
                    var side: Vector3 = CardinalDirections.direction_to_vector(CardinalDirections.yaw_cw(_player.look_direction, _player.down)[0]) * 0.2

                    draw_function.call(
                        [
                            center + look,
                            center - look + side,
                            center - look - side,
                        ],
                        player_color,
                        false,
                    )

func _create_isometric_draw_function(player_coordinates: Vector3, player_up: Vector3, primary: Vector3, secondary: Vector3) -> Callable:
    var area_center: Vector2 = get_rect().get_center()

    var iso_x_scale: float = 1
    var iso_y_scale: float = -0.8
    var iso_z_to_x_scale: float = -0.4
    var iso_z_to_y_scale: float = 0.5

    var coords_transform: Callable = func (coords: Vector3) -> Vector3:
        var transformed: Vector3 = Vector3(coords.dot(primary), coords.dot(player_up), coords.dot(secondary))
        return transformed

    return func(corners: PackedVector3Array, color: Color, outline: bool) -> void:
        var points: PackedVector2Array = []
        @warning_ignore_start("return_value_discarded")
        points.resize(corners.size())
        @warning_ignore_restore("return_value_discarded")

        for idx: int in range(corners.size()):
            var offset: Vector3 = coords_transform.call(corners[idx] - player_coordinates)

            points[idx] = Vector2(
                area_center.x + (offset.x * iso_x_scale + offset.z * iso_z_to_x_scale) * to_canvas_scaling,
                area_center.y + (offset.y * iso_y_scale + offset.z * iso_z_to_y_scale) * to_canvas_scaling,
            )

        _draw_shape(points, color, outline)

func _create_orthographic_draw_function(player_coordinates: Vector3i, player_up: Vector3i) -> Callable:
    var cam_plane: Plane = _calculate_virtual_camera_plane()
    print_debug("%s vs %s d=%s" % [cam_position, cam_plane.get_center(), cam_position.distance_to(player_coordinates)])
    # We need plane up and plane right which can be done with some pitching and yawing the vector to the player
    var cam_plane_up: Vector3 = cam_plane.project(player_coordinates + player_up).normalized()

    var cam_plane_right: Vector3 = cam_plane.normal.cross(cam_plane_up)
    var area: Rect2 = get_rect()
    var area_center: Vector2 = area.get_center()

    return func(corners: PackedVector3Array, color: Color, outline: bool) -> void:
        if !_handle_clipping_update_corners(corners, cam_plane):
            return

        var points: PackedVector2Array = []
        @warning_ignore_start("return_value_discarded")
        points.resize(corners.size())
        @warning_ignore_restore("return_value_discarded")

        for idx: int in range(corners.size()):
            # 3. Calculate plane 3D positions
            # print_debug("projecting %s -> %s" % [corners[idx], cam_plane.project(corners[idx])])

            corners[idx] = cam_plane.project(corners[idx])

            # 4. Scale plane positions to canvas positions
            var offset: Vector2 = Vector2(
                cam_plane_right.dot(corners[idx] - cam_position),
                -cam_plane_up.dot(corners[idx] - cam_position))

            offset *= to_canvas_scaling

            points[idx] = area_center + offset

        _draw_shape(points, color, outline)

func _draw_shape(points: PackedVector2Array, color: Color, outline: bool) -> void:
    if outline:
        draw_polyline(points, color, line_width * to_canvas_scaling)
    elif points.size() > 4:
        # print_debug("Drawing %s -> %s polygon %s" % [corners, points, coords])
        draw_polygon(points, [color])
    else:
        # print_debug("Drawing %s -> %s primitive %s" % [corners, points, coords])
        draw_primitive(points, [color], [Vector2.ZERO])


func _handle_clipping_update_corners(corners: PackedVector3Array, cam_plane: Plane) -> bool:
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
        return false

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


        if corners.resize(3) != 3:
            return false

        corners[0] = pt
        corners[1] = cam_plane.intersects_ray(pt, r1_target)
        corners[2] = cam_plane.intersects_ray(pt, r2_target)

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
        var c2: Vector3 = corners[2]
        var c3: Vector3 = corners[3]

        if corners.resize(5) != 5:
            return false

        if !over[0]:
            corners[0] = cam_plane.intersects_ray(corners[0], corners[1] - corners[0])
            corners[5] = cam_plane.intersects_ray(corners[0], corners[3] - corners[0])
        elif !over[1]:
            corners[1] = cam_plane.intersects_ray(corners[1], corners[0] - corners[1])
            corners[2] = cam_plane.intersects_ray(corners[1], corners[2] - corners[1])
            corners[3] = c2
            corners[4] = c3
        elif !over[2]:
            corners[2] = cam_plane.intersects_ray(corners[2], corners[1] - corners[2])
            corners[3] = cam_plane.intersects_ray(corners[2], corners[3] - corners[2])
            corners[4] = c3
        else:
            corners[3] = cam_plane.intersects_ray(corners[3], corners[2] - corners[3])
            corners[4] = cam_plane.intersects_ray(corners[3], corners[0] - corners[3])

    return true


func _calculate_virtual_camera_plane() -> Plane:
    var center: Vector3 = _player.coordinates()
    var up_offset: Vector3 = CardinalDirections.direction_to_vector(CardinalDirections.invert(_player.down))
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

    var offset: Vector3 = (up_offset + offset_plane).normalized()

    cam_position  = center + offset * view_distance
    var cam_look_direction: Vector3 = center - cam_position

    print_debug("Plane construction from pos %s and normal %s" % [cam_position, cam_look_direction.normalized()])
    return Plane(
        cam_look_direction.normalized(),
        cam_position,
    )
