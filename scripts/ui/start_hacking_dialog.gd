extends ConfirmationDialog
class_name  StartHackingDialog

const ITEM_HACKING_PREFIX: String = "hacking-"
const ITEM_HACKING_WORM: String = "hacking-worms"
const ITEM_HACKING_BOMB: String = "hacking-bombs"
const ITEM_HACKING_PROXY: String = "hacking-proxys"
const BASE_ATTEMPTS: int = 3

static func item_id_to_text(id: String) -> String:
    match id:
        ITEM_HACKING_BOMB: return "Logical Bombs"
        ITEM_HACKING_WORM: return "Worms"
        ITEM_HACKING_PROXY: return "Proxies"
        _:
            push_warning("%s is not a known hacking item id" % id)
            return ""

static var _instance: StartHackingDialog

@export
var _difficulty: Label

@export
var _attempts: Label

@export
var _dangerous: Label

@export
var _worms_label: Label

@export
var _worms_count: Label

@export
var _bombs_label: Label

@export
var _bombs_count: Label

@export
var _proxies_label: Label

@export
var _proxies_count: Label

var _on_abort: Callable
var _on_hack: Callable

static func show_dialog(
    robot: Robot,
    dialog_title: String,
    difficulty: int,
    dangerous: bool,
    on_abort: Callable,
    on_hack: Callable,
) -> void:
    _instance.title = dialog_title
    _instance._difficulty.text = "%s" % difficulty
    _instance._dangerous.visible = dangerous

    _instance._sync_player_info(robot, difficulty)

    _instance._on_abort = on_abort
    _instance._on_hack = on_hack

    _instance.show()

func _ready() -> void:
    _worms_label.text = item_id_to_text(ITEM_HACKING_WORM)
    _bombs_label.text = item_id_to_text(ITEM_HACKING_BOMB)
    _proxies_label.text = item_id_to_text(ITEM_HACKING_PROXY)

    _instance = self
    _instance.hide()

func _sync_player_info(robot: Robot, difficulty: int) -> void:
    var skill: int = robot.get_skill_level(RobotAbility.SKILL_BYPASS)
    var attempts: int = maxi(BASE_ATTEMPTS + skill - difficulty,  1)
    _attempts.text = "%s" % attempts

    var inventory: Inventory = Inventory.active_inventory
    _worms_count.text = "%03d" % roundi(inventory.get_item_count(ITEM_HACKING_WORM))
    _bombs_count.text = "%03d" % roundi(inventory.get_item_count(ITEM_HACKING_BOMB))
    _proxies_count.text = "%03d" % roundi(inventory.get_item_count(ITEM_HACKING_PROXY))


func _on_canceled() -> void:
    hide()
    _on_abort.call()


func _on_confirmed() -> void:
    hide()
    _on_hack.call()
