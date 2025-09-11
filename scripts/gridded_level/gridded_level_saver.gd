extends LevelSaver

const _LEVEL_ID_KEY: String = "id"
const _PLAYER_KEY: String = "player"
const _ENCOUNTERS_KEY: String = "encounters"
const _EVENTS_KEY: String = "events"
const _PUNISHMENT_DECK_KEY: String = "punishments"
const _CORPSE_KEY: String = "corpse"

# TODO: Should not be hardcoded static
const _PLAYER_SCENE: String = "res://scenes/dungeon/player.tscn"

@export var persistant_group: String = "Persistant"

@export var encounter_group: String = "Encounter"

@export var level: GridLevel

func _ready() -> void:
    if level == null:
        var node: Node = get_tree().get_first_node_in_group(GridLevel.LEVEL_GROUP)
        if node != null && node is GridLevel:
            level = node
        else:
            push_warning("Could not find a level in '%s', won't be able to load level saves" % GridLevel.LEVEL_GROUP)

func get_level_name() -> String:
    _ready()
    if level == null:
        return GridLevel.UNKNOWN_LEVEL_ID

    return level.level_id

func get_level_to_load() -> String:
    if !level.player.robot.is_alive():
        return SpaceshipSaver.LEVEL_NAME

    if level.activated_exit_portal != null:
        var target: String = level.activated_exit_portal.exit_level_target
        if target.is_empty():
            return get_level_name()
        return target

    return get_level_name()

func get_level_to_load_entry_portal_id() -> String:
    if !level.player.robot.is_alive():
        return ""

    if level.activated_exit_portal != null:
        return level.activated_exit_portal.exit_level_target_portal

    return ""

## Collect save information for this particular level
func collect_save_state() -> Dictionary:
    var encounters_save: Dictionary[String, Dictionary] = {}
    var events_save: Dictionary[String, Dictionary] = {}

    var save_state: Dictionary = {
        _ENCOUNTERS_KEY: encounters_save,
        _EVENTS_KEY: events_save,
        _PUNISHMENT_DECK_KEY: level.punishments.collect_save_data(),
    }

    var corpse_data: Dictionary
    if _create_corpse(corpse_data):
        save_state[_CORPSE_KEY] = corpse_data

    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        if persistable is GridPlayer:
            var player: GridPlayer = persistable
            if !player.robot.is_alive():
                continue

            if save_state.has(_PLAYER_KEY):
                push_error("Level can only save one player, ignoring %s" % persistable.name)

            var player_save: Dictionary = player.save()
            if level.activated_exit_portal != null:
                GridPlayer.strip_save_of_transform_data(player_save)
            save_state[_PLAYER_KEY] = player_save


    for encounter_node: Node in get_tree().get_nodes_in_group(encounter_group):
        if encounter_node is GridEncounter:
            var encounter: GridEncounter = encounter_node

            if encounters_save.has(encounter.encounter_id):
                push_error("Level %s has duplicate encounters with id '%s'" % [get_level_name(), encounter.encounter_id])

            encounters_save[encounter.encounter_id] = encounter.save()

    for event_node: Node in get_tree().get_nodes_in_group(GridEvent.GRID_EVENT_GROUP):
        if event_node is GridEvent:
            var event: GridEvent = event_node
            if !event.needs_saving():
                continue

            events_save[event.save_key()] = event.collect_save_data()

    print_debug("[GriddedLevelSaver] Saved level %s" % get_level_name())

    return save_state

func _create_corpse(save: Dictionary) -> bool:
    if level.player.robot.is_alive():
        if level.corpse != null && level.corpse.has_loot():
            save.merge(level.corpse.collect_save_data(), true)

            return true

        return false

    save[Corpse.CORPSE_COORDINATES_KEY] = level.player.coordinates()
    save[Corpse.CORPSE_INVENTORY_KEY] = Inventory.active_inventory.collect_save_data()
    save[Corpse.CORPSE_MODEL_KEY] = level.player.robot.model.id
    save[Corpse.CORPSE_NAME_KEY] = level.player.robot.given_name

    return true

