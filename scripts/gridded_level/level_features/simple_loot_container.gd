extends GridEvent
class_name SimpleLootContainer

var _looted: bool

@export
var _contents: Dictionary[String, float]

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
    _looted = Inventory.active_inventory.add_many_to_inventory(_contents)
    # TODO: Do fancy stuff!

    if entity.on_move_end.is_connected(_handle_loooting):
        entity.on_move_end.disconnect(_handle_loooting)

func collect_save_data() -> Variant:
    return _looted

func load_save_data(_data: Variant) -> void:
    # If we exist in the save we are looted no matter what
    _looted = true
