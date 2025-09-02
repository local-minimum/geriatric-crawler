extends Node
class_name SaveSystem

const _APPLICATION_KEY: String = "application"
const _VERSION_KEY: String = "version"
const _LOCALE_KEY: String = "locale"
const _PLATFORM_KEY: String = "platform"

const _GLOBAL_GAME_STATE_KEY: String = "global_state"
const _LEVEL_HISTORY_KEY: String = "level_history"
const _LEVEL_TO_LOAD_KEY: String = "level_to_load"
const _TOTAL_PLAYTIME_KEY: String = "total_playtime"
const _SESSION_PLAYTIME_KEY: String = "session_playtime"
const _SAVE_TIME_KEY: String = "save_datetime"

const _LEVEL_SAVE_KEY: String = "levels"

static var _current_save_slot: int
static var _current_save: Dictionary
static var _session_start: int
static var _previous_session_time_at_save: int
static var instance: SaveSystem

@export var storage_provider: SaveStorageProvider

@export var level_saver: LevelSaver

## Loads before level has been loaded
@export var extensions: Array[SaveExtension] = []
## Load after level has been loaded
@export var late_extensions: Array[SaveExtension] = []

@export var migrations: Array[SaveVersionMigration] = []

## Emitted if loading fails
signal load_fail(slot: int)

## Emitted if saving fails
signal save_fail(slot: int)

func _init() -> void:
    if !OS.request_permissions():
        print_debug("We don't have permissions enough to load and save game probably")

    if _session_start == 0:
        _session_start = Time.get_ticks_msec()

func _enter_tree() -> void:
    instance = self

func _exit_tree() -> void:
    if instance == self:
        instance = null

func save_slot(slot: int) -> void:
    if _current_save == null || _current_save.is_empty():
        _current_save = _load_save_data_or_default_initial_data(slot)

    var data: Dictionary = _collect_save_data(_current_save)

    if !storage_provider.store_data(slot, data):
        push_error("Failed to save to slot %s using %s" % [slot, storage_provider])
        save_fail.emit(slot)
        return

    _current_save = data
    _current_save_slot = slot
    print_debug("Saved %s to slot %s" % [_current_save, _current_save_slot])

func save_last_slot() -> void:
    save_slot(_current_save_slot)

func _collect_levels_save_data(save_data: Dictionary) -> Dictionary:
    if level_saver == null:
        return save_data.get(_LEVEL_SAVE_KEY)

    var updated_levels: Dictionary = {}
    if save_data.has(_LEVEL_SAVE_KEY):
        var levels: Dictionary = save_data[_LEVEL_SAVE_KEY]
        updated_levels = levels.duplicate()

    var current_level: String = level_saver.get_level_name()

    @warning_ignore_start("return_value_discarded")
    updated_levels.erase(current_level)
    @warning_ignore_restore("return_value_discarded")
    updated_levels[current_level] = level_saver.collect_save_state()

    return updated_levels

func _collect_save_data(save_data: Dictionary) -> Dictionary:
    var updated_save_data: Dictionary = {
        _APPLICATION_KEY: _collect_application_save_data(),
        _GLOBAL_GAME_STATE_KEY: _collect_global_game_save_data(save_data),
        _LEVEL_SAVE_KEY: _collect_levels_save_data(save_data),
    }

    for extension: SaveExtension in extensions + late_extensions:
        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if updated_save_data.has(key):
            var existing_data: Dictionary = updated_save_data[key]
            updated_save_data[key] = extension.retrieve_data(existing_data)
        else:
            updated_save_data[key] = extension.retrieve_data({})

    return updated_save_data

func _get_current_app_version() -> Version:
    var version: Version = Version.new()
    var version_string: String = ProjectSettings.get_setting("application/config/version")
    version.set_version(version_string)
    return version

func _collect_application_save_data() -> Dictionary:
    return {
        _VERSION_KEY: _get_current_app_version().get_version(),
        _LOCALE_KEY: OS.get_locale(),
        _PLATFORM_KEY: OS.get_name(),
    }

func _collect_global_game_save_data(save_data: Dictionary) -> Dictionary:

    var session_playtime: int = Time.get_ticks_msec() - _session_start
    var total_playtime: int = save_data[_GLOBAL_GAME_STATE_KEY][_TOTAL_PLAYTIME_KEY] - _previous_session_time_at_save + session_playtime

    var level_history: Array[String] = save_data[_GLOBAL_GAME_STATE_KEY][_LEVEL_HISTORY_KEY]
    if level_saver != null:
        var current_level: String = level_saver.get_level_name()
        if level_history.size() == 0 || level_history[level_history.size() - 1] != current_level:
            level_history = level_history + ([current_level] as Array[String])

    return {
        _LEVEL_HISTORY_KEY: level_history,
        _LEVEL_TO_LOAD_KEY: save_data.get(_LEVEL_TO_LOAD_KEY, "") if level_saver == null else level_saver.get_level_to_load(),
        _TOTAL_PLAYTIME_KEY: total_playtime,
        _SESSION_PLAYTIME_KEY: session_playtime,
        _SAVE_TIME_KEY: Time.get_datetime_string_from_system(true),
    }

