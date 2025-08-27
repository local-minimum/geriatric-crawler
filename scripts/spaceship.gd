extends Node
class_name Spaceship

enum Room { NONE, NAV, MISSION_OPS, LIVING_QUARTERS, MATERIALS_LAB, PRINTERS, INFIRMARY, STORAGE_BAY, ENGINE_ROOM, BROOM_CLOSET }

@export var chap_ui: ChapUI
@export var rooms: Dictionary[Room, SpaceshipRoom]
@export var inventory: Inventory
@export var robots_pool: RobotsPool

var room: Room = Room.NONE

func _ready() -> void:
    _sync_rooms()

func _sync_rooms() -> void:
    for r: Room in rooms:
        if r == room:
            rooms[r].activate()
        else:
            rooms[r].deactivate()

func _on_mission_ops_btn_pressed() -> void:
    _move_to_room(Room.MISSION_OPS)

func _move_to_room(new_room: Room) -> void:
    # TODO: Transition to no-room if needed

    # TODO: Walk over to room and then
    room = new_room
    _sync_rooms()
