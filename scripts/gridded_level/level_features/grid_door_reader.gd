extends Interactable
class_name GridDoorReader

@export var door: GridDoor

@export var is_negative_side: bool

@export var mesh: MeshInstance3D

@export var display_material_idx: int = 2

@export var automatic_door_tex: Texture

@export var walk_into_door_tex: Texture

@export var no_entry_door_tex: Texture

@export var click_to_open_tex: Texture

@export var locked_door_tex_model1: Texture

@export var locked_door_tex_model2: Texture

@export var locked_door_tex_model3: Texture

@export var open_door_tex: Texture

@export var emission_intensity: float = 3

@export var max_click_distance: float = 1

@export var camera_puller: CameraPuller

func _ready() -> void:
    is_interactable = false
    if door.on_door_state_chaged.connect(_sync_reader_display) != OK:
        print_debug("%s could not connect to door state changes" % self)

    if __SignalBus.on_level_loaded.connect(_sync_reader_display) != OK:
        push_error("Could not connect level loaded")

    _sync_reader_display.call_deferred()

func _get_locked_texture() -> Texture:
    var key: String = door.key_id
    match KeyMaster.instance.get_key_model_id(key):
        1: return locked_door_tex_model1
        2: return locked_door_tex_model2
        3: return locked_door_tex_model3
        _:
            push_warning("Key %s has model id %s which we don't know how to draw" % [key, KeyMaster.instance.get_key_model_id(key)])
            return locked_door_tex_model1

func _get_needed_texture() -> Texture:
    match door.get_opening_automation(self):
        GridDoor.OpenAutomation.NONE:
            is_interactable = false
            match door.lock_state:
                GridDoor.LockState.OPEN:
                    return open_door_tex
                _:
                    return no_entry_door_tex
        GridDoor.OpenAutomation.WALK_INTO:
            is_interactable = true
            match door.lock_state:
                GridDoor.LockState.LOCKED:
                    return _get_locked_texture()
                _:
                    return walk_into_door_tex
        GridDoor.OpenAutomation.PROXIMITY:
            match door.lock_state:
                GridDoor.LockState.LOCKED:
                    is_interactable = true
                    return _get_locked_texture()
                _:
                    is_interactable = false
                    return automatic_door_tex
        GridDoor.OpenAutomation.INTERACT:
            is_interactable = true
            match door.lock_state:
                GridDoor.LockState.LOCKED:
                    return _get_locked_texture()
                _:
                    return click_to_open_tex


    return no_entry_door_tex

func _sync_reader_display(_level: GridLevel = null) -> void:
    var mat: StandardMaterial3D = mesh.get_surface_override_material(display_material_idx)
    if mat == null:
        mat = StandardMaterial3D.new()

    var tex: Texture = _get_needed_texture()
    mat.albedo_texture = tex

    if emission_intensity > 0:
        mat.emission_texture = tex
        mat.emission_enabled = true
        mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
        mat.emission_intensity = emission_intensity

    mesh.set_surface_override_material(display_material_idx, mat)

func _in_range(event_position: Vector3) -> bool:
    var level: GridLevel = door.get_level()
    return (
        !level.player.cinematic &&
        VectorUtils.all_dimensions_smaller(
            (level.player.global_position - event_position).abs(),
            level.node_size,
        )
    )

func _execute_interation() -> void:
    if door.lock_state == GridDoor.LockState.LOCKED:
        door.attempt_door_unlock(camera_puller)
    else:
        door.toggle_door()
