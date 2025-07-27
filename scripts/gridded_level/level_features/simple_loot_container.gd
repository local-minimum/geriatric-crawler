extends GridEvent
class_name SimpleLootContainer

var _looted: bool

@export
var _contents: Dictionary[String, float]

@export
var _mesh: MeshInstance3D

@export
var _open_tex: Texture

func needs_saving() -> bool:
    return _looted

func save_key() -> String:
    return "slc-%s" % coordinates()

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if _triggered || Inventory.active_inventory == null:
        return

    super.trigger(entity, movement)

    if entity.on_move_end.connect(_handle_loooting) != OK:
        push_error("Failed to connect on movement end, will loot now")
        _handle_loooting(entity)


func _handle_loooting(entity: GridEntity) -> void:
    # TODO: Do fancy stuff!
    await get_tree().create_timer(0.5).timeout
    _set_open_graphics()
    await get_tree().create_timer(0.2).timeout

    _looted = Inventory.active_inventory.add_many_to_inventory(_contents)

    if entity.on_move_end.is_connected(_handle_loooting):
        entity.on_move_end.disconnect(_handle_loooting)

func collect_save_data() -> Dictionary:
    return {}

func load_save_data(_data: Dictionary) -> void:
    # If we exist in the save we are looted no matter what
    _triggered = true
    _looted = true
    _set_open_graphics()

func _set_open_graphics() -> void:
    var mat: StandardMaterial3D = _mesh.get_active_material(0)
    mat.albedo_texture = _open_tex
    mat.albedo_color = Color.WHITE
