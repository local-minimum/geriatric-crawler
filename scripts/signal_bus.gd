extends Node
class_name SignalBus

@warning_ignore_start("unused_signal")
# Time
signal on_update_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int)
signal on_increment_day(day_of_month: int, days_until_end_of_month: int)

# Credits
signal on_update_credits(credits: int, loans: int)
signal on_update_interest_rate(rate_points: int)
signal on_update_rent(rent: int)

# Spaceship
signal on_before_deploy(level_id: String, robot: RobotsPool.SpaceshipRobot, duration_days: int, insured: bool)

# Saving and loading
signal on_before_save()
signal on_save_complete()
signal on_before_load()
signal on_load_complete()
signal on_fail_load()
@warning_ignore_restore("unused_signal")