func _collect_inital_global_game_save_data() -> Dictionary:
    # We are starting a new game, we should reset play session
    _session_start = Time.get_ticks_msec()

    return {
        _LEVEL_HISTORY_KEY: [] as Array[String],
        _LEVEL_TO_LOAD_KEY: "" if level_saver == null else level_saver.get_level_to_load(),
        _TOTAL_PLAYTIME_KEY: 0,
        _SESSION_PLAYTIME_KEY: 0,
        _SAVE_TIME_KEY: Time.get_date_string_from_system(true),
    }

func _load_save_data_or_default_initial_data(slot: int) -> Dictionary:
    var data: Dictionary = storage_provider.retrieve_data(slot)
    if !data.is_empty():
        return data

    print_debug("This is an entirely new save slot")

    data = {
        _APPLICATION_KEY: _collect_application_save_data(),
        _GLOBAL_GAME_STATE_KEY: _collect_inital_global_game_save_data(),
        _LEVEL_SAVE_KEY: {} if level_saver == null else {
            level_saver.get_level_name(): level_saver.get_initial_save_state()
        },
    }

    for extension: SaveExtension in extensions:
        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if data.has(key):
            var existing_data: Dictionary = data[key]
            data[key] = extension.initial_data(existing_data)
        else:
            data[key] = extension.initial_data({})

    return data

func load_slot(slot: int) -> bool:
    var data: Dictionary = storage_provider.retrieve_data(slot)
    if data.is_empty() || data == null:
        push_error("Failed to load from slot %s using %s" % [slot, storage_provider])
        load_fail.emit(slot)
        return false

    # Migrate old saves
    var current_version: Version = _get_current_app_version()
    var save_version: Version = Version.new()
    var save_version_string: String = data[_APPLICATION_KEY][_VERSION_KEY]
    save_version.set_version(save_version_string)

    if save_version.lower(current_version):
        for migration: SaveVersionMigration in migrations:
            if migration.applicable(save_version):
                data = migration.migrate_save(data)

    _current_save = data

    if level_saver == null || get_next_scene_id() != level_saver.get_level_name():
        return false

    if load_cached_save():
        print_debug("Loaded save slot %s" % slot)
        return true

    return false

func load_cached_save() -> bool:
    var data: Dictionary = _current_save
    var wanted_level: String = data[_GLOBAL_GAME_STATE_KEY][_LEVEL_TO_LOAD_KEY]

    # Load extension save data
    for extension: SaveExtension in extensions:
        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if data.has(key):
            var extension_save: Dictionary = data[key]
            extension.load_from_data(extension_save)
        elif extension.load_from_initial_if_save_missing():
            extension.load_from_data(extension.initial_data({}))
        else:
            push_warning("Save extension '%s' doesn't have any data in save" % key)

    # Load save for current level
    if data.has(_LEVEL_SAVE_KEY):
        var levels_data: Dictionary = data[_LEVEL_SAVE_KEY]
        if levels_data.has(wanted_level):
            var level_data: Dictionary = levels_data[wanted_level]
            level_saver.load_from_save(level_data)
        else:
            push_warning("Level %s not in %s" % [wanted_level, levels_data])
            level_saver.load_from_save(level_saver.get_initial_save_state())
    else:
        push_warning("No levels info in save %s" % data)
        level_saver.load_from_save(level_saver.get_initial_save_state())

    # Load late extension save data
    for extension: SaveExtension in late_extensions:
        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if data.has(key):
            var extension_save: Dictionary = data[key]
            extension.load_from_data(extension_save)
        elif extension.load_from_initial_if_save_missing():
            extension.load_from_data(extension.initial_data({}))
        else:
            push_warning("Save extension '%s' doesn't have any data in save" % key)

    return true

static func get_next_scene_id() -> String:
    var global_state: Dictionary = DictionaryUtils.safe_getd(_current_save, _GLOBAL_GAME_STATE_KEY, {}, false)
    return DictionaryUtils.safe_gets(global_state, _LEVEL_TO_LOAD_KEY, "", false)

func load_last_save() -> bool:
    return load_slot(_current_save_slot)
