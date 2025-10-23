extends GridEvent
class_name GCCorpse

@export var avatar: Node

const CORPSE_COORDINATES_KEY: String = "corpse"
const CORPSE_INVENTORY_KEY: String = "inventory"
const CORPSE_MODEL_KEY: String = "model"
const CORPSE_NAME_KEY: String = "name"

var _loot: Dictionary[String, float]
var _inv: Inventory.InventorySubscriber
var _name: String
var _model: String

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if _triggered && !_repeatable:
        NotificationsManager.info(tr("NOTICE_DEBRIS"), tr("DUSTY_HUSK_NAME").format({"name": _name}))
        return

    super.trigger(entity, movement)

    if _loot.is_empty():
        NotificationsManager.info(tr("NOTICE_DEBRIS"), tr("DUSTY_HUSK_NAME").format({"name": _name}))
    else:
        NotificationsManager.important(tr("NOTICE_DEBRIS"), tr("SEARCH_DEBRIS_MODEL_NAME").format({"model": _model, "name": _name}))
        await get_tree().create_timer(1).timeout
        if _inv.inventory.add_many_to_inventory(_loot):
            _loot.clear()
        else:
            _triggered = false

func has_loot() -> bool:
    return !_triggered && !_loot.is_empty()

func load_from_save(level: GridLevel, save: Dictionary) -> void:
    var coords: Vector3i = DictionaryUtils.safe_getv3i(save, CORPSE_COORDINATES_KEY)
    var node: GridNode = level.get_grid_node(coords)

    print_debug("[GCCorpse] loading corpse from %s" % save)

    if node == null:
        push_error("Cannot load corpse due to %s not inside level" % coords)
        avatar.queue_free()
        return

    if node.get_grid_anchor(CardinalDirections.CardinalDirection.DOWN) == null:
        node = node.neighbour(CardinalDirections.CardinalDirection.DOWN)
        if node == null:
            push_error("Cannot load corpse due not finding ground from %s" % coords)
            avatar.queue_free()
            return

    node.add_grid_event(self)

    if get_parent() == null:
        node.add_child(self)
    else:
        reparent(node, false)

    global_position = node.global_position

    _loot.clear()
    _name = DictionaryUtils.safe_gets(save, CORPSE_NAME_KEY, tr("NO_ROBOT_NAME"), false)
    _model = DictionaryUtils.safe_gets(save, CORPSE_MODEL_KEY, RobotModel.UNKNOWN_MODEL, false)

    var loot: Dictionary = DictionaryUtils.safe_getd(save, CORPSE_INVENTORY_KEY, {}, false)
    for key: Variant in loot:
        if key is not String:
            push_warning("Ignoring corpse loot '%s' because not a string key" % key)
            continue
        var value: Variant = loot[key]
        if value is not int and value is not float:
            push_warning("Ignoring corpse loot '%s' because value '%s' not a float" % [key, value])
            continue

        @warning_ignore_start("unsafe_cast")
        _loot[key as String] = value as float
        @warning_ignore_restore("unsafe_cast")

    _triggered = false

    level.corpse = self

func collect_save_data() -> Dictionary:
    return {
        CORPSE_COORDINATES_KEY: coordinates(),
        CORPSE_INVENTORY_KEY: _loot,
        CORPSE_MODEL_KEY: _model,
        CORPSE_NAME_KEY: _name
    }
