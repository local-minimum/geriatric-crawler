class_name DebugDraw

static func _safe_add_mech_to_root(node: Node, mesh: MeshInstance3D) -> bool:
    var tree: SceneTree = node.get_tree()
    if tree == null:
        push_error("Node (%s) is not part of a tree" % node.name)
        print_stack()
        mesh.queue_free()
        return false

    if tree.root == null:
        push_error("Node's (%s) tree doesn't have a root" % node.name)
        print_stack()
        mesh.queue_free()
        return false

    tree.root.add_child(mesh)
    return true

static func box(
    node: Node3D,
    center: Vector3,
    size: Vector3,
    color: Color = Color.WHITE_SMOKE,
    outlined: bool = true,
) -> MeshInstance3D:
    if node == null:
        push_error("Node is null")
        print_stack()
        return null

    var mesh: MeshInstance3D = MeshInstance3D.new()
    var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
    var mat: ORMMaterial3D = ORMMaterial3D.new()

    mesh.mesh = immediate_mesh
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color

    var x_size: Vector3 = Vector3.RIGHT * size
    var y_size: Vector3 = Vector3.UP * size
    var z_size: Vector3 = Vector3.FORWARD * size

    var offset_to_lsw: Vector3 = 0.5 * size
    offset_to_lsw.z = -offset_to_lsw.z

    var lsw: Vector3 = center - offset_to_lsw
    var lse: Vector3 = lsw + x_size
    var lnw: Vector3 = lsw + z_size
    var lne: Vector3 = lse + z_size
    var usw: Vector3 = lsw + y_size
    var use: Vector3 = lse + y_size
    var unw: Vector3 = lnw + y_size
    var une: Vector3 = lne + y_size

    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES if outlined else Mesh.PRIMITIVE_TRIANGLES, mat)

    if outlined:
        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(lse)

        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(lnw)

        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(usw)

        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(unw)

        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(use)

        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(lne)

        immediate_mesh.surface_add_vertex(usw)
        immediate_mesh.surface_add_vertex(unw)

        immediate_mesh.surface_add_vertex(usw)
        immediate_mesh.surface_add_vertex(use)

        immediate_mesh.surface_add_vertex(unw)
        immediate_mesh.surface_add_vertex(lnw)

        immediate_mesh.surface_add_vertex(lne)
        immediate_mesh.surface_add_vertex(lse)

        immediate_mesh.surface_add_vertex(lne)
        immediate_mesh.surface_add_vertex(lnw)

        immediate_mesh.surface_add_vertex(lse)
        immediate_mesh.surface_add_vertex(use)
    else:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

        # Down
        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(lse)
        immediate_mesh.surface_add_vertex(lnw)

        immediate_mesh.surface_add_vertex(lnw)
        immediate_mesh.surface_add_vertex(lse)
        immediate_mesh.surface_add_vertex(lne)

        # South
        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(use)
        immediate_mesh.surface_add_vertex(lse)

        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(usw)
        immediate_mesh.surface_add_vertex(use)

        # West
        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(lnw)
        immediate_mesh.surface_add_vertex(unw)

        immediate_mesh.surface_add_vertex(lsw)
        immediate_mesh.surface_add_vertex(unw)
        immediate_mesh.surface_add_vertex(usw)

        # East
        immediate_mesh.surface_add_vertex(lse)
        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(lne)

        immediate_mesh.surface_add_vertex(lse)
        immediate_mesh.surface_add_vertex(use)
        immediate_mesh.surface_add_vertex(une)

        # North
        immediate_mesh.surface_add_vertex(lne)
        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(lnw)

        immediate_mesh.surface_add_vertex(lnw)
        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(unw)

        # Up
        immediate_mesh.surface_add_vertex(unw)
        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(usw)

        immediate_mesh.surface_add_vertex(une)
        immediate_mesh.surface_add_vertex(use)
        immediate_mesh.surface_add_vertex(usw)

    immediate_mesh.surface_end()

    if _safe_add_mech_to_root(node, mesh):
        return mesh
    return null

static func sphere(
    node: Node3D,
    pos: Vector3,
    color = Color.WHITE_SMOKE,
    radius: float = 0.075,
) -> MeshInstance3D:
    if node == null:
        push_error("Node is null")
        print_stack()
        return null

    var mesh: MeshInstance3D = MeshInstance3D.new()
    var sphere: SphereMesh = SphereMesh.new()
    var mat: ORMMaterial3D = ORMMaterial3D.new()

    mesh.mesh = sphere
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color

    sphere.radius = radius
    sphere.height = 2 * radius
    sphere.material = mat

    if _safe_add_mech_to_root(node, mesh):
        mesh.global_position = pos
        return mesh
    return null

static func arrow(
    node: Node3D,
    origin: Vector3,
    target: Vector3,
    color = Color.WHITE_SMOKE,
    shaft_width: float = 0.1,
    head_width: float = 0.2,
    head_proportion: float = 0.15,
    normal: Vector3 = Vector3.UP,
) -> MeshInstance3D:
    if node == null:
        push_error("Node is null")
        print_stack()
        return null

    var mesh: MeshInstance3D = MeshInstance3D.new()
    var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
    var mat: ORMMaterial3D = ORMMaterial3D.new()

    mesh.mesh = immediate_mesh
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var vector: Vector3 = target - origin
    var ortho: Vector3 = vector.cross(normal).normalized()
    var head_offset: Vector3 = vector * (1 - head_proportion)

    var head_start_mid: Vector3 = origin + head_offset

    var shaft_start_left: Vector3 = origin + ortho * shaft_width
    var shaft_start_right: Vector3 = origin - ortho * shaft_width
    var shaft_end_left: Vector3 = shaft_start_left + head_offset
    var shaft_end_right: Vector3 = shaft_start_right + head_offset

    var head_left: Vector3 = head_start_mid + ortho * head_width
    var head_right: Vector3 = head_start_mid - ortho * head_width

    immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)

    immediate_mesh.surface_add_vertex(shaft_start_left)
    immediate_mesh.surface_add_vertex(shaft_end_left)
    immediate_mesh.surface_add_vertex(shaft_start_right)

    immediate_mesh.surface_add_vertex(shaft_start_right)
    immediate_mesh.surface_add_vertex(shaft_end_left)
    immediate_mesh.surface_add_vertex(shaft_end_right)

    immediate_mesh.surface_add_vertex(head_left)
    immediate_mesh.surface_add_vertex(target)
    immediate_mesh.surface_add_vertex(head_right)

    immediate_mesh.surface_end()

    if _safe_add_mech_to_root(node, mesh):
        return mesh
    return null


static func direction_to_color(direction: CardinalDirections.CardinalDirection) -> Color:
    match direction:
        CardinalDirections.CardinalDirection.NORTH: return Color.ROYAL_BLUE
        CardinalDirections.CardinalDirection.SOUTH: return Color.YELLOW
        CardinalDirections.CardinalDirection.WEST: return Color.AZURE
        CardinalDirections.CardinalDirection.EAST: return Color.CYAN
        CardinalDirections.CardinalDirection.UP: return Color.BROWN
        CardinalDirections.CardinalDirection.DOWN: return Color.DARK_OLIVE_GREEN
        CardinalDirections.CardinalDirection.NONE: return Color.TEAL
        _: return Color.WHITE_SMOKE
