extends GridEvent
class_name PressurePlate

@export var _anim: AnimationPlayer
@export var _anim_activate: String = "Activate"
@export var _anim_active: String = "Active"
@export var _anim_deactivate: String = "Deactivate"
@export var _anim_deactivated: String = "Deactivated"

@export var _broadcast_id: String
@export var _broadcast_activate_message: String = "activate"
@export var _broadcast_deactivate_message: String = "deactivate"

var _triggering: Array[GridNodeFeature]

func _ready() -> void:
    if __SignalBus.on_change_node.connect(_handle_feature_move) != OK:
        push_warning("Failed to connect change node")

    if __SignalBus.on_change_anchor.connect(_handle_feature_move) != OK:
        push_warning("Failed to connect change anchor")

func _handle_feature_move(feature: GridNodeFeature) -> void:
    if _triggered && !_repeatable:
        return

    if !_triggering.has(feature) && coordinates() == feature.coordinates() &&  _trigger_sides.has(feature.get_grid_anchor_direction()):
        _triggered = true
        _triggering.append(feature)
        if _triggering.size() == 1:
            _anim.play(_anim_activate)
            if !_broadcast_id.is_empty():
                __SignalBus.on_broadcast_message.emit(_broadcast_id, _broadcast_activate_message)

    elif _triggering.has(feature) && (coordinates() != feature.coordinates() || !_trigger_sides.has(feature.get_grid_anchor_direction())):
        _triggering.erase(feature)
        if _triggering.is_empty():
            _anim.play(_anim_deactivate)
            if !_broadcast_id.is_empty():
                __SignalBus.on_broadcast_message.emit(_broadcast_id, _broadcast_deactivate_message)


func trigger(_entity: GridEntity, _movement: Movement.MovementType) -> void:
    # We don't trigger this way
    pass

const _TRIGGERED_KEY: String = "triggered"

func needs_saving() -> bool:
    return _trigger_sides.size() > 0

func save_key() -> String:
    return "pp-%s-%s" % [coordinates(), CardinalDirections.name(_trigger_sides[0])]

func collect_save_data() -> Dictionary:
    return {
        _TRIGGERED_KEY: _triggered,
    }

func load_save_data(_data: Dictionary) -> void:
    _triggered = DictionaryUtils.safe_getb(_data, _TRIGGERED_KEY)

    _triggering.clear()

    var level: GridLevel = get_level()
    var coords: Vector3i = coordinates()

    for entity: GridEntity in level.grid_entities:
        if entity.coordinates() == coords && _trigger_sides.has(entity.get_grid_anchor_direction()):
            _triggering.append(entity)

    if _triggering.is_empty():
        _anim.play(_anim_deactivated)
    else:
        _anim.play(_anim_active)
