extends Node
class_name ZoneDamage

@export var _zone: LevelZone
@export var _min_damage: int = 1
@export var _max_damage: int = 1

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

    if entity is GridPlayer:
        var player: GridPlayer = entity
        _handle_player_damage(player)

func _handle_stay_zone(zone: LevelZone, entity: GridEntity) -> void:
    if zone != _zone:
        return

    if entity is GridPlayer:
        var player: GridPlayer = entity
        _handle_player_damage(player)

func _handle_player_damage(player: GridPlayer) -> void:
    var damage: int = max(0, randi_range(_min_damage, _max_damage) - player.robot.get_skill_level(RobotAbility.SKILL_HARDENED))
    if damage == 0:
        return

    player.robot.health -= damage
    __SignalBus.on_robot_exploration_damage.emit(player.robot, damage)

    if player.robot.health == 0:
        player.robot.kill()
