extends Interactable
class_name ExitLevelInteraction

@export var portal: LevelPortal

func _ready() -> void:
    is_interactable = true

func check_allow_interact() -> bool:
    # print_debug("[Airlock button] allow interact %s" % [portal.allow_exit])
    if !portal.allow_exit:
        NotificationsManager.info(tr("NOTICE_AIRLOCK"), tr("AIRLOCK_NOT_OPERATIONAL"))
        return false
    return true

func _in_range(_event_position: Vector3) -> bool:
    var level: GridLevel = portal.get_level()

    # print_debug("[Airlock button] in range? %s == %s, %s == %s" % [
    #    level.player.coordinates(), portal.coordinates(),
    #    CardinalDirections.name(portal.get_grid_anchor_direction()), CardinalDirections.name(level.player.look_direction)])

    return (
        !level.player.cinematic &&
        level.player.coordinates() == portal.coordinates() &&
        portal.get_grid_anchor_direction() == level.player.look_direction
    )

func execute_interation() -> void:
    portal.exit_level()
