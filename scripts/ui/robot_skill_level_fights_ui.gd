extends Control
class_name RobotSkillLevelFightsUI

@export var _fight_rects: Array[TextureRect]

@export var _completed_tex: Texture

@export var _remaining_tex: Texture

@export var _na_tex: Texture

func sync(completed: int, total: int) -> void:
    for idx: int in range(_fight_rects.size()):
        if idx < completed:
            _fight_rects[idx].texture = _completed_tex
        elif  idx < total:
            _fight_rects[idx].texture = _remaining_tex
        else:
            _fight_rects[idx].texture = _na_tex

    if _fight_rects.size() < total:
        push_error("Cannot show all %s fights because only have %s rects" % [total, _fight_rects.size()])
