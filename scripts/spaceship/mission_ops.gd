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
func _on_select_robot_pressed() -> void:
    if _showing_options:
        UIUtils.clear_control(robot_listing_container)
        robot_listing_panel.hide()
        _showing_options = false
        return

    _showing_options = true

    var options: Array[RobotsPool.SpaceshipRobot] = spaceship.robots_pool.available_robots()
    if options.is_empty():
        var label: Label = Label.new()
        label.text = tr("NO_ROBOTS_AVAILABLE") if !spaceship.robots_pool._robots.is_empty() else "\n".join([tr("NO_ROBOTS_AVAILABLE"), tr("CONSTRUCT_FIRST_ROBOT")])
        label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
        robot_listing_container.add_child(label)

    else:
        # TODO: List robots
        pass

    robot_listing_panel.show()

func _on_loadout_pressed() -> void:
    pass # Replace with function body.


func _on_deploy_pressed() -> void:
    pass # Replace with function body.
