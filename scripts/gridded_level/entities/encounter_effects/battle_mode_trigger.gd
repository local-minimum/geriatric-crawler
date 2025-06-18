extends GridEncounterEffect
class_name BattleModeTrigger

var level: GridLevel

@export
var enemies: Array[BattleEnemy]

func prepare(_encounter: GridEncounter) -> void:
    var focus: BattleEnemy = get_highest_scoring_live_enemy()
    if focus == null:
        push_error("Battle mode trigger doesn't have any focus enemy %s" % [enemies])
        return

    if focus.sprite != null:
        # TODO: Make someone else handle sprite and its animations and such
        var mat: StandardMaterial3D = _encounter.graphics.get_active_material(0)
        mat.albedo_texture = focus.sprite
        mat.albedo_color = Color.WHITE

func get_highest_scoring_live_enemy() -> BattleEnemy:
    if enemies.size() == 0:
        push_warning("%s doesn't have any enemy" % name)
        return

    var scores: Dictionary[String, int] = {}
    for enemy: BattleEnemy in enemies:
        if scores.has(enemy.variant_id):
            scores[enemy.variant_id] += enemy.difficulty
        else:
            scores[enemy.variant_id] = enemy.difficulty

    var highest_score: int = -1
    var focus_variant: String

    for variant: String in scores.keys():
        var score: int = scores[variant]
        if score > highest_score:
            highest_score = score
            focus_variant = variant

    if focus_variant == null:
        push_warning("No focus variant amont enemies '%s' (%s)" % [scores, enemies])
        return null

    for enemy: BattleEnemy in enemies:
        if enemy.variant_id == focus_variant:
            return enemy

    push_error("Failed to locate an enemy of variant '%s' (%s)" % [focus_variant, enemies])
    return null

## Thing that happesn when an encounter is triggered.
## Returns if could trigger
func invoke(triggering_encounter: GridEncounter, player: GridEntity) -> bool:
    print_debug("Entering battle with %s" % triggering_encounter.name)

    @warning_ignore_start("return_value_discarded")
    super(triggering_encounter, player)
    @warning_ignore_restore("return_value_discarded")

    level = triggering_encounter.get_level()
    level.paused = true
    level.battle_mode.enter_battle(self)
    return true

func complete() -> void:
    super()

    level.paused = false
    print_debug("Battle ended, returned to exploring")
