extends GridNodeFeature
class_name PlayerFacer

func _ready() -> void:
    super()

    var level: GridLevel = get_level()
    if level == null:
        push_error("%s is not part of a level" % name)
        return

    if level.player.on_move_start.connect(_track_player) != OK:
        push_error("%s cannot track player during movement" % name)
    if level.player.on_move_end.connect(_end_track_player) != OK:
        push_error("%s cannot end player tracking during movement" % name)

    _look_at_player()

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

func _process(_delta: float) -> void:
    if !_track: return
    _look_at_player()

func _look_at_player() -> void:
    var level: GridLevel = get_level()
    if level == null:
        return

    var player_pos: Vector3 = level.player.global_position
    player_pos.y = global_position.y

    if player_pos != global_position:
        look_at(player_pos, Vector3.UP, true)
