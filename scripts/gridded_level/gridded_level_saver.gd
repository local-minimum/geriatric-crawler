extends LevelSaver

const _PLAYER_KEY: String = "player"
const _PLAYER_SCENE: String = "res://scenes/dungeon/player.tscn"

@export
var persistant_group: String = "Persistant"

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

func collect_save_state() -> Dictionary:
    var save_state: Dictionary = {}

    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        if persistable is GridPlayer:
            if save_state.has(_PLAYER_KEY):
                push_error("Level can only save one player, ignoring %s" % persistable.name)
            save_state[_PLAYER_KEY] = (persistable as GridPlayer).save()

    print_debug("Saved level %s" % level_name)

    return save_state

func get_initial_save_state() -> Dictionary:
    var save_state: Dictionary = {
        _PLAYER_KEY: level.player.initial_state()
    }

    return save_state

func load_from_save(save_data: Dictionary) -> void:
    for persistable: Node in get_tree().get_nodes_in_group(persistant_group):
        persistable.queue_free()

    if save_data.has(_PLAYER_KEY):
        var player_save: Dictionary = save_data[_PLAYER_KEY]
        var player_node: GridPlayer = preload(_PLAYER_SCENE).instantiate()
        level.add_child(player_node)
        player_node.load_from_save(level, player_save)

    print_debug("Level %s loaded" % level_name)
