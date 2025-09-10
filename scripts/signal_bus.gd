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

# Robot
signal on_robot_death(robot: Robot)
signal on_robot_complete_fight(robot: Robot)
signal on_robot_loaded(robot: Robot)

# Battle
signal on_entity_join_battle(entity: BattleEntity)
signal on_entity_leave_battle(entity: BattleEntity)
signal on_battle_start()
signal on_battle_end()

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

# -> Player
signal on_player_select_targets(
    player: BattlePlayer,
    count: int,
    options: Array[BattleEntity],
    effect: BattleCardPrimaryEffect.EffectMode,
    target_type: BattleCardPrimaryEffect.EffectTarget,
)
signal on_player_select_targets_complete(player: BattlePlayer)
signal on_before_execute_effect_on_target(player: BattlePlayer, target: BattleEntity)
signal on_after_execute_effect_on_target(player: BattlePlayer, target: BattleEntity)

# -> Player Hand
signal on_draw_new_player_card(player: BattlePlayer, card: BattleCard)
signal on_player_hand_drawn
signal on_player_hand_actions_complete
signal on_player_hand_debug(msg: String)

# -> Enemy
signal on_prepare_enemy_hand(battle_enemy: BattleEnemy, slotted_cards: Array[BattleCardData])
signal on_show_enemy_card(battle_enemy: BattleEnemy, card_index: int, card: BattleCardData, suit_bonus: int, rank_bonus: int)
signal on_play_enemy_card(battle_enemy: BattleEnemy, card_index: int)
signal on_hide_enemy_card(battle_enemy: BattleEnemy, card_index: int)

# Inventory
signal on_add_to_inventory(inventory: Inventory, id: String, amount: float, total: float)
signal on_remove_from_inventory(inventory: Inventory, id: String, amount: float, total: float)
signal on_load_inventory(inventory: Inventory)
signal on_activate_inventory(inventory: Inventory)
signal on_deactivate_inventory(inventory: Inventory)

@warning_ignore_restore("unused_signal")
