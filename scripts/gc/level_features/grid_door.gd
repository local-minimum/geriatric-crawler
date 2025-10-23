extends GridDoorCore
class_name GridDoor


@export_range(1, 4) var _lock_bypass_required_level: int = 1
@export_range(1, 10) var _lock_difficulty: int = 2
@export var _hacking_danger: HackingGame.Danger

var _hacking_alphabet: PackedStringArray
var _hacking_passphrase: PackedStringArray

func attempt_door_unlock(puller: CameraPuller) -> bool:
    if !super.attempt_door_unlock(puller):
        var player: GridPlayer = get_level().player
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

    return true

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
                    var enemies: Array[BattleEnemy] = (get_level() as GridLevel).alive_enemies()
                    var punishments: PunishmentDeck = (get_level() as GridLevel).punishments
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

const _HACKING_ALPHABET_KEY: String = "hacking-alphabet"
const _HACKING_PASSPHRASE_KEY: String = "hacking-passkey"

func collect_save_data() -> Dictionary:
    var data: Dictionary = super.collect_save_data()
    return data.merged({
        _HACKING_ALPHABET_KEY: _hacking_alphabet,
        _HACKING_PASSPHRASE_KEY: _hacking_passphrase
    }, true)

func load_save_data(data: Dictionary) -> void:
    _hacking_alphabet = DictionaryUtils.safe_get_packed_string_array(data, _HACKING_ALPHABET_KEY, [], false)
    _hacking_passphrase = DictionaryUtils.safe_get_packed_string_array(data, _HACKING_PASSPHRASE_KEY, [], false)

    super.load_save_data(data)
