extends GridEvent
class_name GridTeleporter

signal on_arrive_entity(teleporter: GridTeleporter, entity: GridEntity)

@export var exit: GridTeleporter

@export var teleports_player: bool = true

@export var teleports_non_players: bool

@export var look_direction: CardinalDirections.CardinalDirection

@export var anchor_direction: CardinalDirections.CardinalDirection

@export var inactive_scale: float = 0.3

@export var effect: Node3D

@export var rotation_speed: float = 1

func _ready() -> void:
    if __SignalBus.on_move_end.connect(_handle_teleport) != OK:
        push_error("Failed to connect on move end")

    if effect != null:
        if exit == null:
            effect.visible = false
        else:
            effect.scale = Vector3.ONE * inactive_scale

func needs_saving() -> bool:
    return _triggered && !_repeatable

func save_key() -> String:
    return "tp-%s" % coordinates()

const _TRIGGERED_KEY: String = "triggered"
func collect_save_data() -> Dictionary:
    return {
        _TRIGGERED_KEY: _triggered
    }

func load_save_data(data: Dictionary) -> void:
    var triggered: bool = DictionaryUtils.safe_getb(data, _TRIGGERED_KEY, false, false)
    _triggered = triggered

func should_trigger(
    _entity: GridEntity,
    _from: GridNode,
    _from_side: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
) -> bool:
    if exit == null:
        return false

    if _entity is GridPlayer:
        return teleports_player
    return teleports_non_players

## If event blocks entry translation
func blocks_entry_translation(
    _entity: GridEntity,
    _from: GridNode,
    _move_direction: CardinalDirections.CardinalDirection,
    _to_side: CardinalDirections.CardinalDirection,
    _silent: bool = false,
) -> bool:
    return false

## If event blocks entry translation
func blocks_exit_translation(
    _exit_direction: CardinalDirections.CardinalDirection,
) -> bool:
    return false

var _teleporting: Array[GridEntity] = []

func trigger(entity: GridEntity, movement: Movement.MovementType) -> void:
    if _teleporting.has(entity):
        return

    print_debug("%s grabbed %s for teleporting" % [coordinates(), entity])
    _teleporting.append(entity)

    super.trigger(entity, movement)

    _show_effect(entity)

    entity.cinematic = true
    # TODO: Play some nice effect

func _show_effect(entity: GridEntity) -> void:
    if effect == null || exit == null:
        return

    var rot: Quaternion = CardinalDirections.direction_to_rotation(
        CardinalDirections.invert(entity.down),
        CardinalDirections.invert(entity.look_direction),
    )

    effect.global_rotation = rot.get_euler()
    effect.scale = Vector3.ONE * inactive_scale
    effect.visible = true

    var tween: Tween = create_tween()

    @warning_ignore_start("return_value_discarded")
    tween.tween_property(effect, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_CUBIC)
    @warning_ignore_restore("return_value_discarded")

    if tween.connect(
        "finished",
        func () -> void:
            effect.scale = Vector3.ONE * inactive_scale
    ) != OK:
        push_warning("Could not disable teleportation effect after done")


func _handle_teleport(entity: GridEntity) -> void:
    if !_teleporting.has(entity):
        return

    await get_tree().create_timer(0.1).timeout

    FaderUI.fade(
        FaderUI.FadeTarget.EXPLORATION_VIEW,
        func() -> void:
            var exit_node: GridNode = exit.get_grid_node()
            if exit_node == null:
                entity.cinematic = false
                push_error("Failed to teleport because there was no exit")
                return

            var exit_anchor: GridAnchor = exit_node.get_grid_anchor(exit.anchor_direction)
            if exit_anchor != null:
                entity.down = exit.anchor_direction
                entity.set_grid_anchor(exit_anchor)
            else:
                entity.set_grid_node(exit_node)

            if exit.look_direction != CardinalDirections.CardinalDirection.NONE:
                entity.look_direction = exit.look_direction
                entity.orient()

            entity.sync_position()
            entity.clear_queue()
            ,
        func () -> void:
            entity.cinematic = false
            _teleporting.erase(entity)
            on_arrive_entity.emit(exit, entity)
            ,
        Color.ALICE_BLUE,
    )

    print_debug("Handle teleport of %s from %s to %s" % [entity, coordinates(), "%s" % exit.coordinates() if exit != null else "Nowhere"])

func _process(delta: float) -> void:
    if effect == null || !effect.visible || !_teleporting.is_empty():
        return

    effect.global_rotation += CardinalDirections.direction_to_vector(anchor_direction) * delta * rotation_speed
