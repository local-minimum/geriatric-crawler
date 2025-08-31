extends SpaceshipRoom
class_name MissionOpsRoom

@export var spaceship: Spaceship
@export var select_robot_btn: Button
@export var loadout_btn: Button
@export var deploy_btn: Button

@export var robot_listing_panel: Control
@export var robot_listing_container: Control


func activate() -> void:
    select_robot_btn.disabled = false
    loadout_btn.disabled = true
    deploy_btn.disabled = true

    robot_listing_panel.hide()
    _showing_options = false
    show()

func deactivate() -> void:
    hide()

var _showing_options: bool
var _robot_options: Array[RobotSelectOption]

func _hide_robot_options() -> void:
    UIUtils.clear_control(robot_listing_container)
    robot_listing_panel.hide()
    _showing_options = false

func _on_select_robot_pressed() -> void:
    _robot_options.clear()

    if _showing_options:
        _hide_robot_options()
        return

    _showing_options = true

    var options: Array[RobotsPool.SpaceshipRobot] = spaceship.robots_pool.available_robots()
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

func _handle_deselect_option(robot: RobotsPool.SpaceshipRobot) -> void:
    if _selected_robot == robot && _selected_robot != null:
        _selected_robot = null

        print_debug("Delected robot")

        loadout_btn.disabled = _selected_robot == null

func _on_loadout_pressed() -> void:
    _hide_robot_options()

func _on_deploy_pressed() -> void:
    pass # Replace with function body.
