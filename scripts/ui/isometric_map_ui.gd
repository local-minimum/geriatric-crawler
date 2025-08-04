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
var other_side_color: Color

@export_range(0, 1)
var elevation_difference_alpha_factor: float = 0.8

func trigger_redraw(player: GridPlayer, seens_coordinates: Array[Vector3i]) -> void:
    _player = player
    _seen = seens_coordinates

    queue_redraw()

func _draw() -> void:
    var level: GridLevel = _player.get_level()

    var cam_plane: Plane = _calculate_virtual_camera_plane()
    var cam_position: Vector3 = cam_plane.get_center()

    var node_half_size: Vector3 = Vector3.ONE * 0.5

    var center: Vector3i = _player.coordinates()

    var up: Vector3i = CardinalDirections.direction_to_vector(CardinalDirections.invert(_player.down))
    var plane: Vector3i = CardinalDirections.direction_to_ortho_plane(_player.down)
    if VectorUtils.is_negative_cardinal_axis(up):
        plane *= -1

    for elevation_offset: int in range(-draw_box_half.y, draw_box_half.y + 1):
        var elevation_center: Vector3i = center + up * elevation_offset
        for primary_offset: int in range(-draw_box_half.x, draw_box_half.x + 1):
            var primary: Vector3i
            if plane.x != 0:
                primary.x = plane.x
            elif plane.y != 0:
                primary.y = plane.y
            else:
                primary.z = plane.z

            for secondary_offset: int in range(-draw_box_half.z, draw_box_half.z +1):
                var secondary: Vector3i
                if primary.x != 0:
                    if plane.y != 0:
                        secondary.y = plane.y
                    else:
                        secondary.z = plane.z
                else:
                    secondary.z = plane.z

                var coords: Vector3i = elevation_center + primary + secondary
                if !_seen.has(coords):
                    continue

                var node: GridNode = level.get_grid_node(coords)
                if node == null:
                    continue

                match node.has_side(_player.down):
                    GridNode.NodeSideState.SOLID:
                        # TODO: Draw ground
                        pass
                    GridNode.NodeSideState.ILLUSORY:
                        if _seen.has(CardinalDirections.translate(coords, _player.down)):
                            # TODO: Draw illusion
                            pass
                        else:
                            # TODO: Draw ground
                            pass


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

    return Plane(
        cam_look_direction.normalized(),
        cam_position,
    )
