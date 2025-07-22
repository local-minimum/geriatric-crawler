extends LevelSaver

const _LEVEL_ID_KEY: String = "id"
const _PLAYER_KEY: String = "player"
const _ENCOUNTERS_KEY: String = "encounters"
const _EVENTS_KEY: String = "events"

# TODO: Should not be hardcoded static
const _PLAYER_SCENE: String = "res://scenes/dungeon/player.tscn"

@export
var persistant_group: String = "Persistant"

@export
var encounter_group: String = "Encounter"

@export
var level: GridLevel

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

## Collect save information for this particular level
func collect_save_state() -> Dictionary:
    var encounters_save: Dictionary[String, Dictionary] = {}
    var events_save: Dictionary[String, Dictionary] = {}

    var save_state: Dictionary = {
        _ENCOUNTERS_KEY: encounters_save,
        _EVENTS_KEY: events_save,
    }

    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        if persistable is GridPlayer:
            if save_state.has(_PLAYER_KEY):
                push_error("Level can only save one player, ignoring %s" % persistable.name)
            save_state[_PLAYER_KEY] = (persistable as GridPlayer).save()


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

    print_debug("Saved level %s" % get_level_name())

    return save_state

func get_initial_save_state() -> Dictionary:
    var save_state: Dictionary = {
        _LEVEL_ID_KEY: null,
        _PLAYER_KEY: level.player.initial_state(),
        _ENCOUNTERS_KEY: {}, # We just assume they are as they should be
        _EVENTS_KEY: {},
    }

    return save_state

## Load part of save that holds this particular level
func load_from_save(save_data: Dictionary) -> void:
    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        persistable.queue_free()

    var player_node: GridPlayer = null

    if save_data.has(_PLAYER_KEY):
        var player_save: Dictionary = DictionaryUtils.safe_getd(save_data, _PLAYER_KEY)
        player_node = preload(_PLAYER_SCENE).instantiate()
        player_node.name = "Player Blob"
        level.add_child(player_node)
        player_node.load_from_save(level, player_save)
        level.player = player_node

    var encounters_data: Dictionary = DictionaryUtils.safe_getd(save_data, _ENCOUNTERS_KEY)
    if encounters_data is Dictionary[String, Dictionary]:
        var encounters_save: Dictionary[String, Dictionary] = encounters_data

        for encounter_node: Node in get_tree().get_nodes_in_group(encounter_group):
            if encounter_node is GridEncounter:
                var encounter: GridEncounter = encounter_node
                if encounters_save.has(encounter.encounter_id):
                    # This requires that the new player instance has been loaded and set on the level
                    encounter.load_from_save(level, encounters_save[encounter.encounter_id])
                else:
                    push_warning("Encounter '%s' not present in save" % [encounter.encounter_id])
    else:
        push_warning("Level has no encounters save data")

    var events_save: Dictionary = DictionaryUtils.safe_getd(save_data, _EVENTS_KEY)
    if !events_save.is_empty():
        if events_save is Dictionary[String, Variant]:
            for event_node: Node in get_tree().get_nodes_in_group(GridEvent.GRID_EVENT_GROUP):
                if event_node is GridEvent:
                    var event: GridEvent = event_node
                    if !event.needs_saving():
                        continue

                    if events_save.has(event.save_key()):
                        event.load_save_data(events_save[event.save_key()])
                    else:
                        push_warning("Event '%s' not present in save" % event.save_key())

    print_debug("Level %s loaded" % get_level_name())
