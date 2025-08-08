extends Control
class_name MapControlsUI


@export
var mode_2d_button: Button

@export
var mode_3d_button: Button

@export
var zoom_in_button: Button

@export
var zoom_out_button: Button

var _mapper: RobotExplorationMapper

func sync(exploration_mapper: RobotExplorationMapper, skill_level: int, prefer_2d: bool) -> void:
    _mapper = exploration_mapper

    match skill_level:
        3, 4:
            mode_2d_button.visible = !prefer_2d
            mode_3d_button.visible = prefer_2d
            zoom_in_button.visible = !prefer_2d
            zoom_out_button.visible = !prefer_2d
        _:
            visible = false

func _on_2d_map_button_pressed() -> void:
    _mapper.prefer_2d = true

func _on_3d_map_button_pressed() -> void:
    _mapper.prefer_2d = false

func _on_zoom_out_button_pressed() -> void:
    _mapper.zoom_out()

func _on_zoom_in_button_pressed() -> void:
    _mapper.zoom_in()
