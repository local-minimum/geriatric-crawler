extends Resource
class_name RobotAbility

enum AbilityType { Exploration, Battle }

## Class id of the ability (doesn't include the level of the ability)
@export
var id: String

@export
var skill_level: int

func full_id() -> String: return "%s-%s" % [id, skill_level]

@export
var skill_name: String

func full_skill_name() -> String:
    return "%s %s" % [skill_name, IntUtils.to_roman(skill_level)]

@export
var ability_type: AbilityType

@export
var description: String

@export
var icon: Texture
