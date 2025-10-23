extends Node
class_name SignalBusCore

@warning_ignore_start("unused_signal")
# Settings
signal on_update_input_mode(method: BindingHints.InputMode)
signal on_update_handedness(handedness: AccessibilitySettings.Handedness)

# Time
signal on_update_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int)
signal on_increment_day(day_of_month: int, days_until_end_of_month: int)

# Credits $$$
signal on_update_credits(credits: int)

# Saving and loading
signal on_before_save()
signal on_save_complete()
signal on_before_load()
signal on_load_complete()
signal on_load_fail()

# Scene transition
signal on_scene_transition_initiate(target_scene: String)
signal on_scene_transition_progress(progress: float)
signal on_scene_transition_complete(target_scene: String)
signal on_scene_transition_fail(target_scene: String)
signal on_scene_transition_new_scene_ready()

# Exploration
# -> Level
signal on_change_player(level: GridLevelCore, player: GridPlayerCore)
signal on_level_loaded(level: GridLevelCore)
signal on_level_unloaded(level: GridLevelCore)

# -> Grid Node
signal on_add_anchor(node: GridNode, anchor: GridAnchor)

# -> Zone
signal on_enter_zone(zone: LevelZone, entity: GridEntity)
signal on_exit_zone(zone: LevelZone, entity: GridEntity)
signal on_stay_zone(zone: LevelZone, entity: GridEntity)

# -> Grid Door
signal on_door_state_chaged(door: GridDoorCore, from: GridDoorCore.LockState, to: GridDoorCore.LockState)

# -> Exploration Message
## General purpose messaging to any who may be interested
signal on_broadcast_message(id: String, message: String)

# -> Grid Entity
signal on_move_start(entity: GridEntity, from: Vector3i, translation_direction: CardinalDirections.CardinalDirection)
signal on_move_end(entity: GridEntity)
signal on_update_orientation(
    entity: GridEntity,
    old_down: CardinalDirections.CardinalDirection,
    down: CardinalDirections.CardinalDirection,
    old_forward: CardinalDirections.CardinalDirection,
    forward: CardinalDirections.CardinalDirection,
)
signal on_cinematic(entity: GridEntity, cinematic: bool)

# -> Gride Node Feature
signal on_change_node(feature: GridNodeFeature)
signal on_change_anchor(feature: GridNodeFeature)

# --> Teleporter
signal on_teleporter_activate(teleporter: GridTeleporter, entity: GridEntity, target: GridTeleporter)
signal on_teleporter_arrive_entity(teleporter: GridTeleporter, entity: GridEntity)

# -> Interactable
signal on_allow_interactions(interactable: Interactable)
signal on_disallow_interactions(interactable: Interactable)

@warning_ignore_restore("unused_signal")
