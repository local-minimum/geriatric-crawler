extends Node
class_name BattleMode

signal on_entity_join_battle(entity: BattleEntity)
signal on_entity_leave_battle(entity: BattleEntity)
signal on_new_card(card: BattleCard)
signal on_battle_start()
signal on_battle_end()

const LEVEL_GROUP: String = "battle-mode"

@export
var animator: AnimationPlayer

@export
var battle_hand: BattleHandManager

@export
var player_deck: BattleDeck

@export
var _active_cards: Control

@export
var _ui: CanvasLayer

@export
var battle_player: BattlePlayer

var trigger: GridEncounterEffect
var robot: Robot

const _battle_card_resource: PackedScene = preload("res://scenes/battle_card.tscn")
var _cards: Array[BattleCard] = []

var previous_card: BattleCardData
var rank_direction: int
var suit_bonus: int
var rank_bonus: int

static func find_battle_parent(current: Node, inclusive: bool = true) ->  BattleMode:
    if inclusive && current is BattleMode:
        return current as BattleMode

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is BattleMode:
        return parent as BattleMode

    return find_battle_parent(parent, false)

func _init() -> void:
    add_to_group(LEVEL_GROUP)

var _inited: bool

func _ready() -> void:
    if battle_hand.on_hand_drawn.connect(_after_deal) != OK:
        push_error("Failed to connect callback to hand dealt")
    if battle_hand.slots.on_update_slotted.connect(_handle_update_slotted):
        push_error("Failed to connect callback to slotted cards updated")
    if battle_hand.on_hand_actions_complete.connect(_start_playing_cards):
        push_error("Failed to connect callback to hand actions completed")

    _ui.visible = false
    _inited = true

var _next_active_enemy: int
var _player_initiative: int

func get_battling() -> bool:
    return _ui.visible && _inited

var _enemies: Array[BattleEnemy]
func get_enemies() -> Array[BattleEnemy]:
    return _enemies.duplicate()

func get_party() -> Array[BattlePlayer]:
    return [battle_player]

#region ENTER BATTLE
func enter_battle(battle_trigger: BattleModeTrigger, player_robot: Robot) -> void:
    on_battle_start.emit()

    _ui.visible = true

    # TODO: Gather proximate battle triggers too and pull them into the fight!
    # TODO: Consider need to wait for enemy to animate death before lettning new enter...

    trigger = battle_trigger
    robot = player_robot

    player_deck.load_deck(robot.get_deck())

    battle_player.max_health = robot.model.max_hp
    battle_player.validate_health()

    on_entity_join_battle.emit(battle_player)
    if battle_player.on_end_turn.connect(_next_agent_turn) != OK:
        push_error("Failed to connect player %s turn done" % battle_player)

    if battle_player.on_death.connect(_handle_player_death) != OK:
        push_error("Failed to connect player %s death" % battle_player)

    # Show all enemies and their stats
    _enemies.append_array(battle_trigger.enemies)
    for enemy: BattleEnemy in _enemies:
        if enemy.on_end_turn.connect(_next_agent_turn) != OK:
            push_error("Failed to connect enemy %s turn done" % enemy)
        if enemy.on_death.connect(_handle_enemy_death) != OK:
            push_error("Failed to connect enemy %s death" % enemy)

        on_entity_join_battle.emit(enemy)

    await get_tree().create_timer(0.5).timeout

    animator.play("fade_in_battle")

    await get_tree().create_timer(1.0).timeout

    if trigger.hide_encounter_on_trigger:
        trigger.encounter.visible = false

    # Show F I G H T
    await get_tree().create_timer(1.0).timeout

    round_start_prepare_hands()
#endregion ENTER BATTLE

#region PHASE DRAW AND SLOT CARDS
func round_start_prepare_hands() -> void:
    for enemy: BattleEnemy in _enemies:
        if !enemy.is_alive():
            continue

        enemy.prepare_hand()

    deal_player_hand()

const _HAND_SIZE: String = "hand"

func _get_hand_size() -> int:
    return robot.get_skill_level(_HAND_SIZE) + 4

