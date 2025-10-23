extends Node
class_name ZoneDamageCore

@export var _zone: LevelZone
@export var _min_damage: int = 1
@export var _max_damage: int = 1

var can_damage: bool:
    get():
        return _min_damage < 0 || _max_damage > 0

var damage_range: Array[int]:
    get():
        return [_min_damage, _max_damage]

func _enter_tree() -> void:
    if __SignalBus.on_enter_zone.connect(_handle_enter_zone) != OK:
        push_error("Failed to connect enter zone")
    if __SignalBus.on_stay_zone.connect(_handle_stay_zone) != OK:
        push_error("Failed to connect stay zone")

func _ready() -> void:
    if _zone == null:
        push_warning("%s does not have a configured zone and thus be useless" % name)

func _handle_enter_zone(zone: LevelZone, entity: GridNodeFeature) -> void:
    if zone != _zone:
        return

    if entity is GridPlayerCore:
        var player: GridPlayerCore = entity
        _handle_player_damage(player)

func _handle_stay_zone(zone: LevelZone, entity: GridEntity) -> void:
    if zone != _zone:
        return

    if entity is GridPlayerCore:
        var player: GridPlayerCore = entity
        _handle_player_damage(player)

func _handle_player_damage(_player: GridPlayerCore) -> void:
    pass
