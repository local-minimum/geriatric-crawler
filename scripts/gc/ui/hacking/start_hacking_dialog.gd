extends ConfirmationDialog
class_name  StartHackingDialog

static var _instance: StartHackingDialog

@export var _difficulty: Label
@export var _attempts: Label
@export var _dangerous: Label

@export var _danger_low_color: Color

@export var _danger_slight_color: Color

@export var _danger_default_color: Color

@export var _danger_severe_color: Color

@export var _worms_label: Label
@export var _worms_count: Label

@export var _bombs_label: Label
@export var _bombs_count: Label

@export var _proxies_label: Label
@export var _proxies_count: Label

@export var _deploy_proxies_button: Button

var _on_abort: Callable
var _on_hack: Callable

var _danger: HackingGame.Danger
var _on_change_danger: Callable

var _inv: Inventory.InventorySubscriber

static func show_dialog(
    dialog_title: String,
    difficulty: int,
    attempts: int,
    danger: HackingGame.Danger,
    on_change_danger: Callable,
    on_abort: Callable,
    on_hack: Callable,
) -> void:
    _instance.title = dialog_title
    _instance._difficulty.text = "%s" % difficulty

    _instance._danger = danger

    _instance._sync_player_info(attempts)

    _instance._on_abort = on_abort
    _instance._on_hack = on_hack
    _instance._on_change_danger = on_change_danger

    _instance.show()

func _enter_tree() -> void:
    _inv = Inventory.InventorySubscriber.new()

func _ready() -> void:
    _worms_label.text = GCLootableManager.translate(GCLootableManager.ITEM_HACKING_WORM, 999)
    _bombs_label.text = GCLootableManager.translate(GCLootableManager.ITEM_HACKING_BOMB, 999)
    _proxies_label.text = GCLootableManager.translate(GCLootableManager.ITEM_HACKING_PROXY, 99)

    _instance = self
    _instance.hide()

func danger_to_color(danger: HackingGame.Danger) -> Color:
    match danger:
        HackingGame.Danger.LOW: return _danger_low_color
        HackingGame.Danger.SLIGHT: return _danger_slight_color
        HackingGame.Danger.DEFAULT: return _danger_default_color
        HackingGame.Danger.SEVERE: return _danger_severe_color
        _:
            push_error("Danger %s not handled" % danger)
            return _danger_default_color

func _sync_player_info(attempts: int) -> void:
    _attempts.text = "%s" % attempts

    _sync()

func _sync() -> void:
    _worms_count.text = "%03d" % roundi(_inv.inventory.get_item_count(GCLootableManager.ITEM_HACKING_WORM))

    _bombs_count.text = "%03d" % roundi(_inv.inventory.get_item_count(GCLootableManager.ITEM_HACKING_BOMB))

    var proxies: int = roundi(_inv.inventory.get_item_count(GCLootableManager.ITEM_HACKING_PROXY))
    _proxies_count.text = "%03d" % proxies
    _deploy_proxies_button.disabled = proxies == 0 || _danger == HackingGame.Danger.LOW

    _dangerous.text = HackingGame.danger_to_text(_danger)
    _dangerous.add_theme_color_override("font_color", danger_to_color(_danger))

func _on_canceled() -> void:
    hide()
    _on_abort.call()

func _on_confirmed() -> void:
    hide()
    _on_hack.call()

func _on_deploy_proxy_button_pressed() -> void:
    if _inv.inventory.remove_from_inventory(GCLootableManager.ITEM_HACKING_PROXY, 1.0) != 1.0:
        NotificationsManager.warn(tr("NOTICE_HACKING_PROXY"), tr("HACKING_PROXY_FAILED_DEPLOY"))
        _sync()
        return

    _danger = HackingGame.decrease_danger(_danger)
    _on_change_danger.call(_danger)
    _sync()

    NotificationsManager.info(tr("NOTICE_HACKING_PROXY"), tr("HACKING_PROXY_DEPLOYED"))
