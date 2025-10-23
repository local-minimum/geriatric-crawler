extends Node3D
class_name LevelZone

enum EntityFilter { ENTITIES, PLAYER, ENEMIES }

@export var filter: EntityFilter = EntityFilter.ENTITIES
@export var nodes: Array[GridNode]
@export var limits_mapping: bool

var _in_zones: Array[GridEntity]

func _enter_tree() -> void:
    if __SignalBus.on_change_node.connect(_handle_change_node) != OK:
        push_error("Failed to connect move start")

func get_level() -> GridLevelCore:
    if nodes.is_empty():
        return GridLevelCore.find_level_parent(self, false)
    return nodes[0].get_level()

func _passes_filter(feature: GridNodeFeature) -> bool:
    match filter:
        EntityFilter.ENTITIES:
            return feature is GridEntity
        EntityFilter.PLAYER:
            return feature is GridPlayerCore
        EntityFilter.ENEMIES:
            if feature is GridEncounterCore:
                var encounter: GridEncounterCore = feature
                return encounter.encounter_type == GridEncounterCore.EncounterType.ENEMY

            return false
        _:
            push_error("Entity Filter %s not handled" % filter)
            return false

func covers(coordinates: Vector3i) -> bool:
    return nodes.any(func (node: GridNode) -> bool: return node.coordinates == coordinates)

func _handle_change_node(feature: GridNodeFeature) -> void:
    if feature is not GridEntity || !_passes_filter(feature):
        return

    var entity: GridEntity = feature

    var in_zone: bool = covers(entity.coordinates())
    if !_in_zones.has(entity) && in_zone:
        _in_zones.append(entity)
        __SignalBus.on_enter_zone.emit(self, entity)
    elif _in_zones.has(entity):
        if in_zone:
            __SignalBus.on_stay_zone.emit(self, entity)
        else:
            _in_zones.erase(entity)
            __SignalBus.on_exit_zone.emit(self, entity)
