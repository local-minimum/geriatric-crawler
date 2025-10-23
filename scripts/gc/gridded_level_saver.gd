extends GriddedLevelSaverCore

const _PUNISHMENT_DECK_KEY: String = "punishments"
const _CORPSE_KEY: String = "corpse"

func get_level_to_load() -> String:
    if level.player is GridPlayer:
        if !(level.player as GridPlayer).robot.is_alive():
            return SpaceshipSaver.LEVEL_NAME

    return super.get_level_to_load()

func get_level_to_load_entry_portal_id() -> String:
    if level.player is GridPlayer:
        if !(level.player as GridPlayer).robot.is_alive():
            return ""

    return super.get_level_to_load_entry_portal_id()

## Collect save information for this particular level
func collect_save_state() -> Dictionary:
    var save_state: Dictionary = super.collect_save_state().merged({
        _PUNISHMENT_DECK_KEY: (level as GridLevel).punishments.collect_save_data(),
    }, true)

    var corpse_data: Dictionary
    if _create_corpse(corpse_data):
        save_state[_CORPSE_KEY] = corpse_data

    return save_state

func _create_corpse(save: Dictionary) -> bool:
    var lvl: GridLevel = level
    if (lvl.player as GridPlayer).robot.is_alive():
        if lvl.corpse != null && lvl.corpse.has_loot():
            save.merge(lvl.corpse.collect_save_data(), true)

            return true

        return false

    save[GCCorpse.CORPSE_COORDINATES_KEY] = lvl.player.coordinates()
    save[GCCorpse.CORPSE_INVENTORY_KEY] = Inventory.active_inventory.collect_save_data()
    save[GCCorpse.CORPSE_MODEL_KEY] = (lvl.player as GridPlayer).robot.model.id
    save[GCCorpse.CORPSE_NAME_KEY] = (lvl.player as GridPlayer).robot.given_name

    return true

func get_initial_save_state() -> Dictionary:
    return super.get_initial_save_state().merged({
        _PUNISHMENT_DECK_KEY: []
    }, true)

## Load part of save that holds this particular level
func load_from_save(save_data: Dictionary, entry_portal_id: String) -> void:
    super.load_from_save(save_data, entry_portal_id)

    var lvl: GridLevel = level

    lvl.punishments.load_from_save(DictionaryUtils.safe_geta(save_data, _PUNISHMENT_DECK_KEY, []))

    var corpse_save: Dictionary = DictionaryUtils.safe_getd(save_data, _CORPSE_KEY, {}, false)
    if !corpse_save.is_empty():
        var corpse_scene: PackedScene = load("res://scenes/dungeon/corpse.tscn")
        var corpse: GCCorpse = corpse_scene.instantiate()
        corpse.load_from_save(lvl, corpse_save)
