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

    print_debug("[Zone Damage] %s has health %s (%s)" % [player.robot.given_name, player.robot.health, player.robot.model.max_hp])
    player.robot.health -= damage
    print_debug("[Zone Damage] Did %s damage to %s which ended up with health %s (%s)" % [damage, player.robot.given_name, player.robot.health, player.robot.model.max_hp])
    if player.robot.health == 0:
        player.robot.kill()
