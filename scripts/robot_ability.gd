extends Resource
class_name RobotAbility

const SKILL_SUIT: String = "suits"
const SKILL_RANK: String = "rank"

## LVL 0: Only floors, LVL 1: Stairs/Ladders, LVL 2: Wallwalking, LVL 3: Ceiling too
const SKILL_CLIMBING: String = "climbing"

## LVL 1: Earn progress beyond unlocked, LVL 2: Skip buying on level, LVL 3: Buy multiple of same level, LVL 4: Unlimited buys per level
const SKILL_UPGRADES: String = "upgrades"

## LVL 1: Compass, LVL 2: Simple map, LVL 3: 3D map, LVL 4: Annotation
const SKILL_MAPPING: String = "mapping"

## LVL 1: Detect enemies, LVL 2: Detect enemies & hidden objects
const SKILL_SONAR: String = "sonar"

## LVL 1-4: Increasing proficiency
const SKILL_BYPASS: String = "bypass"

## LVL 1: Minimum tools
const SKILL_HACKING_BOMBS: String = "hacking-bombs"

## Handsize is level + 4
const SKILL_HAND_SIZE: String = "hand"

## LVL 1 Bonus stays to next round, LVL 2: Last card remembered to next round, LVL 3: Also remembers to next battle
const SKILL_HAND_MEMORY: String = "memory"

## Cards to slot is level + 1
const SKILL_HAND_SLOTS: String = "slots"

enum AbilityType { Exploration, Battle, Other }

## Class id of the ability (doesn't include the level of the ability)
@export var id: String

@export var skill_level: int

func full_id() -> String: return "%s-%s" % [id, skill_level]

@export var skill_name: String

func full_skill_name() -> String:
    return "%s %s" % [skill_name, IntUtils.to_roman(skill_level)]

@export var ability_type: AbilityType

@export var description: String

@export var icon: Texture