func get_initial_save_state() -> Dictionary:
    var player_save: Dictionary = level.player.initial_state()
    if level.activated_exit_portal != null:
        GridPlayer.strip_save_of_transform_data(player_save)

    var save_state: Dictionary = {
        _LEVEL_ID_KEY: null,
        _PLAYER_KEY: player_save,
        _ENCOUNTERS_KEY: {}, # We just assume they are as they should be
        _EVENTS_KEY: {},
        _PUNISHMENT_DECK_KEY: []
    }

    return save_state

## Load part of save that holds this particular level
func load_from_save(save_data: Dictionary, entry_portal_id: String) -> void:
    level.activated_exit_portal = null

    if entry_portal_id.is_empty():
        level.entry_portal = level.primary_entry_portal
    else:
        var portal_idx: int = level.level_portals.find_custom(func (port: LevelPortal) -> bool: return port.id == entry_portal_id)
        if portal_idx >= 0:
            level.entry_portal = level.level_portals[portal_idx]
        else:
            push_warning("Portal '%s' not among level portals %s" % [
                entry_portal_id,
                level.level_portals.map(func (port: LevelPortal) -> String: return port.id),
            ])

            level.entry_portal = level.primary_entry_portal

    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        if level.grid_entities.has(persistable):
            level.grid_entities.erase(persistable)

        persistable.queue_free()

    var player_node: GridPlayer = null

    var player_save: Dictionary = DictionaryUtils.safe_getd(save_data, _PLAYER_KEY)
    if !GridPlayer.valid_save_data(player_save):
        GridPlayer.extend_save_with_portal_entry(player_save, level.entry_portal)

    if !player_save.is_empty():
        player_node = preload(_PLAYER_SCENE).instantiate()
        player_node.name = "Player Blob"
        level.add_child(player_node)
        player_node.load_from_save(level, player_save)
        level.player = player_node
    else:
        push_error("There was no player to load, this can't be handled")
        __SignalBus.on_critical_level_corrupt.emit(level.level_id)
        return

    var encounters_data: Dictionary = DictionaryUtils.safe_getd(save_data, _ENCOUNTERS_KEY, {}, false)
    var encounters_save: Dictionary[String, Dictionary] = {}
    if encounters_data is Dictionary[String, Dictionary]:
        encounters_save = encounters_data

    for encounter_node: Node in get_tree().get_nodes_in_group(encounter_group):
        if encounter_node is GridEncounter:
            var encounter: GridEncounter = encounter_node
            if encounters_save.has(encounter.encounter_id):
                # This requires that the new player instance has been loaded and set on the level
                encounter.load_from_save(level, encounters_save[encounter.encounter_id])
            else:
                encounter.load_from_save(level, {})
                push_warning("Encounter '%s' not present in save" % [encounter.encounter_id])

    var events_save: Dictionary = DictionaryUtils.safe_getd(save_data, _EVENTS_KEY, {}, false)
    for event_node: Node in get_tree().get_nodes_in_group(GridEvent.GRID_EVENT_GROUP):
        if event_node is GridEvent:
            var event: GridEvent = event_node
            var event_save: Variant = events_save.get(event.save_key())
            if event_save is Dictionary:
                @warning_ignore_start("unsafe_cast")
                event.load_save_data(event_save as Dictionary)
                @warning_ignore_restore("unsafe_cast")
            elif event.needs_saving():
                event.load_save_data({})
                push_warning("Event '%s' not present in save" % event.save_key())

    level.punishments.load_from_save(DictionaryUtils.safe_geta(save_data, _PUNISHMENT_DECK_KEY, []))

    var corpse_save: Dictionary = DictionaryUtils.safe_getd(save_data, _CORPSE_KEY, {}, false)
    if !corpse_save.is_empty():
        var corpse_scene: PackedScene = load("res://scenes/dungeon/corpse.tscn")
        var corpse: Corpse = corpse_scene.instantiate()
        corpse.load_from_save(level, corpse_save)

    level.emit_loaded = true