func deal_player_hand() -> void:
    var cards: Array[BattleCard] = []
    cards.append_array(battle_hand.hand)
    var hand_size: int = _get_hand_size()
    var new_cards: int = hand_size - cards.size()

    var card_data: Array[BattleCardData] = player_deck.draw(new_cards)
    # print_debug("Hand should be %s, have %s remaining -> %s to draw, drew %s" % [
    #    hand_size,
    #    cards.size(),
    #    new_cards,
    #    card_data.size(),
    #])
    new_cards = mini(new_cards, card_data.size())

    var card_data_idx: int = 0
    # Resuse cards already instanced
    for card: BattleCard in _cards:
        if !card.card_played || cards.has(card):
            continue

        if card_data_idx >= new_cards:
            break

        card.data = card_data[card_data_idx]
        cards.append(card)

        card.visible = false
        card_data_idx += 1

    # Instance new cards
    while card_data_idx < new_cards:
        var new_card: BattleCard = _battle_card_resource.instantiate()
        new_card.visible = false
        new_card.data = card_data[card_data_idx]

        _active_cards.add_child(new_card)
        new_card.owner = _active_cards.get_tree().root
        new_card.visible = false

        _cards.append(new_card)
        cards.append(new_card)

        card_data_idx += 1

        on_new_card.emit(new_card)

    battle_hand.draw_hand(cards)

const _SUIT_SKILL: String = "suits"
func get_suit_bonus_step() -> int:
    match robot.get_skill_level(_SUIT_SKILL):
        0: return 0
        1: return 1
        2: return 3
        _:
            push_warning("Not implemented level %s skill for suits (skill '%s')" % [robot.get_skill_level(_SUIT_SKILL), _SUIT_SKILL])
            return 3

const _RANK_SKILL: String = "rank"
func get_rank_bonus_step() -> int:
    match robot.get_skill_level(_RANK_SKILL):
        0: return 0
        1: return 2
        2: return 2
        _:
            push_warning("Not implemented level %s skill for suits (skill '%s')" % [robot.get_skill_level(_RANK_SKILL), _RANK_SKILL])
            return 2

func get_rank_bonus_allow_descending() -> bool:
    return robot.get_skill_level(_RANK_SKILL) < 2

func _handle_update_slotted(cards: Array[BattleCard]) -> void:
    var acc_suit_bonus: int = suit_bonus
    var acc_rank_bonus: int = rank_bonus
    var current_rank_direction: int = rank_direction
    var prev_card: BattleCardData = previous_card

    var slotted_cards: Array[BattleCard]
    slotted_cards.append_array(cards)
    ArrayUtils.erase_all_occurances(slotted_cards, null)

    var idx: int = 0
    var suit_skill_step: int = get_suit_bonus_step()
    var rank_skill_step: int = get_rank_bonus_step()

    for card: BattleCard in slotted_cards:
        var next_card: BattleCardData = slotted_cards[idx + 1].data if idx + 1 < slotted_cards.size() else null
        acc_suit_bonus = battle_player.get_suit_bonus(card.data, acc_suit_bonus, suit_skill_step, prev_card, next_card, idx == 0)
        acc_rank_bonus = battle_player.get_rank_bonus(card.data, acc_rank_bonus, rank_skill_step, prev_card, current_rank_direction, next_card, idx == 0, get_rank_bonus_allow_descending())

        if prev_card != null:
            current_rank_direction = signi(card.data.rank - prev_card.rank)

        print_debug("%s with %s prev gets bonus %s (start bonus %s)" % [
            card.data.id, prev_card.id if prev_card != null else "[NONE]", acc_suit_bonus, suit_bonus])

        idx += 1

        card.sync_display(acc_suit_bonus + acc_rank_bonus)

        prev_card = card.data

const _SLOTS: String = "slots"

func _get_number_of_slots() -> int:
    return robot.get_skill_level(_SLOTS) + 1

func _after_deal() -> void:
    battle_hand.slots.show_slots(_get_number_of_slots())
#endregion PHASE DRAW AND SLOT CARDS

#region PHASE PLAY CARD
func _start_playing_cards() -> void:
    print_debug("Card actions phase")

    _next_active_enemy = 0

    _enemies.sort_custom(
        func (a: BattleEnemy, b: BattleEnemy) -> bool:
            if a != null && b == null:
                return true

            if a != null || b != null:
                return false

            return a.initiative() > b.initiative())

    var leading_player_card: BattleCard = battle_hand.slots.slotted_cards[0]
    if leading_player_card ==  null:
        _player_initiative = -1
        player_deck.discard_hand()
        battle_hand.hand.clear()
    else:
        _player_initiative = leading_player_card.data.rank

    await get_tree().create_timer(1).timeout
    _next_agent_turn(null)

func _next_agent_turn(_entity: BattleEntity) -> void:
    if !(await  _pass_action_turn()):
        _clean_up_round()

