extends Node
class_name SignalBus

@warning_ignore_start("unused_signal")

# Critical fails
signal on_critical_level_corrupt(level_id: String)

# Time
signal on_update_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int)
signal on_increment_day(day_of_month: int, days_until_end_of_month: int)

# Credits $$$
signal on_update_credits(credits: int, loans: int)
signal on_update_interest_rate(rate_points: int)
signal on_update_rent(rent: int)

# Spaceship
signal on_finalize_loadout(loadout: Dictionary)
signal on_before_deploy(level_id: String, robot: RobotData, duration_days: int, insured: bool)

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

# Battle Entities
# -> Shields
signal on_gain_shield(battle_entitiy: BattleEntity, shields: Array[int], new_shield: int)
signal on_break_shield(battle_entity: BattleEntity, shields: Array[int], broken_shield: int)

# -> Health
signal on_heal(battle_entity: BattleEntity, amount: int, new_health: int, overheal: bool)
signal on_hurt(battle_entity: BattleEntity, amount: int, new_health: int)
signal on_death(battle_entity: BattleEntity)

# -> Turns
signal on_start_turn(entity: BattleEntity)
signal on_end_turn(entity: BattleEntity)

# Inventory
signal on_add_to_inventory(inventory: Inventory, id: String, amount: float, total: float)
signal on_remove_from_inventory(inventory: Inventory, id: String, amount: float, total: float)
signal on_load_inventory(inventory: Inventory)
signal on_activate_inventory(inventory: Inventory)
signal on_deactivate_inventory(inventory: Inventory)

@warning_ignore_restore("unused_signal")
