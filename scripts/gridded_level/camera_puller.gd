extends Node3D
class_name CameraPuller

@export var look_target: Node3D

@export var tween_duration: float = 0.7

var _tween: Tween

func grab_player(player: GridPlayerCore, on_grabbed_complete: Variant = null, auto_release: bool = false, speed: float = 1.0) -> void:
    player.cinematic = true

    var cam: Camera3D = player.camera

    if _tween != null:
        _tween.kill()

    _tween = create_tween()

    var target_rotation: Quaternion = Basis.looking_at(look_target.global_position - global_position, global_basis.y).get_rotation_quaternion()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(cam, "global_position", global_position, tween_duration * speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    _tween.parallel().tween_method(
        func (rot: Quaternion) -> void:
            cam.global_rotation = rot.get_euler(),
        cam.global_basis.get_rotation_quaternion(),
        target_rotation,
        tween_duration * speed
    ).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    @warning_ignore_restore("return_value_discarded")

    if auto_release:
        if _tween.connect(
            "finished",
            func () -> void:
                if on_grabbed_complete != null && on_grabbed_complete is Callable:
                    @warning_ignore_start("unsafe_cast")
                    (on_grabbed_complete as Callable).call()
                    @warning_ignore_restore("unsafe_cast")
                release_player(player, null, speed)
        ) != OK:
            await get_tree().create_timer(speed * tween_duration).timeout
            release_player(player, null, speed)
    elif on_grabbed_complete != null && on_grabbed_complete is Callable:
        if _tween.connect(
            "finished",
            func () -> void:
                @warning_ignore_start("unsafe_cast")
                (on_grabbed_complete as Callable).call()
                @warning_ignore_restore("unsafe_cast")
        ) != OK:
            await get_tree().create_timer(speed * tween_duration).timeout
            @warning_ignore_start("unsafe_cast")
            (on_grabbed_complete as Callable).call()
            @warning_ignore_restore("unsafe_cast")


func release_player(player: GridPlayerCore, on_released_complete: Variant = null, speed: float = 1.0, release_from_cinematic: bool = true) -> void:
    var cam: Camera3D = player.camera

    if _tween != null:
        _tween.kill()

    _tween = create_tween()

    @warning_ignore_start("return_value_discarded")
    _tween.tween_property(cam, "position", player.camera_wanted_position, tween_duration * speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    _tween.parallel().tween_method(
        func (rot: Quaternion) -> void:
            cam.rotation = rot.get_euler(),
        cam.basis.get_rotation_quaternion(),
        player.camera_resting_rotation,
        tween_duration * speed
    ).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    @warning_ignore_restore("return_value_discarded")

    if _tween.connect(
        "finished",
        func () -> void:
            if release_from_cinematic:
                player.cinematic = false

            if on_released_complete != null && on_released_complete is Callable:
                @warning_ignore_start("unsafe_cast")
                (on_released_complete as Callable).call()
                @warning_ignore_restore("unsafe_cast")
    ) != OK:
        await get_tree().create_timer(speed * tween_duration).timeout

        if release_from_cinematic:
            player.cinematic = false

        if on_released_complete != null && on_released_complete is Callable:
            @warning_ignore_start("unsafe_cast")
            (on_released_complete as Callable).call()
            @warning_ignore_restore("unsafe_cast")
