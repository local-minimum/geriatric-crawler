extends Node
class_name BattleMode

signal on_entity_join_battle(entity: BattleEntity)
signal on_entity_leave_battle(entity: BattleEntity)
signal on_new_card(card: BattleCard)

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

var suit_crit_bonus: int = 0
var rank_crit_bonus: int = 0

const _battle_card_resource: PackedScene = preload("res://scenes/battle_card.tscn")
var _cards: Array[BattleCard] = []

func _ready() -> void:
    if battle_hand.on_hand_drawn.connect(_after_deal) != OK:
        push_error("Failed to connect callback to hand dealt")
    if battle_hand.slots.on_update_slotted.connect(_handle_update_slotted):
        push_error("Failed to connect callback to slotted cards updated")
    if battle_hand.on_hand_actions_complete.connect(_start_playing_cards):
        push_error("Failed to connect callback to hand actions completed")

    _ui.visible = false

var _next_active_enemy: int
var _player_initiative: int

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
    else:
        _player_initiative = leading_player_card.data.rank

    await get_tree().create_timer(1).timeout
    _next_agent_turn(null)

func _next_agent_turn(_entity: BattleEntity) -> void:
    if !(await  _pass_action_turn()):
        _clean_up_round()

func _clean_up_round(exit_battle_cleanup: bool = false) -> void:
    _enemies = _enemies.filter(
        func (enemy: BattleEnemy) -> bool:
            if enemy.is_alive():
                return true

            on_entity_leave_battle.emit(enemy)
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

    if !exit_battle_cleanup:
        round_start_prepare_hands()

func _next_enemy_initiative() -> int:
    if _next_active_enemy >= _enemies.size() || _enemies[_next_active_enemy] == null:
        return -1
    var enemy: BattleEnemy = _enemies[_next_active_enemy]
    if !enemy.is_alive():
        return -1

    return enemy.initiative()

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

func _handle_update_slotted(cards: Array[BattleCard]) -> void:
    var acc_suit_bonus: int
    var prev_card: BattleCardData = null

    var slotted_cards: Array[BattleCard]
    slotted_cards.append_array(cards)
    ArrayUtils.erase_all_occurances(slotted_cards, null)

    var idx: int = 0

    for card: BattleCard in slotted_cards:
        var next_card: BattleCardData = slotted_cards[idx + 1].data if idx + 1 < slotted_cards.size() else null
        acc_suit_bonus = battle_player.get_suit_bonus(card.data, acc_suit_bonus, prev_card, next_card, idx == 0)

        idx += 1

        card.sync_display(acc_suit_bonus)

        prev_card = card.data

var _enemies: Array[BattleEnemy]

func enter_battle(battle_trigger: BattleModeTrigger) -> void:
    _ui.visible = true

    # TODO: Gather proximate battle triggers too and pull them into the fight!
    # TODO: Consider need to wait for enemy to animate death before lettning new enter...

    trigger = battle_trigger

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

func _handle_player_death(entity: BattleEntity) -> void:
    if entity == battle_player:
        for enemy: BattleEnemy in _enemies:
            enemy.halt_actions()

    # TODO Handle party wipe better
    exit_battle()


func _handle_enemy_death(entity: BattleEntity) -> void:
    var remaining_enemies: bool = _enemies.any(
        func (e: BattleEnemy) -> bool:
            return e.is_alive()
    )

    print_debug("%s died, any remaining %s" % [entity.name, remaining_enemies])

    if !remaining_enemies:
        battle_player.halt_actions()
        exit_battle()

func round_start_prepare_hands() -> void:
    for enemy: BattleEnemy in _enemies:
        if !enemy.is_alive():
            continue

        enemy.prepare_hand()

    deal_player_hand()

func deal_player_hand() -> void:
    # TODO: Something should manage hand size
    var cards: Array[BattleCard] = []
    cards.append_array(battle_hand.hand)
    var hand_size: int = 6
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

func _after_deal() -> void:
    battle_hand.slots.show_slots(3)

func exit_battle() -> void:
    _clean_up_round(true)

    for enemy: BattleEnemy in _enemies:
        on_entity_leave_battle.emit(enemy)
        enemy.on_end_turn.disconnect(_next_agent_turn)

    on_entity_leave_battle.emit(battle_player)
    battle_player.on_end_turn.disconnect(_next_agent_turn)

    _enemies.clear()

    animator.play("fade_out_battle")
    await get_tree().create_timer(0.5).timeout
    trigger.complete()

    _ui.visible = false
