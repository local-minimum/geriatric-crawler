extends LevelSaver

const _PLAYER_KEY: String = "player"
const _ENCOUNTERS_KEY: String = "encounters"

# TODO: Should not be hardcoded static
const _PLAYER_SCENE: String = "res://scenes/dungeon/player.tscn"

@export
var persistant_group: String = "Persistant"

@export
var encounter_group: String = "Encounter"

@export
var level: GridLevel

@export
var level_name: String = "demo"

func _ready() -> void:
    if level == null:
        var node: Node = get_tree().get_first_node_in_group(GridLevel.LEVEL_GROUP)
        if node != null:
            level = node
        else:
            push_error("Could not find a level in '%s', won't be able to load saves" % GridLevel.LEVEL_GROUP)

func get_level_name() -> String:
    return level_name

## Collect save information for this particular level
func collect_save_state() -> Dictionary:
    var encounters_save: Dictionary[String, Dictionary] = {}
    var save_state: Dictionary = {
        _ENCOUNTERS_KEY: encounters_save,
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
                push_error("Level %s has duplicate encounters with id '%s'" % [level_name, encounter.encounter_id])

            encounters_save[encounter.encounter_id] = encounter.save()

    print_debug("Saved level %s" % level_name)

    return save_state

func get_initial_save_state() -> Dictionary:
    var save_state: Dictionary = {
        _PLAYER_KEY: level.player.initial_state(),
        _ENCOUNTERS_KEY: {}, # We just assume they are as they should be
    }

    return save_state

## Load part of save that holds this particular level
func load_from_save(save_data: Dictionary) -> void:
    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        persistable.queue_free()

    if save_data.has(_PLAYER_KEY):
        var player_save: Dictionary = save_data[_PLAYER_KEY]
        var player_node: GridPlayer = preload(_PLAYER_SCENE).instantiate()
        level.add_child(player_node)
        player_node.load_from_save(level, player_save)

    if save_data.has(_ENCOUNTERS_KEY):
        var encounters_save: Dictionary[String, Dictionary] = save_data[_ENCOUNTERS_KEY]

        for encounter_node: Node in get_tree().get_nodes_in_group(encounter_group):
            if encounter_node is GridEncounter:
                var encounter: GridEncounter = encounter_node
                if encounters_save.has(encounter.encounter_id):
                    encounter.load_from_save(level, encounters_save[encounter.encounter_id])
                else:
                    push_warning("Encounter '%s' not present in save" % [encounter.encounter_id])
    else:
        push_warning("Level has no encounters save data")
    print_debug("Level %s loaded" % level_name)