func _pass_action_turn() -> bool:
    var next_entity_timeout: float = 0.25

    var enemy_initiative: int = _next_enemy_initiative()
    if enemy_initiative == -1 && _player_initiative == -1:
        return false

    var enemies: Array[BattleEntity] = []
    enemies.append_array(_enemies)
    # TODO: Here's a HACK we are always only one player
    var player_party: Array[BattleEntity] = [battle_player]

    if _player_initiative >= enemy_initiative:
        await get_tree().create_timer(next_entity_timeout).timeout
        battle_player.play_actions(player_party, enemies)
        _player_initiative = -1
        return true

    await get_tree().create_timer(next_entity_timeout).timeout
    var enemy: BattleEnemy = _enemies[_next_active_enemy]
    enemy.play_actions(enemies, player_party)
    battle_hand.slots.hide_slotted_cards()
    _next_active_enemy += 1
    return true

func _next_enemy_initiative() -> int:
    if _next_active_enemy >= _enemies.size() || _enemies[_next_active_enemy] == null:
        return -1
    var enemy: BattleEnemy = _enemies[_next_active_enemy]
    if !enemy.is_alive():
        return -1

    return enemy.initiative()

func _handle_player_death(entity: BattleEntity) -> void:
    if entity == battle_player:
        for enemy: BattleEnemy in _enemies:
            enemy.end_turn_early()

    # TODO Handle party wipe better
    exit_battle()


var _ending_player_turn_early: bool

func _handle_enemy_death(entity: BattleEntity) -> void:
    var remaining_enemies: bool = _enemies.any(
        func (e: BattleEnemy) -> bool:
            return e.is_alive()
    )

    print_debug("%s died, any remaining %s" % [entity.name, remaining_enemies])

    if !remaining_enemies:
        battle_player.end_turn_early()
        if battle_player.on_after_execute_card.connect(exit_battle) == OK:
            _ending_player_turn_early = true
        else:
            push_error("Failed to connect after execute card on player %s" % battle_player)
            exit_battle()
#endregion PHASE PLAY CARD

#region PHASE CLEANUP
const _MEMORY: String = "memory"
func _remembers_bonus_end_of_round() -> bool: return robot.get_skill_level(_MEMORY) > 0

func _remembers_previous_end_of_round() -> bool: return robot.get_skill_level(_MEMORY) > 1

func _remembers_to_next_battle() -> bool: return robot.get_skill_level(_MEMORY) > 2

func _clean_up_round(exit_battle_cleanup: bool = false) -> void:
    _enemies = _enemies.filter(
        func (enemy: BattleEnemy) -> bool:
            if enemy.is_alive():
                return true

            on_entity_leave_battle.emit(enemy)
            enemy.on_end_turn.disconnect(_next_agent_turn)
            enemy.on_death.disconnect(_handle_enemy_death)
            enemy.clean_up_battle()
            return false
    )

    if !exit_battle_cleanup && _enemies.is_empty():
        exit_battle()
        return

    if !battle_player.is_alive():
        print_debug("WE DIES")
        return

    battle_hand.slots.hide_slotted_cards(exit_battle_cleanup)
    battle_player.clean_up_round()
    player_deck.discard_from_hand(battle_hand.round_end_cleanup())

    if !_remembers_bonus_end_of_round():
        suit_bonus = 0
        rank_bonus = 0

    if !_remembers_previous_end_of_round():
        previous_card = null

    if !exit_battle_cleanup:
        round_start_prepare_hands()
#endregion PHASE CLEANUP

#region END BATTLE
func exit_battle() -> void:
    if _ending_player_turn_early:
        battle_player.on_after_execute_card.disconnect(exit_battle)
        _ending_player_turn_early = false

    _clean_up_round(true)

    if !_remembers_to_next_battle():
        suit_bonus = 0
        rank_bonus = 0
        previous_card = null

    for enemy: BattleEnemy in _enemies:
        on_entity_leave_battle.emit(enemy)
        enemy.clean_up_battle()
        enemy.on_end_turn.disconnect(_next_agent_turn)
        enemy.on_death.disconnect(_handle_enemy_death)

    on_entity_leave_battle.emit(battle_player)
    battle_player.clean_up_battle()
    battle_player.on_end_turn.disconnect(_next_agent_turn)
    battle_player.on_death.disconnect(_handle_player_death)

    _enemies.clear()

    animator.play("fade_out_battle")
    await get_tree().create_timer(0.5).timeout
    trigger.complete()

    trigger = null
    if battle_player.is_alive():
        robot.complete_fight()
    else:
        robot.killed_in_fight()
    robot = null

    on_battle_end.emit()
    _ui.visible = false
#endregion END BATTLE
