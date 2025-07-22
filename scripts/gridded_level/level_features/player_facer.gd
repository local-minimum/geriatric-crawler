extends GridNodeFeature
class_name PlayerFacer

@export
var offset_if_on_same_tile: bool

@export_range(0, 0.5)
var offset_amount: float = 0

@export_range(0, 1)
var interpoation_fraction: float = 0.25

var _local_anchor_position: Vector3

func _ready() -> void:
    _local_anchor_position = position
    super._ready()

    var level: GridLevel = get_level()
    if level != null:
        if level.on_change_player.connect(_connect_player_tracking) != OK:
            push_error("Could not connect level player updating")
    else:
        push_error("Player facer must be part of a level")

    _connect_player_tracking()

func _connect_player_tracking() -> void:
    var level: GridLevel = get_level()
    if level == null:
        push_error("%s is not part of a level" % name)
        return

    if level.player.on_move_start.connect(_track_player) != OK:
        push_error("%s cannot track player during movement" % name)
    if level.player.on_move_end.connect(_end_track_player) != OK:
        push_error("%s cannot end player tracking during movement" % name)

    _look_at_player(false)

var _track: bool

func _track_player(entity: GridEntity) -> void:
    var level: GridLevel = get_level()

    if entity != level.player:
        return

    _track = true

func _end_track_player(entity: GridEntity) -> void:
    var level: GridLevel = get_level()

    if entity != level.player:
        return

    _track = false
    _look_at_player(false)

func _process(_delta: float) -> void:
    if !_track: return
    _look_at_player()

func _look_at_player(interpolate: bool = true) -> void:
    var level: GridLevel = get_level()
    if level == null:
        return

    var player_pos: Vector3 = level.player.camera.global_position
    player_pos.y = global_position.y

    if offset_if_on_same_tile && level.player.coordinates() == coordinates():
        var target: Vector3 = _local_anchor_position + CardinalDirections.direction_to_look_vector(level.player.look_direction) * offset_amount * level.node_size
        if interpolate:
            position = lerp(position, target, interpoation_fraction)
        else:
            position = target
    elif position != _local_anchor_position:
        position = _local_anchor_position

    if player_pos != global_position:
        look_at(player_pos, Vector3.UP, true)
