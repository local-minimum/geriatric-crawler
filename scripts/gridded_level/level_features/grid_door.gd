extends GridEvent
class_name GridDoor

signal on_door_state_chaged()

@export var animator: AnimationPlayer

enum OpenAutomation { NONE, WALK_INTO, PROXIMITY, INTERACT }
enum CloseAutomation { NONE, END_WALK, PROXIMITY }
enum LockState { LOCKED, CLOSED, OPEN }

static func lock_state_name(state: LockState) -> String:
    match state:
        LockState.LOCKED: return __GlobalGameState.tr("DOOR_LOCKED")
        LockState.CLOSED: return __GlobalGameState.tr("DOOR_CLOSED")
        LockState.OPEN: return __GlobalGameState.tr("DOOR_OPEN")
        _:
            return __GlobalGameState.tr("DOOR_UNKNOWN")

@export var _automation: OpenAutomation

@export var _back_automation: OpenAutomation

@export var _close_automation: CloseAutomation

@export var _inital_lock_state: LockState = LockState.CLOSED

@export var _door_face: CardinalDirections.CardinalDirection

func get_side() -> CardinalDirections.CardinalDirection:
    return _door_face

@export var door_down: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.DOWN

@export var _open_animation: String = "Open"

@export var _close_animation: String = "Close"

@export var _opened_animation: String = "Opened"

@export var _closed_animation: String = "Closed"

@export
var block_traversal_anchor_sides: Array[CardinalDirections.CardinalDirection]

## If door is locked, this identifies what key unlocks it, omit the universal key-prefix
@export var key_id: String

@export var _consumes_key: bool

@export_range(1, 4) var _lock_bypass_required_level: int = 1

@export_range(1, 10) var _lock_difficulty: int = 2

@export var _hacking_danger: HackingGame.Danger

var lock_state: LockState
var _hacking_alphabet: PackedStringArray
var _hacking_passphrase: PackedStringArray

func _ready() -> void:
    lock_state = _inital_lock_state
    if lock_state == LockState.OPEN:
        animator.play(_opened_animation)
    else:
        animator.play(_closed_animation)

    if _back_automation != OpenAutomation.NONE:
        _add_back_sentinel.call_deferred()

    get_grid_node().add_grid_event(self)

func _add_back_sentinel() -> void:
    var neighbour_coords: Vector3i = CardinalDirections.translate(coordinates(), _door_face)
    var neighbour: GridNode = get_level().get_grid_node(neighbour_coords)
    if neighbour == null:
        push_error("Door %s @ at %s direction %s is supposed to have a backside but there's no node at %s" % [
            self,
            coordinates(),
            CardinalDirections.name(_door_face),
            neighbour_coords,
        ])
        return

    if neighbour.coordinates == coordinates():
        push_error("Door %s @ %s direction %s gets its own node as sentinel position" % [
            self,
            coordinates(),
            CardinalDirections.name(_door_face),
        ])
        return

    for sentinel: GridDoorSentinel in neighbour.find_children("", "GridDoorSentinel"):
        if sentinel.door == self:
            push_error("Door %s @ %s direction %s already has a sentinel on %s (%s)" % [
                self,
                coordinates(),
                CardinalDirections.name(_door_face),
                neighbour,
                sentinel,
            ])
            return

    var sentinel: GridDoorSentinel = GridDoorSentinel.new()

    sentinel.door = self
    sentinel.door_face = CardinalDirections.invert(_door_face)

    sentinel.automation = _back_automation
    sentinel.close_automation = _close_automation

    sentinel._repeatable = true
    sentinel._trigger_entire_node = true

    neighbour.add_child(sentinel)
    neighbour.add_grid_event(sentinel)

func get_opening_automation(reader: GridDoorReader) -> OpenAutomation:
    if reader.is_negative_side:
        print_debug("door %s's reader %s is negative side %s" % [self, reader, _back_automation])
        return _back_automation

    print_debug("door %s's reader %s is positive side %s" % [self, reader, _automation])
    return _automation

