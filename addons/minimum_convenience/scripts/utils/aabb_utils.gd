class_name AABBUtils

static func box_corners(box: AABB) -> Array[Vector3]:
    var pos: Vector3 = box.position
    var end: Vector3 = box.end
    return [
        pos,

        Vector3(pos.x, pos.y, end.z),
        Vector3(pos.x, end.y, end.z),
        Vector3(pos.x, end.y, pos.z),

        Vector3(end.x, pos.y, pos.z),
        Vector3(end.x, end.y, pos.z),
        Vector3(end.x, pos.y, end.z),

        end,
    ]

static func bounding_box(node: Node3D) -> AABB:
    var bounding: AABB
    for child: MeshInstance3D in node.find_children("", "MeshInstance3D", true, false):
        var box: AABB = child.global_transform * child.get_aabb()
        if bounding.size.length_squared() == 0:
            bounding = box
        else:
            bounding = bounding.merge(box)

    return bounding

static func closest_surface_point(box: AABB, point: Vector3) -> Vector3:
    if box.has_point(point):
        var corners: Array[Vector3] = box_corners(box)
        corners.sort_custom(
            func (a: Vector3, b: Vector3) -> bool:
                return a.distance_squared_to(point) < b.distance_squared_to(point)
        )
        var p: Plane = Plane((corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized(), corners[0])
        return p.project(point)

    return Vector3(
        clampf(point.x, box.position.x, box.end.x),
        clampf(point.y, box.position.y, box.end.y),
        clampf(point.z, box.position.z, box.end.z),
    )
