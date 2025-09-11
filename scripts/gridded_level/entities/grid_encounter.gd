extends GridEntity
class_name GridEncounter

static var _TRIGGERED_KEY: String = "triggered"
static var _ENEMY_GAINED_CARDS_KEY: String = "gained-cards"
static var _ID_KEY: String = "id"

enum EncounterMode { NEVER, NODE, ANCHOR }

## When encounters trigger, be it never, when player collides on same node, or when player collides on same anchor
@export var encounter_mode: EncounterMode = EncounterMode.NODE

@export var encounter_id: String

@export var repeatable: bool = true

@export var effect: GridEncounterEffect

@export var graphics: MeshInstance3D

@export var _spawn_node: GridNode

@export var _start_anchor_direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

var _triggered: bool
var _was_on_node: bool

func _ready() -> void:
    if _spawn_node != null:
        var anchor: GridAnchor = _spawn_node.get_grid_anchor(_start_anchor_direction)
        if anchor == null:
            push_error("%s doesn't have anchor in %s direction" % [
                _spawn_node.name,
                CardinalDirections.name(_start_anchor_direction),
            ])
        update_entity_anchorage(_spawn_node, anchor, true)
        sync_position()

    super._ready()

    _connect_player_callbacks(get_level())

    effect.prepare(self)

var _connected_player: GridPlayer

func _connect_player_callbacks(level: GridLevel) -> void:
    if _connected_player == level.player:
        return
    elif _connected_player != null:
        _disconnect_player_callbacks()

    if level != null:
        if level.player.on_change_anchor.connect(_check_colliding_anchor) != OK:
            push_error("%s failed to connect to player anchor change signal" % name)
        if level.player.on_change_node.connect(_check_colliding_node) != OK:
            push_error("%s failed to connect to player node change signal" % name)
        _connected_player = level.player
    else:
        push_error("%s is not part of a level" % name)

func _disconnect_player_callbacks() -> void:
    if _connected_player == null:
        return

    _connected_player.on_change_anchor.disconnect(_check_colliding_anchor)
    _connected_player.on_change_node.disconnect(_check_colliding_node)
    _connected_player = null


func _check_colliding_anchor(feature: GridNodeFeature) -> void:
    if encounter_mode != EncounterMode.ANCHOR:
        return

    if feature.get_grid_node() == get_grid_node() && feature.get_grid_anchor() == get_grid_anchor():
        if feature is GridEntity:
            _trigger(feature as GridEntity)

func _check_colliding_node(feature: GridNodeFeature) -> void:
    var is_on_node: bool = feature.get_grid_node() == get_grid_node()

    if encounter_mode != EncounterMode.NODE:
        _was_on_node = is_on_node
        return

    if is_on_node:
        if !_was_on_node && feature is GridEntity:
            _trigger(feature as GridEntity)

    _was_on_node = is_on_node

func can_trigger() -> bool:
    return effect != null && (repeatable || !_triggered)

func _trigger(entity: GridEntity) -> void:
    if !can_trigger():
        return

    if effect != null && effect.invoke(self, entity):
        _triggered = true

func save() -> Dictionary:
    var anchor_direction: CardinalDirections.CardinalDirection = get_grid_anchor_direction()

    var data: Dictionary = {
        _ID_KEY: encounter_id,
        _LOOK_DIRECTION_KEY: look_direction,
        _ANCHOR_KEY: anchor_direction,
        _COORDINATES_KEY: coordinates(),
        _DOWN_KEY: down,
        _TRIGGERED_KEY: _triggered,
    }

    var enemy_cards: Dictionary[String, Array] = _collect_enemy_gained_cards()
    if !enemy_cards.is_empty():
        data[_ENEMY_GAINED_CARDS_KEY] = enemy_cards

    return data

func _valid_save_data(save_data: Dictionary) -> bool:
    return (
        save_data.has(_ID_KEY) &&
        save_data.has(_LOOK_DIRECTION_KEY) &&
        save_data.has(_ANCHOR_KEY) &&
        save_data.has(_COORDINATES_KEY) &&
        save_data.has(_DOWN_KEY))

func load_from_save(level: GridLevel, save_data: Dictionary) -> void:
    if !_valid_save_data(save_data):
        _reset_starting_condition()
        return

    if save_data[_ID_KEY] != encounter_id:
        push_error("Attempting load of '%s' but I'm '%s" % [save_data[_ID_KEY], encounter_id])
        return

    var coords: Vector3i = DictionaryUtils.safe_getv3i(save_data, _COORDINATES_KEY)
    var node: GridNode = level.get_grid_node(coords)

    if node == null:
        push_error("Trying to load player onto coordinates %s but there's no node there." % coords)
        _reset_starting_condition()
        return

    var look: CardinalDirections.CardinalDirection = save_data[_LOOK_DIRECTION_KEY]
    var down_direction: CardinalDirections.CardinalDirection = save_data[_DOWN_KEY]
    var anchor_direction: CardinalDirections.CardinalDirection = save_data[_ANCHOR_KEY]

    look_direction = look
    down = down_direction
    _triggered = save_data[_TRIGGERED_KEY] if save_data.has(_TRIGGERED_KEY) else false

    if anchor_direction == CardinalDirections.CardinalDirection.NONE:
        set_grid_node(node)
    else:
        var anchor: GridAnchor = node.get_grid_anchor(anchor_direction)
        if anchor == null:
            push_error("Trying to load player onto coordinates %s and anchor %s but node lacks anchor in that direction" % [coords, anchor_direction])
        update_entity_anchorage(node, anchor, true)

    if effect != null:
        if effect.hide_encounter_on_trigger && _triggered:
            visible = false
    sync_position()
    orient()

    var enemy_cards: Dictionary = DictionaryUtils.safe_getd(save_data, _ENEMY_GAINED_CARDS_KEY, {}, false)
    _load_enemy_cards(enemy_cards)

    _connect_player_callbacks(level)

    print_debug("Loaded %s from %s" % [encounter_id, save_data])

func _reset_starting_condition() -> void:
    set_grid_node(_spawn_node)
    _triggered = false
    # TODO: Continue here!

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
