extends Resource
class_name RobotAbility

const SKILL_SUIT: String = "suits"
const SKILL_RANK: String = "rank"

## LVL 0: Only floors, LVL 1: Stairs/Ladders, LVL 2: Wallwalking, LVL 3: Ceiling too
const SKILL_CLIMBING: String = "climbing"

## LVL 1: Earn progress beyond unlocked, LVL 2: Skip buying on level, LVL 3: Buy multiple of same level, LVL 4: Unlimited buys per level
const SKILL_UPGRADES: String = "upgrades"

enum AbilityType { Exploration, Battle, Other }

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
