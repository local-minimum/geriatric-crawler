extends Node
class_name ZoneEffectManager

enum Attachment { NODE, SIDE }

@export var zone: LevelZone
@export var attachment: Attachment
@export var effect_path: String

func _ready() -> void:
    print_debug("[Zone Effect Manager] ready to %s" % attachment)
    match attachment:
        Attachment.NODE:
            _attach_to_node()

        Attachment.SIDE:
            _attach_to_side()

func _attach_to_node() -> void:
    print_debug("[Zone Effect Manager] Adding to zone nodes %s" % [zone.nodes.size()])
    var scene: PackedScene = load(effect_path)
    for node: GridNode in zone.nodes:
        var effect: Node3D = scene.instantiate()

        node.add_child(effect)

        effect.position = Vector3.ZERO
        print_debug("[Zone Effect Manager] Adding %s to %s" % [effect, node])

func _attach_to_side() -> void:
    print_debug("[Zone Effect Manager] Adding to zone node sides %s" % [zone.nodes.size()])
    var scene: PackedScene = load(effect_path)
    for node: GridNode in zone.nodes:
        var level: GridLevel = node.get_level()
        for direction: CardinalDirections.CardinalDirection in CardinalDirections.ALL_DIRECTIONS:
            var side: Node3D
            match node.has_side(direction):
                GridNode.NodeSideState.NONE:
                    print_debug("[Zone Effect Manager] Nothing of %s %s" % [node.name, CardinalDirections.name(direction)])
                    continue
                GridNode.NodeSideState.DOOR:
                    var door: GridDoor = node.get_door(direction)
                    if door.lock_state == GridDoor.LockState.OPEN:
                        print_debug("[Zone Effect Manager] Open door of %s %s" % [node.name, CardinalDirections.name(direction)])
                        continue
                    side = door
                _:
                    side = node.get_grid_anchor(direction)
                    if side == null:
                        print_debug("[Zone Effect Manager] No side/anchor of %s %s" % [node.name, CardinalDirections.name(direction)])
                        continue

            var effect: Node3D = scene.instantiate()

            side.add_child(effect)

            print_debug("[Zone Effect Manager] Adding %s to %s of %s" % [effect, side, node.name])

            effect.position = Vector3.ZERO

            # Assuming north is identiy rotation
            # Assuming center is node 0,0,0 (meaning floor center)
            side.global_rotation = CardinalDirections.direction_to_any_rotation(direction).get_euler()

            if direction == CardinalDirections.CardinalDirection.UP:
                side.global_position += Vector3.UP * level.node_size.y
            elif CardinalDirections.is_planar_cardinal(direction):
                side.global_position += (
                    Vector3.UP * level.node_size.y * 0.5 +
                    CardinalDirections.direction_to_vector(direction) * level.node_size * 0.5
                )
