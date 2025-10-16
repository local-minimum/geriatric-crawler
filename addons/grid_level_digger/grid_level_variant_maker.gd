@tool
extends MarginContainer
class_name GridLevelVariantMaker

@export var template: LineEdit
@export var suffix: LineEdit
@export var warning: Label
@export var create_files_list: Label
@export var create_buttons: Array[Button]
@export var _highlight_color: Color = Color.MEDIUM_AQUAMARINE

var _panel: GridLevelDiggerPanel
var _direction: CardinalDirections.CardinalDirection
var _root_from: String
var _highlight: MeshInstance3D

static var _start_with_suffix: String

## [Resource Path, Relative Node Path, Duplicate (true) vs New Inherited (false)]
var _to_copy: Array[Array]
var _node: GridNode
var _regexp: RegEx
var _close: Callable

func _init() -> void:
    _regexp = RegEx.new()
    _regexp.compile("(\\.|_[^_]+\\.)(.+$)")

func _exit_tree() -> void:
    if _highlight != null:
        _highlight.queue_free()
        _highlight = null

func configure(panel: GridLevelDiggerPanel, grid_node: GridNode, side: GridNodeSide, close: Callable) -> void:
    _panel = panel
    _node = grid_node
    _direction = side.direction
    _close = close

    template.text = side.scene_file_path
    suffix.text = _start_with_suffix

    _find_copy_work(side)
    _sync_suffix(suffix.placeholder_text if suffix.text.is_empty() else suffix.text)
    _highlight_targets(side)

func _highlight_targets(side: GridNodeSide) -> void:
    var bounds: AABB = AABBUtils.bounding_box(side).grow(0.1)
    _highlight = DebugDraw.box(
        _panel.level,
        bounds.get_center(),
        bounds.size,
        _highlight_color,
        false,
    )

func _find_copy_work(side: GridNodeSide) -> void:
    _to_copy.clear()
    _to_copy.append([side.scene_file_path, "", true])
    _root_from = side.scene_file_path
    var _listed: Array[String]

    for m_instance: MeshInstance3D in side.find_children("", "MeshInstance3D", true, false):
        var parts: Array[Array] = ResourceUtils.list_resource_parentage(m_instance, side.get_path())
        parts.reverse()
        print_debug("[GLD Variant Maker] Found Mesh '%s' with parentage depth %s" % [m_instance.name, parts.size()])
        var idx = -1
        for part: Array[String] in parts:
            idx += 1
            if idx == 0:
                continue

            var node_path: String = part[0]
            var resource_path: String = part[1]

            var relative: String = node_path.trim_prefix(side.get_path())
            relative = relative.trim_prefix("/")

            if _listed.has(relative):
                continue

            _to_copy.append([resource_path, relative, idx != parts.size() - 1])
            _listed.append(relative)
            print_debug("[GLD Variant Maker] Added job on '%s' resource %s" % [relative, resource_path])

func _on_create__style_pressed() -> void:
    _on_create_pressed(true)

var _swaps: Dictionary[String, String]
var _roots: Dictionary[String, Node]
var level_scene: String

func _on_create_pressed(set_style: bool = false) -> void:
    _start_with_suffix = ""
    _swaps.clear()
    level_scene = EditorInterface.get_edited_scene_root().scene_file_path
    var suffix: String = suffix.placeholder_text if suffix.text.is_empty() else suffix.text

    _to_copy.sort_custom(func (a: Array, b: Array) -> bool:
        var a_path: String = a[1]
        var b_path: String = b[1]

        if b_path.is_empty():
            return true
        elif a_path.is_empty():
            return false

        return a_path.count("/") > b_path.count("/")
    )

    for part: Array in _to_copy:
        var target: String = _get_target_path(part[0], suffix)
        if part[2]:
            _make_duplicate(part[0], target)
        else:
            _make_new_inherited(part[0], target)

    for new_scene: String in _swaps.values():
        print_debug("[GLD Variant Maker] Wanting to close newly created scene '%s' with parentage %s" % [new_scene, _roots[new_scene].get_path()])

    if set_style:
        if _swaps.has(_root_from):
            _panel.styles.set_resource(_direction, load(_swaps[_root_from]))
        else:
            push_warning("[GLD Variant Maker] Cannot update style because failed to create new scene or not yet created")

    EditorInterface.open_scene_from_path(level_scene)

    var panel: GridLevelDiggerPanel = _panel
    var grid_node: GridNode = _node
    var direction: CardinalDirections.CardinalDirection = _direction
    var new_resource: String = _swaps.get(_root_from)

    _close.call(
        func () -> void:
            await grid_node.get_tree().create_timer(0.5).timeout

            if panel.edited_scene_root != grid_node.get_tree().edited_scene_root:
                    push_error("[GLD Variant Maker] Cannot safely swap out node side because we aren't focusing the right scene %s vs %s" % [
                        panel.edited_scene_root,
                        grid_node.get_tree().edited_scene_root,
                    ])

            else:
                if !new_resource.is_empty():
                    if panel.node_digger.swap_node_side(
                        grid_node,
                        direction,
                        new_resource,
                    ):
                        EditorInterface.save_scene()
                        EditorInterface.reload_scene_from_path(panel.edited_scene_root.scene_file_path)
                    else:
                        push_error("[GLD Variant Maker] Failed to swap out %s's %s side for '%s'" % [
                            grid_node,
                            CardinalDirections.name(direction),
                            new_resource,
                        ])

                else:

                    push_warning("[GLD Variant Maker] Cannot swap out side because lacking info about variant root")
    )