func should_trigger(
    _entity: GridEntity,
    _from: GridNode,
    _from_side: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    return true

func blocks_entry_translation(
    entity: GridEntity,
    _from: GridNode,
    move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
    _silent: bool = false,
) -> bool:
    return CardinalDirections.invert(move_direction) == _door_face && (
        lock_state != LockState.OPEN || block_traversal_anchor_sides.has(entity.get_grid_anchor_direction())
    )

func blocks_exit_translation(
    exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return exit_direction == _door_face && lock_state != LockState.OPEN

func anchorage_blocked(side: CardinalDirections.CardinalDirection) -> bool:
    return side == _door_face && lock_state == LockState.OPEN || super.anchorage_blocked(side)

func manages_triggering_translation() -> bool:
    return false

var proximate_entitites: Array[GridEntity]

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    #print_debug("%s door is state %s automation %s" % [self, lock_state_name(lock_state), _automation])

    if !_repeatable && _triggered:
        return

    super.trigger(entity, movement)

    if _close_automation == CloseAutomation.PROXIMITY:
        _monitor_entity_for_proximity_closing(entity)
    elif _close_automation == CloseAutomation.END_WALK:
        _monitor_entity_for_walkthrough_closing(entity)

    if lock_state == LockState.CLOSED:
        if _automation == OpenAutomation.PROXIMITY:
            print_debug("Door opens %s" % self)
            open_door()
            return

    if _automation == OpenAutomation.WALK_INTO:
        if !entity.on_move_start.is_connected(_check_walk_onto_closed_door):
            if entity.on_move_start.connect(_check_walk_onto_closed_door) != OK:
                push_error("Failed to connect %s on move start to check door opening" % entity)
        return

func _check_walk_onto_closed_door(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    print_debug("DOOR: %s %s vs %s and %s vs %s" % [
        self,
        from,
        coordinates(),
        CardinalDirections.name(translation_direction),
        CardinalDirections.name(_door_face),
    ])

    if from != coordinates() && entity.coordinates() != coordinates():
        entity.on_move_start.disconnect(_check_walk_onto_closed_door)
        return

    if from == coordinates() && translation_direction == _door_face:
        print_debug("Door opens %s" % self)
        open_door()
        entity.on_move_start.disconnect(_check_walk_onto_closed_door)

func _monitor_entity_for_walkthrough_closing(
    entity: GridEntity,
) -> void:
    if entity.on_move_start.is_connected(_check_traversing_door_should_autoclose):
        return

    if entity.on_move_start.connect(_check_traversing_door_should_autoclose) != OK:
        push_error("Door %s failed to connect %s on move start for walk through auto-closing" % [self, entity])

func _check_traversing_door_should_autoclose(
    entity: GridEntity,
    from: Vector3i,
    translation_direction: CardinalDirections.CardinalDirection,
) -> void:
    if entity.coordinates() != coordinates():
        entity.on_move_start.disconnect(_check_traversing_door_should_autoclose)

    if from == coordinates() && translation_direction == _door_face && lock_state == LockState.OPEN:
        if entity.on_move_end.connect(_do_autoclose) != OK:
            push_error("Door %s failed to conntect %s on move end when walking through door to autoclose it" % [self, entity])

func _do_autoclose(entity: GridEntity) -> void:
    entity.on_move_end.disconnect(_do_autoclose)

    if lock_state == LockState.OPEN:
        close_door()

func _monitor_entity_for_proximity_closing(entity: GridEntity) -> void:
    if !proximate_entitites.has(entity):
        proximate_entitites.append(entity)

    if !entity.on_move_end.is_connected(_check_autoclose):
        print_debug("%s monitors %s" % [self, entity])
        if entity.on_move_end.connect(_check_autoclose) != OK:
            push_error("Door %s failed to connect %s on move end for auto-closing" % [self, entity])

func _check_autoclose(entity: GridEntity) -> void:
    var e_coords: Vector3i = entity.coordinates()
    var coords: Vector3i = coordinates()

    if e_coords == coords || e_coords == CardinalDirections.translate(coords, _door_face):
        return

    proximate_entitites.erase(entity)
    entity.on_move_end.disconnect(_check_autoclose)

    if proximate_entitites.is_empty() && lock_state == LockState.OPEN:
        print_debug("%s close door" % self)
        close_door()
        return

    print_debug("%s don't close door %s" % [self, proximate_entitites])

func close_door() -> void:
    print_debug("Close %s" % self)
    lock_state = LockState.CLOSED
    animator.play(_close_animation, 0.5)
    await get_tree().create_timer(0.5).timeout
    on_door_state_chaged.emit()

func open_door() -> void:
    print_debug("Open %s" % self)
    lock_state = LockState.OPEN
    animator.play(_open_animation, 0.5)
    await get_tree().create_timer(0.5).timeout
    on_door_state_chaged.emit()

func toggle_door() -> void:
    if lock_state == LockState.LOCKED:
        return

    if lock_state == LockState.CLOSED:
        open_door()
    else:
        close_door()

func attempt_door_unlock(puller: CameraPuller) -> void:
    if lock_state != LockState.LOCKED:
        return

    var player: GridPlayer = get_level().player

    var key_ring: KeyRing = player.key_ring
    if key_ring == null || !key_ring.has_key(key_id):
        NotificationsManager.warn(tr("NOTICE_DOOR_LOCKED"), tr("MISSING_ITEM").format({"item": KeyMaster.instance.get_description(key_id)}))

        if puller != null:
            var skill_level: int = player.robot.get_skill_level(RobotAbility.SKILL_BYPASS)
            if skill_level >= _lock_bypass_required_level:
                puller.grab_player(
                    player,
                    func () -> void:
                        _trigger_hacking_prompt.call(puller)
                        ,
                )
            elif skill_level > 0:
                puller.grab_player(
                    player,
                    func () -> void:
                        await get_tree().create_timer(0.2).timeout
                        NotificationsManager.important(tr("NOTICE_DOOR_BYPASS"), tr("INSUFFICIENT_LEVEL"))
                        await get_tree().create_timer(0.8).timeout
                        puller.release_player(player)
                        ,
                )

        return

    if _consumes_key:
        if key_ring.consume_key(key_id):
            NotificationsManager.important(tr("NOTICE_DOOR_UNLOCKED"), tr("LOST_ITEM").format({"item": KeyMaster.instance.get_description(key_id)}))
        else:
            NotificationsManager.warn(tr("NOTICE_DOOR_LOCKED"), tr("UNLOCK_FAILED").format({"item": KeyMaster.instance.get_description(key_id)}))
            return
    else:
        NotificationsManager.info(tr("NOTICE_DOOR_UNLOCKED"), tr("USED_ITEM").format({"item": KeyMaster.instance.get_description(key_id)}))

    lock_state = LockState.CLOSED
    on_door_state_chaged.emit()
    open_door()

func _trigger_hacking_prompt(puller: CameraPuller) -> void:
    var player: GridPlayer = get_level().player

    var attempts: int = HackingGame.calculate_attempts(player.robot, _lock_difficulty)

    StartHackingDialog.show_dialog(
        tr("NOTICE_DOOR_LOCKED"),
        _lock_difficulty,
        attempts,
        _hacking_danger,
        func (danger: HackingGame.Danger) -> void:
            _hacking_danger = danger
            ,
        func () -> void:
            NotificationsManager.info(tr("NOTICE_HACKING"), tr("NOT_WORTH"))
            puller.release_player(player)
            ,
        func () -> void:
            _generate_hacking_parameters_if_needed(_lock_difficulty)

            HackingGame.start(
                player.robot,
                _lock_difficulty,
                attempts,
                _hacking_alphabet,
                _hacking_passphrase,
                func () -> void:
                    open_door()
                    puller.release_player(player),
                func () -> void:
                    var robot: Robot = player.robot
                    var enemies: Array[BattleEnemy] = get_level().alive_enemies()
                    var punishments: PunishmentDeck = get_level().punishments
                    for _idx: int in range(HackingGame.danger_to_drawn_cards_count(_hacking_danger)):
                        var card: BattleCardData = punishments.get_random_card()
                        if card == null:
                            break

                        match card.card_owner:
                            BattleCardData.Owner.SELF:
                                robot.gain_card(card)
                                NotificationsManager.important(tr("NOTICE_PUNISHMENT"), tr("GAINED_CARD").format({"card": card.localized_name()}))
                            BattleCardData.Owner.ENEMY:
                                if enemies.is_empty():
                                    push_warning("No enemy is alive, returning card %s" % card.localized_name())
                                    punishments.return_card(card)
                                else:
                                    var enemy: BattleEnemy = enemies[randi_range(0, enemies.size() - 1)]
                                    enemy.deck.gain_card(card)
                                    NotificationsManager.important(tr("NOTICE_PUNISHMENT"), tr("ENEMY_GAINED_CARD").format({"card": card.localized_name()}))

                            BattleCardData.Owner.ALLY:
                                push_warning("We don't know how to give a punishment to an ally yet, returning card %s" % card.name)
                                punishments.return_card(card)
                    puller.release_player(player)
                    ,
            )
    )

func _generate_hacking_parameters_if_needed(difficulty: int) -> void:
    if _hacking_alphabet.size() == 0 || _hacking_passphrase.size() == 0:
        _hacking_alphabet = HackingGame.generate_alphabet(difficulty)
        _hacking_passphrase = HackingGame.generate_passphrase(difficulty, _hacking_alphabet)

func needs_saving() -> bool:
    return true

func save_key() -> String:
    return "d-%s-%s" % [coordinates(), CardinalDirections.name(_door_face)]

const _LOCK_STATE_KEY: String = "lock"
const _TRIGGERED_KEY: String = "triggered"
const _HACKING_ALPHABET_KEY: String = "hacking-alphabet"
const _HACKING_PASSPHRASE_KEY: String = "hacking-passkey"

func collect_save_data() -> Dictionary:
    return {
        _LOCK_STATE_KEY: lock_state,
        _TRIGGERED_KEY: _triggered,
        _HACKING_ALPHABET_KEY: _hacking_alphabet,
        _HACKING_PASSPHRASE_KEY: _hacking_passphrase
    }

func _deserialize_lockstate(state: int) -> LockState:
    match state:
        0: return LockState.LOCKED
        1: return LockState.CLOSED
        2: return LockState.OPEN
        _:
            push_error("State %s is not a serialized lockstate, using initial lock state" % state)
            return _inital_lock_state

func load_save_data(data: Dictionary) -> void:
    print_debug("Door %s loads from %s" % [self, data])
    _triggered = DictionaryUtils.safe_getb(data, _TRIGGERED_KEY, false, false)
    _hacking_alphabet = DictionaryUtils.safe_get_packed_string_array(data, _HACKING_ALPHABET_KEY, [], false)
    _hacking_passphrase = DictionaryUtils.safe_get_packed_string_array(data, _HACKING_PASSPHRASE_KEY, [], false)

    var lock_state_int: int = DictionaryUtils.safe_geti(data, _LOCK_STATE_KEY, _inital_lock_state, false)
    lock_state = _deserialize_lockstate(lock_state_int)

    print_debug("Door %s loads with state %s" % [self, lock_state_name(lock_state)])
    if lock_state == LockState.OPEN:
        animator.play(_opened_animation)
    else:
        animator.play(_closed_animation)

    if _close_automation == CloseAutomation.PROXIMITY:
        var coords: Vector3i = coordinates()
        for entity: GridEntity in get_level().grid_entities:
            if entity != null && coords == entity.coordinates():
                _monitor_entity_for_proximity_closing(entity)
