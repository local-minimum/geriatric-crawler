extends GridEncounterCore
class_name GridEncounter

static var _ENEMY_GAINED_CARDS_KEY: String = "gained-cards"

func save() -> Dictionary:
    var data: Dictionary = super.save()
    var enemy_cards: Dictionary[String, Array] = _collect_enemy_gained_cards()
    if !enemy_cards.is_empty():
        data[_ENEMY_GAINED_CARDS_KEY] = enemy_cards

    return data

func load_from_save(level: GridLevelCore, save_data: Dictionary) -> void:
    if !_valid_save_data(save_data):
        _reset_starting_condition()
        return

    super.load_from_save(level, save_data)

    var enemy_cards: Dictionary = DictionaryUtils.safe_getd(save_data, _ENEMY_GAINED_CARDS_KEY, {}, false)
    _load_enemy_cards(enemy_cards)

func _reset_starting_condition() -> void:
    super._reset_starting_condition()

    if effect is BattleModeTrigger:
        var trigger: BattleModeTrigger = effect
        for enemy: BattleEnemy in trigger.enemies:
            enemy.deck.restore_start_deck()

    _triggered = false

func _load_enemy_cards(enemy_cards: Dictionary) -> void:
    if effect is not BattleModeTrigger:
        return

    var trigger: BattleModeTrigger = effect
    for enemy: BattleEnemy in trigger.enemies:
        enemy.deck.restore_start_deck()

        var enemy_gained_cards: Array = DictionaryUtils.safe_geta(enemy_cards, enemy.id, [], false)
        for id: Variant in enemy_gained_cards:
            if id is not String:
                push_warning("%s is not a string value (expected on %s in %s)" % [id, enemy_gained_cards])
                continue

            var card_id: String = id
            var card: BattleCardData = BattleCardData.get_card_by_id(BattleCardData.CardCategory.Enemy, card_id, enemy.variant_id)
            if card == null:
                card = BattleCardData.get_card_by_id(BattleCardData.CardCategory.Punishment, card_id)
                if card == null:
                    push_warning("%s (%s): %s couldn't be found among enemy or punishment cards" % [enemy.variant_id, enemy.id, card_id])
                elif card.card_owner != BattleCardData.Owner.ENEMY:
                    push_warning("%s is not an enemy card but %s" % [card_id, BattleCardData.name_owner(card.card_owner)])
                else:
                    enemy.deck.gain_card(card)
            else:
                enemy.deck.gain_card(card)

func _collect_enemy_gained_cards() -> Dictionary[String, Array]:
    if effect is not BattleModeTrigger:
        return {}

    var trigger: BattleModeTrigger = effect

    var cards: Dictionary[String, Array] = {}

    for enemy: BattleEnemy in trigger.enemies:
        var enemy_cards: Array[String] = enemy.deck.get_gained_card_ids()
        if enemy_cards.is_empty():
            continue

        cards[enemy.id] = enemy_cards

    return cards

func kill() -> void:
    _triggered = true

    if effect is BattleModeTrigger:
        var trigger: BattleModeTrigger = effect
        if trigger.reward_environmental_kill:
            for enemy: BattleEnemy in trigger.enemies:
                __GlobalGameState.deposit_credits(enemy.carried_credits)

    if repeatable:
        var node: GridNode = get_grid_node()
        if node == null:
            push_error("Encounter %s is out of bounds at %s, killed and repeatable!" % [name, coordinates()])
            return

        for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
            if node.may_exit(self, direction, true, true):
                var neighbour: GridNode = node.neighbour(direction)
                if neighbour == null:
                    continue

                if neighbour.may_enter(self, node, direction, get_grid_anchor_direction(), false, true, true):
                    var anchor: GridAnchor = neighbour.get_grid_anchor(get_grid_anchor_direction())
                    if anchor != null:
                        set_grid_anchor(anchor)
                    else:
                        set_grid_node(neighbour)

                    sync_position()
                    break
