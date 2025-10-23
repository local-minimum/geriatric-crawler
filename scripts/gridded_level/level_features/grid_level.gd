extends GridLevelCore
class_name GridLevel


@export var punishments: PunishmentDeck

var corpse: GCCorpse

var _doors: Array[GridDoor] = []
func doors() -> Array[GridDoor]:
    if _doors.is_empty():
        for door: GridDoor in find_children("", "GridDoor"):
            _doors.append(door)
    return _doors

func alive_enemies() -> Array[BattleEnemy]:
    var enemies: Array[BattleEnemy]

    for entity: GridEntity in grid_entities:
        if entity is GridEncounter:
            var encounter: GridEncounter = entity
            if !encounter.can_trigger():
                continue

            if encounter.effect is BattleModeTrigger:
                var battle_trigger: BattleModeTrigger = encounter.effect

                for enemy: BattleEnemy in battle_trigger.enemies:
                    if enemy.is_alive_and_has_health():
                        enemies.append(enemy)

    return enemies
