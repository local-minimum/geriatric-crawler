extends SaveExtension
class_name ChapSaver

@export var _save_key: String = "globals"
@export var chap_ui: ChapUI

func _enter_tree() -> void:
    if chap_ui == null:
        for chap_candidate: Node in get_tree().root.find_children("", "ChapUI"):
            if chap_candidate is ChapUI:
                chap_ui = chap_candidate
                break

func get_key() -> String:
    return _save_key

func load_from_initial_if_save_missing() -> bool:
    return false

func retrieve_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return chap_ui.collect_save_state()

func initial_data(_extentsion_save_data: Dictionary) -> Dictionary:
    return {}

func load_from_data(extentsion_save_data: Dictionary) -> void:
    chap_ui.load_save_state(extentsion_save_data)
