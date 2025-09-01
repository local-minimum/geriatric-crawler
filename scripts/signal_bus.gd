extends Node
class_name SignalBus

@warning_ignore_start("unused_signal")
signal on_update_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int)
signal on_increment_day(day_of_month: int, days_until_end_of_month: int)

signal on_update_credits(credits: int, loans: int)
signal on_update_interest_rate(rate_points: int)
signal on_update_rent(rent: int)

signal on_before_deploy(level_id: String, robot: RobotsPool.SpaceshipRobot, duration_days: int, insured: bool)
@warning_ignore_restore("unused_signal")
