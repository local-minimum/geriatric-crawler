extends Node
class_name Spaceship

enum Room { NONE, NAV, MISSION_OPS, LIVING_QUARTERS, MATERIALS_LAB, PRINTERS, INFIRMARY, STORAGE_BAY, ENGINE_ROOM, BROOM_CLOSET }

static func to_room(room_value: int, default: Room = Room.NONE) -> Room:
    match room_value:
        Room.NAV: return Room.NAV
        Room.MISSION_OPS: return Room.MISSION_OPS
        Room.LIVING_QUARTERS: return Room.LIVING_QUARTERS
        Room.MATERIALS_LAB: return Room.MATERIALS_LAB
        Room.PRINTERS: return Room.PRINTERS
        Room.INFIRMARY: return Room.INFIRMARY
        Room.STORAGE_BAY: return Room.STORAGE_BAY
        Room.ENGINE_ROOM: return Room.ENGINE_ROOM
        Room.BROOM_CLOSET: return Room.BROOM_CLOSET
        Room.NONE: return Room.NONE
        _:
            push_warning("Unknown room %s using %s as defalt" % [room_value, default])
            return default

@export var chap_ui: ChapUI
@export var rooms: Dictionary[Room, SpaceshipRoom]
@export var inventory: Inventory
@export var robots_pool: RobotsPool
@export var printers: PrintersManager

var room: Room = Room.NONE

func _ready() -> void:
    if __SignalBus.on_update_day.connect(_handle_increment_day) != OK:
        push_error("Failed to connect increment day")

    _sync_rooms()


func _handle_increment_day(year: int, month: int, day_of_month: int, days_until_end_of_month: int) -> void:
    if days_until_end_of_month == 1:
        NotificationsManager.warn(tr("NOTICE_NEW_DAY"), tr("DAY_UNTIL_RENT"))
    elif days_until_end_of_month > 0 && days_until_end_of_month < 4:
        NotificationsManager.warn(tr("NOTICE_NEW_DAY"), tr("DAYS_UNTIL_RENT").format({"days": days_until_end_of_month }))
    else:
        NotificationsManager.info(
            tr("NOTICE_NEW_DAY"),
            tr("IT_IS_DATE").format({"date": tr("DATE_FORMAT").format({"year": year, "month": month, "day": day_of_month})}),
        )

func _sync_rooms() -> void:
    for r: Room in rooms:
        if r == room:
            rooms[r].activate()
        else:
            rooms[r].deactivate()

func _move_to_room(new_room: Room) -> void:
    # TODO: Transition to no-room if needed

    # TODO: Walk over to room and then
    room = new_room
    _sync_rooms()

func _on_mission_ops_btn_pressed() -> void:
    _move_to_room(Room.MISSION_OPS)

func _on_printers_btn_pressed() -> void:
    _move_to_room(Room.PRINTERS)

func _on_living_quarters_btn_pressed() -> void:
    _move_to_room(Room.LIVING_QUARTERS)

func save() -> void:
    __SaveSystemWrapper.autosave()
