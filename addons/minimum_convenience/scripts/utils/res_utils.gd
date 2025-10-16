class_name ResourceUtils

static func valid_abs_resource_path(path: String, allow_hidden: bool = false) -> bool:
    if path.is_empty():
        return false

    if !path.begins_with("res://"):
        return false

    if allow_hidden:
        return true

    var parts: PackedStringArray = path.substr("res://".length()).split("/")
    for part: String in parts:
        if part.begins_with("."):
            return false

    return true

static func find_resources(
    root: String = "res://",
    pattern: Variant = null,
    filter: Variant = null,
    allow_hidden: bool = false,
) -> PackedStringArray:
    var result: PackedStringArray
    if !valid_abs_resource_path(root):
        return result

    _find_resources(
        result,
        root,
        _pattern_filter(pattern),
        filter if filter is Callable else _everything_goes,
        allow_hidden,
    )

    return result

static func _pattern_filter(pattern: Variant) -> Callable:
    if pattern is Callable:
        return pattern

    if pattern is String:
        var p: String =  pattern
        if p.contains(","):
            var allowed: PackedStringArray = p.split(",")
            return func (path: String) -> bool:
                for allow: String in allowed:
                    if path.ends_with(allow):
                        return true
                return false

        return func (path: String) -> bool: return path.ends_with(p)

    if pattern is RegEx:
        var reg: RegEx = pattern
        return func (path: String) -> bool: return reg.search(pattern) != null

    if pattern != null:
        push_warning("Don't know how to convert %s to a pattern filter function" % pattern)

    return _everything_goes

static func _everything_goes(path: String) -> bool: return true

static func _find_resources(
    results: PackedStringArray,
    directory_path,
    filename_filter: Callable,
    filter: Callable,
    allow_hidden: bool,
) -> void:
    var dir: DirAccess = DirAccess.open(directory_path)
    if dir == null:
        push_warning("'%s' is not a directory we have access to" % directory_path)
        return
    dir.include_hidden = allow_hidden
    dir.include_navigational = false

    dir.list_dir_begin()
    for file: String in dir.get_files():
        var full_file_path: String = "%s/%s" % [dir.get_current_dir(), file]
        if filename_filter.call(full_file_path) && filter.call(full_file_path):
            results.push_back(full_file_path)
    dir.list_dir_end()

    dir.list_dir_begin()
    for dir_path: String in dir.get_directories():
        if !allow_hidden && dir_path.begins_with("."):
            continue

        var full_dir_path: String = ("%s%s" % [dir.get_current_dir(), dir_path]) if dir.get_current_dir().ends_with("//") else ("%s/%s" % [dir.get_current_dir(), dir_path])

        _find_resources(
            results,
            full_dir_path,
            filename_filter,
            filter,
            allow_hidden,
        )


## Returns an array of [Node Path, Node Scene File Path]:s
static func list_resource_parentage(node: Node, until: String = "") -> Array[Array]:
    var res: Array[Array]
    var terminate: bool

    while true:
        if !node.scene_file_path.is_empty():
            var info: Array[String] = [node.get_path(), node.scene_file_path]
            res.append(info)

        node = node.get_parent()

        if node == null || terminate:
            break

        if !until.is_empty() && ("%s" % node.get_path()) == until:
            terminate = true

    return res

## This assumes node is in fact a child of parent, the function will not check that
static func in_instanced_scene_under_parent(parent: Node, node: Node) -> bool:
    while true:
        if node == parent:
            return false

        if !node.scene_file_path.is_empty():
            # print_debug("[Resource Utils] %s has path %s and thus not part of %s" % [node, node.scene_file_path, parent])
            return true

        node = node.get_parent()

        if node == null:
            break

    return false

static func find_first_node_using_resource(root: Node, scene_file_path: String, internal: bool = false) -> Node:
    for child: Node in root.get_children(internal):
        if child.scene_file_path == scene_file_path:
            return child

        var target: Node = find_first_node_using_resource(child, scene_file_path, internal)
        if target != null:
            return target

    return null

static func find_all_nodes_using_resource(root: Node, scene_file_path: String, internal: bool = false) -> Array[Node]:
    var nodes: Array[Node]

    for child: Node in root.get_children(internal):
        if child.scene_file_path == scene_file_path:
            nodes.append(child)
            continue

        nodes.append_array(find_all_nodes_using_resource(child, scene_file_path, internal))

    return nodes


static func find_all_nodes_with_scene_file_paths(root: Node, internal: bool = false) -> Array[Node]:
    var nodes: Array[Node]

    for child: Node in root.get_children(internal):
        if !child.scene_file_path.is_empty():
            nodes.append(child)
            continue

        nodes.append_array(find_all_nodes_with_scene_file_paths(child, internal))

    return nodes
