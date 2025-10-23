extends Node
class_name SaveSystem

const _APPLICATION_KEY: String = "application"
const _VERSION_KEY: String = "version"
const _LOCALE_KEY: String = "locale"
const _PLATFORM_KEY: String = "platform"

const _GLOBAL_GAME_STATE_KEY: String = "global_state"
const _LEVEL_HISTORY_KEY: String = "level_history"
const _LEVEL_TO_LOAD_KEY: String = "level_to_load"
const _LEVEL_TO_LOAD_PORTAL_KEY: String = "level_to_load_portal"
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

    var current_level: String = level_saver.get_level_id()

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
        if extension == null:
            push_warning("save system %s has empty extension slot" % self)
            continue

        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if updated_save_data.has(key):
            var existing_data: Dictionary = updated_save_data[key]
            updated_save_data[key] = extension.retrieve_data(existing_data)
        else:
            updated_save_data[key] = extension.retrieve_data({})

    return updated_save_data

func _collect_application_save_data() -> Dictionary:
    return {
        _VERSION_KEY: Version.current.get_version_string(),
        _LOCALE_KEY: OS.get_locale(),
        _PLATFORM_KEY: OS.get_name(),
    }

func _collect_global_game_save_data(save_data: Dictionary) -> Dictionary:

    var session_playtime: int = Time.get_ticks_msec() - _session_start
    var total_playtime: int = save_data[_GLOBAL_GAME_STATE_KEY][_TOTAL_PLAYTIME_KEY] - _previous_session_time_at_save + session_playtime

    var level_history: Array[String] = save_data[_GLOBAL_GAME_STATE_KEY][_LEVEL_HISTORY_KEY]
    if level_saver != null:
        var current_level: String = level_saver.get_level_id()
        if level_history.size() == 0 || level_history[level_history.size() - 1] != current_level:
            level_history = level_history + ([current_level] as Array[String])

    return {
        _LEVEL_HISTORY_KEY: level_history,
        _LEVEL_TO_LOAD_KEY: save_data.get(_LEVEL_TO_LOAD_KEY, "") if level_saver == null else level_saver.get_level_to_load(),
        _LEVEL_TO_LOAD_PORTAL_KEY: save_data.get(_LEVEL_TO_LOAD_PORTAL_KEY, "") if level_saver == null else level_saver.get_level_to_load_entry_portal_id(),
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
        _LEVEL_TO_LOAD_PORTAL_KEY: "" if level_saver == null else level_saver.get_level_to_load_entry_portal_id(),
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
            level_saver.get_level_id(): level_saver.get_initial_save_state()
        },
    }

    for extension: SaveExtension in extensions:
        if extension == null:
            push_warning("save system %s has empty extension slot" % self)
            continue

        var key: String = extension.get_key()
        if key.is_empty():
            continue

        if data.has(key):
            var existing_data: Dictionary = data[key]
            data[key] = extension.initial_data(existing_data)
        else:
            data[key] = extension.initial_data({})

    return data

func _load_slot_into_cache(slot: int) -> bool:
    var data: Dictionary = storage_provider.retrieve_data(slot)
    if data.is_empty() || data == null:
        push_error("Failed to load from slot %s using %s" % [slot, storage_provider])
        load_fail.emit(slot)
        return false

    # Migrate old saves
    var current_version: Version = Version.current
    var save_version_string: String = data[_APPLICATION_KEY][_VERSION_KEY]
    var save_version: Version = Version.new(save_version_string)

    if save_version.lower(current_version):
        for migration: SaveVersionMigration in migrations:
            if migration == null:
                push_warning("Save system %s has empty migration slot" % self)
                continue

            if migration.applicable(save_version):
                data = migration.migrate_save(data)

    _current_save = data
    return true

func can_load_cach_onto_this_level() -> bool:
    return level_saver != null && get_loading_level_id() == level_saver.get_level_id()

func load_slot(slot: int) -> bool:
    if !_load_slot_into_cache(slot):
        return false

    if !can_load_cach_onto_this_level():
        push_error("Failed to load from slot %s using %s because of next scene id missmach %s vs %s" % [
            slot,
            storage_provider,
            get_loading_level_id(),
            level_saver.get_level_id()])
        return false

    if load_cached_save():
        print_debug("Loaded save slot %s" % slot)
        return true

    return false

func load_cached_save() -> bool:
    var data: Dictionary = _current_save
    var global_state: Dictionary = DictionaryUtils.safe_getd(_current_save, _GLOBAL_GAME_STATE_KEY, {}, false)
    var wanted_level: String = DictionaryUtils.safe_gets(global_state, _LEVEL_TO_LOAD_KEY, "", false)
    var wanted_level_portal: String = DictionaryUtils.safe_gets(global_state, _LEVEL_TO_LOAD_PORTAL_KEY, "", false)

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
        elif extension.warn_missing:
            push_warning("Save extension '%s' doesn't have any data in save" % key)

    # Load save for current level
    if data.has(_LEVEL_SAVE_KEY):
        var levels_data: Dictionary = data[_LEVEL_SAVE_KEY]
        if levels_data.has(wanted_level):
            var level_data: Dictionary = levels_data[wanted_level]
            level_saver.load_from_save(level_data, wanted_level_portal)
        else:
            print_debug("Level %s has not been visited before, spawning in at start")
            level_saver.load_from_save(level_saver.get_initial_save_state(), wanted_level_portal)
    else:
        push_warning("No levels info in save %s" % data)
        level_saver.load_from_save(level_saver.get_initial_save_state(), wanted_level_portal)

    # Load late extension save data
    for extension: SaveExtension in late_extensions:
        if extension == null:
            push_warning("save system %s has empty late extension slot" % self)
            continue

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

static func get_loading_level_id() -> String:
    var global_state: Dictionary = DictionaryUtils.safe_getd(_current_save, _GLOBAL_GAME_STATE_KEY, {}, false)
    return DictionaryUtils.safe_gets(global_state, _LEVEL_TO_LOAD_KEY, "", false)

func preload_last_save_into_cache() -> bool:
    return _load_slot_into_cache(_current_save_slot)

func load_last_save() -> bool:
    return load_slot(_current_save_slot)
