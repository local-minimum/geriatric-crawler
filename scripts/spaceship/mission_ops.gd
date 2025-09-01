extends SpaceshipRoom
class_name MissionOpsRoom

@export var spaceship: Spaceship
@export var select_robot_btn: Button
@export var loadout_btn: Button
@export var deploy_btn: Button

@export var robot_listing_panel: Control
@export var robot_listing_container: Control

@export var loadout_panel: Control

@export var deploy_panel: Control
@export var deploy_robot_name: Label
@export var deploy_destination_name: Label
@export var deploy_with_insurance_btn: Button

enum PanelPhase {NONE, OPTIONS, LOADOUT, DEPLOY}
var _phase: PanelPhase = PanelPhase.NONE

func activate() -> void:
    select_robot_btn.disabled = false
    loadout_btn.disabled = true
    deploy_btn.disabled = true

    robot_listing_panel.hide()
    loadout_panel.hide()
    deploy_panel.hide()
    _phase = PanelPhase.NONE
    show()

func deactivate() -> void:
    hide()

var _robot_options: Array[RobotSelectOption]

func _clear_previous_listing_if_needed(options: Array[RobotsPool.SpaceshipRobot]) -> bool:
    if (
        _robot_options.size() == 0 ||
        robot_listing_container.get_child_count() != options.size() ||
        _robot_options.size() != options.size() ||
        !_robot_options.all(func (opt: RobotSelectOption) -> bool: return options.has(opt._robot))
    ):
        _robot_options.clear()
        UIUtils.clear_control(robot_listing_container)
        return true
    return false

func _hide_robot_options() -> void:
    robot_listing_panel.hide()
    _phase = PanelPhase.NONE

func _on_select_robot_pressed() -> void:
    loadout_panel.hide()
    deploy_panel.hide()

    if _phase == PanelPhase.OPTIONS:
        _hide_robot_options()
        return

    var options: Array[RobotsPool.SpaceshipRobot] = spaceship.robots_pool.available_robots()

    _phase = PanelPhase.OPTIONS

    if !_clear_previous_listing_if_needed(options):
        robot_listing_panel.show()
        return

    if options.is_empty():
        var label: Label = Label.new()
        label.text = tr("NO_ROBOTS_AVAILABLE") if !spaceship.robots_pool._robots.is_empty() else "\n".join([tr("NO_ROBOTS_AVAILABLE"), tr("CONSTRUCT_FIRST_ROBOT")])
        label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
        robot_listing_container.add_child(label)

    else:
        var template: PackedScene = load("res://scenes/spaceship/robot_select_option.tscn")

        for robot: RobotsPool.SpaceshipRobot in spaceship.robots_pool.available_robots():
            var instance: RobotSelectOption = template.instantiate()
            instance.sync(robot)
            instance.sync_selection(_selected_robot)

            if instance.on_select_robot.connect(_handle_select_option) != OK:
                push_error("Failed to connect select robot")
            if instance.on_deselect_robot.connect(_handle_deselect_option) != OK:
                push_error("Failed to connect deselect robot")

            robot_listing_container.add_child(instance)
            _robot_options.append(instance)

    robot_listing_panel.show()

var _selected_robot: RobotsPool.SpaceshipRobot

func _handle_select_option(robot: RobotsPool.SpaceshipRobot) -> void:
    _selected_robot = robot
    for option: RobotSelectOption in _robot_options:
        option.sync_selection(robot)

    if robot != null:
        print_debug("Selected robot %s" % robot.given_name)

    loadout_btn.disabled = _selected_robot == null
    deploy_btn.disabled = true
    deploy_with_insurance_btn.disabled = false

func _handle_deselect_option(robot: RobotsPool.SpaceshipRobot) -> void:
    if _selected_robot == robot && _selected_robot != null:
        _selected_robot = null

        print_debug("Delected robot")

        loadout_btn.disabled = _selected_robot == null
        deploy_btn.disabled = _selected_robot == null
        deploy_with_insurance_btn.disabled = false

func _on_loadout_pressed() -> void:
    if _phase == PanelPhase.LOADOUT:
        loadout_panel.hide()
        _phase = PanelPhase.NONE
        return

    _hide_robot_options()
    loadout_panel.show()
    deploy_panel.hide()
    _phase = PanelPhase.LOADOUT

func _calculate_insurance_cost() -> int:
    # TODO: Make insurer system
    return ceili(_selected_robot.model.production.credits * 0.7) + 50

func _on_deploy_pressed() -> void:
    if _phase == PanelPhase.DEPLOY:
        _phase = PanelPhase.NONE
        deploy_panel.hide()
        return

    _hide_robot_options()
    loadout_panel.hide()

    if _selected_robot == null:
        NotificationsManager.warn(tr("MISSION_OPS"), tr("NO_ROBOT_SELECTED"))
        return

    deploy_robot_name.text = _selected_robot.given_name
    # TODO: Fix actual destinations
    deploy_destination_name.text = tr("TRAINING_GROUNDS")
    deploy_with_insurance_btn.text = tr("DEPLOY_WITH_INSURANCE").format({"cost": GlobalGameState.credits_with_sign(_calculate_insurance_cost())})
    deploy_panel.show()
    _phase = PanelPhase.DEPLOY

func _on_unlock_loadouts_pressed() -> void:
    NotificationsManager.warn(tr("NOTICE_SYSTEM_ERROR"), tr("LOADOUT_SYSTEM_NOT_RESPONDING"))

func _on_skip_loadout_pressed() -> void:
    deploy_btn.disabled = false
    _on_deploy_pressed()

func _on_deploy_with_insurance_pressed() -> void:
    var cost: int = _calculate_insurance_cost()
    if !__GlobalGameState.withdraw_credits(cost):
        NotificationsManager.warn(tr("MISSION_OPS"), tr("CANNOT_AFFORD_INSURANCE"))
        deploy_with_insurance_btn.disabled = true
        return

    _on_deploy_without_insurance_pressed(true)

func _on_deploy_without_insurance_pressed(insured: bool = false) -> void:
    print_debug("Make deployment")
    # Out on a mission
    _selected_robot.storage_location = Spaceship.Room.NONE
    _selected_robot.excursions += 1

    # TODO: Fix actual destinations
    __SignalBus.on_before_deploy.emit("test-level", _selected_robot, insured)

    spaceship.save()

    # TODO: Load onto level somehow
