class_name RobotData

var id: String
var model: RobotModel
var given_name: String
var storage_location: Spaceship.Room
var excursions: int
var accumualated_damage: int
var fights: int
var alive: bool = true
var obtained_upgrades: Array[RobotAbility]
var obtained_cards: Array[BattleCardData]

const MODEL_ID_KEY: String = "model"
const GIVEN_NAME_KEY: String = "given_name"
const STORAGE_LOCATION_KEY: String = "location"
const EXCURSIONS_KEY: String = "excursions"
const FIGHTS_KEY: String = "fights"
const ACCUMULATED_DAMAGE_KEY: String = "accumulated_damage"
const ID_KEY: String = "id"
const ABILITIES_KEY: String = "abilites"
const OBTAINED_CARDS_KEY: String = "bonus-cards"
const ALIVE_KEY: String = "alive"

@warning_ignore_start("shadowed_variable")
func _init(
    model: RobotModel,
    given_name: String,
    id: String = "",
) -> void:
    @warning_ignore_restore("shadowed_variable")
    self.model = model
    self.given_name = given_name
    self.id = RobotsPool._get_next_robot_id() if id.is_empty() else id

func to_save() -> Dictionary:
    return {
        ID_KEY: id,
        MODEL_ID_KEY: model.id,
        GIVEN_NAME_KEY: given_name,
        STORAGE_LOCATION_KEY: storage_location,
        ALIVE_KEY: alive,
        FIGHTS_KEY: fights,
        EXCURSIONS_KEY: excursions,
        ACCUMULATED_DAMAGE_KEY: accumualated_damage,
        ABILITIES_KEY: obtained_upgrades.map(func (ability: RobotAbility) -> String: return ability.full_id()),
        OBTAINED_CARDS_KEY: obtained_cards.map(func (card: BattleCardData) -> String: return card.id),
    }

func get_id_counter() -> int:
    return int(id.split("-")[0])


static func from_save(data: Dictionary) -> RobotData:
    var _given_name: String = DictionaryUtils.safe_gets(data, GIVEN_NAME_KEY)
    var _model_id: String = DictionaryUtils.safe_gets(data, MODEL_ID_KEY)

    var _id: String = DictionaryUtils.safe_gets(data, ID_KEY, RobotsPool._get_next_robot_id())

    var _model: RobotModel = RobotModel.get_model(_model_id)
    if _model == null:
        return null

    var _excursions: int = DictionaryUtils.safe_geti(data, EXCURSIONS_KEY)
    var _accumulated_damage: int = DictionaryUtils.safe_geti(data, ACCUMULATED_DAMAGE_KEY)
    var _storage_location: Spaceship.Room = Spaceship.to_room(DictionaryUtils.safe_geti(data, STORAGE_LOCATION_KEY), Spaceship.Room.PRINTERS)
    var _fights: int = DictionaryUtils.safe_geti(data, FIGHTS_KEY, 0, false)
    var _alive: bool = DictionaryUtils.safe_getb(data, ALIVE_KEY, true)

    var robot: RobotData = RobotData.new(_model, _given_name, _id)

    robot.storage_location = _storage_location
    robot.excursions = _excursions
    robot.accumualated_damage = _accumulated_damage
    robot.fights = _fights
    robot.alive = _alive

    for ability_id: Variant in DictionaryUtils.safe_geta(data, ABILITIES_KEY):
        if ability_id is String:
            @warning_ignore_start("unsafe_call_argument")
            var ability: RobotAbility = _model.find_skill(ability_id)
            @warning_ignore_restore("unsafe_call_argument")
            if ability != null:
                robot.obtained_upgrades.append(ability)
            else:
                push_warning("%s is not a known ability of %s" % [ability_id, _model])
        else:
            push_warning("%s is not a string value (expected on %s in %s)" % [ability_id, ABILITIES_KEY, data])

    for card_id_raw: Variant in DictionaryUtils.safe_geta(data, OBTAINED_CARDS_KEY):
        if card_id_raw is String:
            var card_id: String = card_id_raw
            var card: BattleCardData = BattleCardData.get_card_by_id(BattleCardData.CardCategory.Player, card_id)
            if card == null:
                card = BattleCardData.get_card_by_id(BattleCardData.CardCategory.Punishment, card_id)
                if card == null:
                    push_warning("%s couldn't be found among player or punishment cards" % card_id)
                elif card.card_owner != BattleCardData.Owner.SELF:
                    push_warning("%s is not a player card but %s" % [card_id, BattleCardData.name_owner(card.card_owner)])
                else:
                    robot.obtained_cards.append(card)

            else:
                robot.obtained_cards.append(card)
        else:
            push_warning("%s is not a string value (expected on %s in %s)" % [card_id_raw, OBTAINED_CARDS_KEY, data])

    return robot
