extends ConfirmationDialog
class_name  StartHackingDialog

enum Danger { LOW, SLIGHT, DEFAULT, SEVERE }

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

static func danger_to_text(danger: Danger) -> String:
    match danger:
        Danger.LOW: return "Failing is as safe as it gets"
        Danger.SLIGHT: return "Failure most likely prompt some reaction"
        Danger.DEFAULT: return "Failure will have consequences"
        Danger.SEVERE: return "The fallout of failing will be severe"
        _:
            push_error("%s is not a handled danger level" % danger)
            return "Unknown risk of consequences"

static func decrease_danger(danger: Danger) -> Danger:
    match danger:
        Danger.LOW: return Danger.LOW
        Danger.SLIGHT: return Danger.LOW
        Danger.DEFAULT: return Danger.SLIGHT
        Danger.SEVERE: return Danger.DEFAULT
        _:
            push_error("Danger %s not handled" % danger)
            return Danger.DEFAULT

signal on_change_danger(danger: Danger)

@export
var _difficulty: Label

@export
var _attempts: Label

@export
var _dangerous: Label

@export
var _danger_low_color: Color

@export
var _danger_slight_color: Color

@export
var _danger_default_color: Color

@export
var _danger_severe_color: Color

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

@export
var _deploy_proxies_button: Button

var _on_abort: Callable
var _on_hack: Callable

var _danger: Danger

static func show_dialog(
    robot: Robot,
    dialog_title: String,
    difficulty: int,
    danger: Danger,
    on_abort: Callable,
    on_hack: Callable,
) -> void:
    _instance.title = dialog_title
    _instance._difficulty.text = "%s" % difficulty

    _instance._danger = danger

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

func danger_to_color(danger: Danger) -> Color:
    match danger:
        Danger.LOW: return _danger_low_color
        Danger.SLIGHT: return _danger_slight_color
        Danger.DEFAULT: return _danger_default_color
        Danger.SEVERE: return _danger_severe_color
        _:
            push_error("Danger %s not handled" % danger)
            return _danger_default_color

func _sync_player_info(robot: Robot, difficulty: int) -> void:
    var skill: int = robot.get_skill_level(RobotAbility.SKILL_BYPASS)
    var attempts: int = maxi(BASE_ATTEMPTS + skill - difficulty,  1)
    _attempts.text = "%s" % attempts

    _sync()

func _sync() -> void:

    var inventory: Inventory = Inventory.active_inventory

    _worms_count.text = "%03d" % roundi(inventory.get_item_count(ITEM_HACKING_WORM))

    _bombs_count.text = "%03d" % roundi(inventory.get_item_count(ITEM_HACKING_BOMB))

    var proxies: int = roundi(inventory.get_item_count(ITEM_HACKING_PROXY))
    _proxies_count.text = "%03d" % proxies
    _deploy_proxies_button.disabled = proxies == 0 || _danger == Danger.LOW

    _dangerous.text = danger_to_text(_danger)
    _dangerous.add_theme_color_override("font_color", danger_to_color(_danger))
    on_change_danger.emit(_danger)

func _on_canceled() -> void:
    hide()
    _on_abort.call()

func _on_confirmed() -> void:
    hide()
    _on_hack.call()

func _on_deploy_proxy_button_pressed() -> void:
    var inventory: Inventory = Inventory.active_inventory
    if inventory.remove_from_inventory(ITEM_HACKING_PROXY, 1.0) != 1.0:
        NotificationsManager.warn("Proxy", "Failed to deploy proxy")
        _sync()
        return

    _danger = decrease_danger(_danger)
    on_change_danger.emit(_danger)
    _sync()

    NotificationsManager.info("Proxy", "Successfully deployed")
