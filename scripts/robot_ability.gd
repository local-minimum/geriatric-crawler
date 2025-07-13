extends Resource
class_name RobotAbility

enum AbilityType { Exploration, Battle }

@export
var id: String

@export
var skill_level: int

func full_id() -> String: return "%s-%s" % [id, skill_level]

@export
var ability_type: AbilityType

@export
var description: String

@export
var icon: Texture
