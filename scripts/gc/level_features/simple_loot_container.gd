extends GridEvent
class_name SimpleLootContainer

var _looted: bool

@export var _contents: Dictionary[String, float]

@export var _mesh: MeshInstance3D

@export var _open_tex: Texture
@export var _close_tex: Texture

var _looting: bool
var _inv: Inventory.InventorySubscriber
var _manual_loot: bool

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()

func _ready() -> void:
    super._ready()

    var mat: Material = _mesh.get_active_material(0)
    if mat.get_reference_count() > 1:
        _mesh.material_overlay = mat.duplicate()

    if __SignalBus.on_move_end.connect(_handle_loooting) != OK:
        push_error("Failed to connect on movement end, will loot manually")
        _manual_loot = true

func needs_saving() -> bool:
    return _looted

func save_key() -> String:
    return "slc-%s" % coordinates()

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if _triggered || _inv.inventory == null:

        return

    super.trigger(entity, movement)

    if _manual_loot:
        _handle_loooting(entity)


func _handle_loooting(entity: GridEntity) -> void:
    if _looting || _looted || entity is not GridPlayer || entity.coordinates() != coordinates():
        return

    _looting = true

    await get_tree().create_timer(0.5).timeout
    _set_open_graphics()
    await get_tree().create_timer(0.2).timeout

    _looted = _inv.inventory.add_many_to_inventory(_contents)

    var key_ring: KeyRingCore = get_level().player.key_ring
    for id: String in _contents:
        if KeyRing.is_key(id):
            var amount: int = ceili(_contents[id])
            if amount > 0:
                key_ring.gain(id, amount)

    _looting = false

const TRIGGERED_KEY: String = "triggered"

func collect_save_data() -> Dictionary:
    return {
        TRIGGERED_KEY: true
    }

func load_save_data(data: Dictionary) -> void:
    var triggered: bool = DictionaryUtils.safe_getb(data, TRIGGERED_KEY, false, false)
    _triggered = triggered
    _looted = triggered
    if triggered:
        _set_open_graphics()
    else:
        _set_close_graphics()

func _set_open_graphics() -> void:
    var mat: StandardMaterial3D = _mesh.get_active_material(0)
    mat.albedo_texture = _open_tex
    mat.albedo_color = Color.WHITE

func _set_close_graphics() -> void:
    var mat: StandardMaterial3D = _mesh.get_active_material(0)
    mat.albedo_texture = _close_tex
    mat.albedo_color = Color.WHITE
