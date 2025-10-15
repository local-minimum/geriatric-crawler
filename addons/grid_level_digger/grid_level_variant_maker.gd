@tool
extends MarginContainer
class_name GridLevelVariantMaker

@export var template: LineEdit
@export var suffix: LineEdit
@export var warning: Label
@export var create_files_list: Label
@export var create_buttons: Array[Button]

var _panel: GridLevelDiggerPanel
## [Resource Path, Relative Node Path, Duplicate (true) vs New Inherited (false)]
var _to_copy: Array[Array]
var _regexp: RegEx

func _init() -> void:
    _regexp = RegEx.new()
    _regexp.compile("(\\.|_[^_]+\\.)(.+$)")

func configure(panel: GridLevelDiggerPanel, side: GridNodeSide) -> void:
    _panel = panel
    template.text = side.scene_file_path

    _find_copy_work(side)
    _sync_suffix(suffix.placeholder_text)

func _find_copy_work(side: GridNodeSide) -> void:
    _to_copy.clear()
    _to_copy.append([side.scene_file_path, "", true])
    var _listed: Array[String]

    for m_instance: MeshInstance3D in side.find_children("", "MeshInstance3D", true, false):
        var parts: Array[Array] = ResourceUtils.list_resource_parentage(m_instance, side.get_path())
        parts.reverse()
        print_debug("[GLD Variant Maker] Found Mesh '%s' with parentage (%s) %s" % [m_instance.name, parts.size(), parts])
        var idx = -1
        for part: Array[String] in parts:
            idx += 1
            if idx == 0:
                continue

            var node_path: String = part[0]
            var resource_path: String = part[1]

            var relative: String = node_path.trim_prefix(side.get_path())
            relative = relative.trim_prefix("/")
            print_debug("[GLD Variant Maker] Looking for node-path '%s'" % relative)

            if _listed.has(relative):
                continue

            _to_copy.append([resource_path, relative, idx != parts.size() - 1])
            _listed.append(relative)


func _on_create__style_pressed() -> void:
    _on_create_pressed(true)

func _on_create_pressed(set_style: bool = false) -> void:
    pass

func _on_variant_suffix_text_changed(new_text: String) -> void:
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
    return "%s/%s%s.%s" % [basedir, filename.substr(0, r_match.get_start(1)), suffix, r_match.get_string(2)]