func _on_variant_suffix_text_changed(new_text: String) -> void:
    _start_with_suffix = new_text
    _sync_suffix(suffix.placeholder_text if new_text.is_empty() else new_text)


func _sync_suffix(suffix: String) -> void:
    if suffix.is_empty():
        warning.text = "You must have a suffix"
        warning.show()
        create_files_list.hide()
        _sync_buttons(true)
        return

    var todo: Array[String]
    var bad_files: Array[String]
    var missing_dirs: Array[String]

    for part: Array in _to_copy:
        var _action: String = "DUPLICATE" if part[2] else "NEW INHERIT"

        var target: String = _get_target_path(part[0], suffix)
        var dir: DirAccess = DirAccess.open(target.get_base_dir())

        if !dir:
            missing_dirs.append(target.get_base_dir())
        elif dir.file_exists(target.get_file()):
            bad_files.append(target)

        todo.push_back("- [%s] %s" % [_action, target])

    create_files_list.text = "\n".join(todo)
    create_files_list.show()

    if bad_files.is_empty() && missing_dirs.is_empty():
        warning.hide()
        _sync_buttons(false)
    elif !missing_dirs.is_empty():
        warning.text = "Directory %s does not exist" % ", ".join(missing_dirs)
        warning.show()
        _sync_buttons(true)
    else:
        warning.text = "Files %s already exist" % ", ".join(bad_files)
        warning.show()
        _sync_buttons(true)

func _sync_buttons(disabled: bool) -> void:
    for btn: Button in create_buttons:
        btn.disabled = disabled

func _get_target_path(path: String, suffix: String) -> String:
    var basedir: String = path.get_base_dir()
    var filename: String = path.get_file()

    var r_match: RegExMatch = _regexp.search(filename)
    if r_match == null:
        push_error("[GLD Variant Maker] could not match regex on file '%s'" % filename)
        return path


    r_match.get_start(1)
    return "%s/%s%s.tscn" % [basedir, filename.substr(0, r_match.get_start(1)), suffix]

func _make_duplicate(path: String, new_path: String):
    print_debug("[GLD Variant Maker] make duplicate scene form '%s'" % path)

    var resource: Resource = load(path)
    if ResourceSaver.save(resource, new_path) != OK:
        push_error("[GLD Variant Maker] could not save '%s' to '%s'" % [path, new_path])

    _swaps[path] = new_path

    await _wait_for_scene(new_path)

    EditorInterface.open_scene_from_path(new_path)

    _roots[new_path] = _panel.edited_scene_root

    if _make_all_meshes_unique(new_path):
        for node: Node in ResourceUtils.find_all_nodes_with_scene_file_paths(_panel.edited_scene_root):
            if _swaps.has(node.scene_file_path):
                await _wait_for_scene(_swaps[node.scene_file_path])

                var replacement_resouce: PackedScene = load(_swaps[node.scene_file_path])
                var replacement: Node = replacement_resouce.instantiate()
                var name: String = node.name

                node.get_parent().add_child(replacement)
                replacement.owner = node.get_tree().edited_scene_root

                if node is Node3D and replacement is Node3D:
                    var transform: Transform3D = (node as Node3D).global_transform
                    (replacement as Node3D).global_transform = transform
                elif node is Node2D and replacement is Node2D:
                    var transform: Transform2D = (node as Node2D).global_transform
                    (replacement as Node2D).global_transform = transform
                else:
                    push_warning("[GLD Variant Maker] Cannot copy transforms / layout of %s to %s" % [node, replacement])

                print_debug("[GLD Variant Maker] Swapping out '%s' @ '%s' for scene from %s" % [node.name, _panel.edited_scene_root.get_path_to(node), replacement.scene_file_path])
                node.free()
                replacement.name = name

    EditorInterface.save_scene_as(new_path, true)
    print_debug("[GLD Variant Maker] made duplicate scene '%s'" % new_path)

func _make_new_inherited(path: String, new_path: String):
    print_debug("[GLD Variant Maker] make new inherited scene form '%s'" % path)

    _swaps[path] = new_path

    EditorInterface.open_scene_from_path(path, true)
    EditorInterface.save_scene_as(new_path, true)

    await _wait_for_scene(new_path)

    _roots[new_path] = _panel.edited_scene_root

    _make_all_meshes_unique(new_path)
    EditorInterface.save_scene_as(new_path, true)

    print_debug("[GLD Variant Maker] made new inherited scene '%s'" % new_path)

func _make_all_meshes_unique(path: String) -> bool:
    var root: Node = _panel.edited_scene_root
    if root.scene_file_path != path:
        push_error("[GLD Variant Maker] Edited Scene '%s' is not the expected '%s'" % [root.scene_file_path, path])
        return false

    for m_instance: MeshInstance3D in root.find_children("", "MeshInstance3D"):
        if ResourceUtils.in_instanced_scene_under_parent(root, m_instance):
            # push_warning("[GLD Variant Maker] Mesh of '%s' in '%s' should not be made unique because part of other scene" % [root.get_path_to(m_instance), root.scene_file_path])
            continue

        print_debug("[GLD Variant Maker] Will make mesh of '%s' in '%s' unique" % [root.get_path_to(m_instance), root.scene_file_path])
        m_instance.mesh = m_instance.mesh.duplicate()

    return true

func _wait_for_scene(path: String, timeeout: int = 5000):
    var dir: DirAccess = DirAccess.open(path.get_base_dir())
    if dir == null:
        return

    var start: int = Time.get_ticks_msec()

    while !dir.file_exists(path.get_file()):
        await get_tree().create_timer(0.1).timeout

        if Time.get_ticks_msec() - start > timeeout:
            break
