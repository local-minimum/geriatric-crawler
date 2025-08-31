extends SpaceshipRoom

func _on_go_to_bed_pressed() -> void:
    __GlobalGameState.go_to_next_day()

func _on_stare_shelf_pressed() -> void:
    NotificationsManager.info(tr("SHELVES"), tr("STARE_EMPTY_SHELVES"))
