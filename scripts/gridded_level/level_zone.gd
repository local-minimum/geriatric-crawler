extends Node
class_name LevelZone

enum EntityFilter { ENTITIES, PLAYER, ENEMIES }

@export var filter: EntityFilter = EntityFilter.ENTITIES
@export var nodes: Array[GridNode]

var _in_zones: Array[GridEntity]

func _enter_tree() -> void:
    if __SignalBus.on_change_node.connect(_handle_change_node) != OK:
        push_error("Failed to connect move start")

func get_level() -> GridLevel:
    if nodes.is_empty():
        return GridLevel.find_level_parent(self, false)
    return nodes[0].get_level()

func _passes_filter(feature: GridNodeFeature) -> bool:
    match filter:
        EntityFilter.ENTITIES:
            return feature is GridEntity
        EntityFilter.PLAYER:
            return feature is GridPlayer
        EntityFilter.ENEMIES:
            if feature is GridEncounter:
                var encounter: GridEncounter = feature
                return encounter.effect is BattleModeTrigger

            return false
        _:
            push_error("Entity Filter %s not handled" % filter)
            return false

func covers(coordinates: Vector3i) -> bool:
    return nodes.any(func (node: GridNode) -> bool: return node.coordinates == coordinates)

func _handle_change_node(feature: GridNodeFeature) -> void:
    if !_passes_filter(feature):
        return

    var in_zone: bool = covers(feature.coordinates())
    if !_in_zones.has(feature):
        _in_zones.append(feature)
        __SignalBus.on_enter_zone.emit(self, feature)
    elif _in_zones.has(feature):
        if in_zone:
            __SignalBus.on_stay_zone.emit(self, feature)
        else:
            _in_zones.erase(feature)
            __SignalBus.on_exit_zone.emit(self, feature)
