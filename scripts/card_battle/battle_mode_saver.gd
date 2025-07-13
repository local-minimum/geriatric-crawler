extends SaveExtension
class_name BattleModeSaver

const _PARTY_KEY: String = "party"
const _SUIT_BONUS_KEY: String = "suit-bonus"
const _RANK_BONUS_KEY: String = "rank-bonus"
const _RANK_DIRECTION_KEY: String = "rank-direction"
const _PREV_CARD_KEY: String = "prev-card"

@export
var _battle: BattleMode

func get_key() -> String:
    if _battle == null:
        var node: Node = get_tree().get_first_node_in_group(BattleMode.LEVEL_GROUP)
        if node != null && node is BattleMode:
            _battle = node
        else:
            push_warning("Could not find a battle in '%s', won't be able to load battle saves" % BattleMode.LEVEL_GROUP)
    return "battle"

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(extentsion_save_data: Dictionary) -> Dictionary:
    if _battle == null:
        return extentsion_save_data

    var party: Array = _battle.get_party().map(func (member: BattlePlayer) -> Dictionary: return member.collect_save_data())

    return {
        _PARTY_KEY: party,
        _SUIT_BONUS_KEY: _battle.suit_bonus,
        _RANK_BONUS_KEY: _battle.rank_bonus,
        _RANK_DIRECTION_KEY: _battle.rank_direction,
        _PREV_CARD_KEY: _battle.previous_card.id if _battle.previous_card != null else "",
    }

func initial_data(extentsion_save_data: Dictionary) -> Dictionary:
    return extentsion_save_data

func load_from_data(extentsion_save_data: Dictionary) -> void:
    if _battle == null:
        if extentsion_save_data != null && !extentsion_save_data.is_empty():
            push_error("Could not load battle state from save")
        return

    var party: Array[BattlePlayer] = _battle.get_party()
    if extentsion_save_data.has(_PARTY_KEY):
        for save: Dictionary in extentsion_save_data[_PARTY_KEY]:
            var id: String = save.get(BattlePlayer._ID_KEY, "")
            var player_idx: int = party.find_custom(func (p: BattlePlayer) -> bool: return p.character_id == id)
            if player_idx < 0:
                continue

            party[player_idx].load_from_save(save)

    if extentsion_save_data.has(_SUIT_BONUS_KEY):
        var bonus: Variant = extentsion_save_data[_SUIT_BONUS_KEY]
        if bonus is int:
            _battle.suit_bonus = bonus
        else:
            _battle.suit_bonus = 0
            push_error("The suit bonus on %s in save %s was the wrong type (%s)" % [_SUIT_BONUS_KEY, extentsion_save_data, bonus])
    else:
        _battle.suit_bonus = 0
        push_error("There was no suit bonus on %s in save %s" % [_SUIT_BONUS_KEY, extentsion_save_data])

    if extentsion_save_data.has(_RANK_BONUS_KEY):
        var bonus: Variant = extentsion_save_data[_RANK_BONUS_KEY]
        if bonus is int:
            _battle.rank_bonus = bonus
        else:
            _battle.rank_bonus = 0
            push_error("The rank bonus on %s in save %s was the wrong type (%s)" % [_RANK_BONUS_KEY, extentsion_save_data, bonus])
    else:
        _battle.rank_bonus = 0
        push_error("There was no rank bonus on %s in save %s" % [_RANK_BONUS_KEY, extentsion_save_data])

    if extentsion_save_data.has(_RANK_DIRECTION_KEY):
        var direction: Variant = extentsion_save_data[_RANK_DIRECTION_KEY]
        if direction is int:
            _battle.rank_direction = direction
        else:
            _battle.rank_direction = 0
            push_error("The rank direction on %s in save %s was the wrong type (%s)" % [_RANK_DIRECTION_KEY, extentsion_save_data, direction])
    else:
        _battle.rank_direction = 0
        push_error("There was no rank direction on %s in save %s" % [_RANK_DIRECTION_KEY, extentsion_save_data])

    if extentsion_save_data.has(_PREV_CARD_KEY):
        var prev_card: Variant = extentsion_save_data[_PREV_CARD_KEY]
        if prev_card is String:
            @warning_ignore_start("unsafe_cast")
            # TODO: Can we really be sure that the player deck is loaded??
            _battle.previous_card = _battle.player_deck.get_card(prev_card as String)
            @warning_ignore_restore("unsafe_cast")
        else:
            _battle.previous_card = null
            push_error("There was no previous card on %s in save %s" % [_PREV_CARD_KEY, extentsion_save_data])
