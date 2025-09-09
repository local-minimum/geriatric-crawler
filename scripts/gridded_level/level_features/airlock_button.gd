extends Node
class_name AirlockButton

@export var portal: LevelPortal

func _in_range() -> bool:
    var level: GridLevel = portal.get_level()
    return !level.player.cinematic && level.player.coordinates() == portal.coordinates()

func _on_static_body_3d_input_event(
    _camera:Node,
    event:InputEvent,
    _event_position:Vector3,
    _normal:Vector3,
    _shape_idx:int,
) -> void:
    if !_in_range():
        return

    if event is InputEventMouseButton && !event.is_echo():
        var mouse_event: InputEventMouseButton = event

        if mouse_event.pressed && mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if !portal.allow_exit:
                NotificationsManager.info(tr("NOTICE_AIRLOCK"), tr("AIRLOCK_NOT_OPERATIONAL"))
                return

            portal.exit_level()
