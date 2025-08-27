extends Node
class_name SaveVersionMigration

@export var applies_from: Version

func applicable(save_version: Version) -> bool:
    return applies_from.higher_or_equal(save_version)

func migrate_save(save_data: Dictionary) -> Dictionary:
    return save_data
