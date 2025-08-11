extends Node
class_name HackingGame

const ITEM_HACKING_PREFIX: String = "hacking-"
const ITEM_HACKING_WORM: String = "hacking-worms"
const ITEM_HACKING_BOMB: String = "hacking-bombs"
const ITEM_HACKING_PROXY: String = "hacking-proxys"
const BASE_ATTEMPTS: int = 3

enum Danger { LOW, SLIGHT, DEFAULT, SEVERE }

static func item_id_to_text(id: String) -> String:
    match id:
        ITEM_HACKING_BOMB: return "Logical Bombs"
        ITEM_HACKING_WORM: return "Worms"
        ITEM_HACKING_PROXY: return "Proxies"
        _:
            push_warning("%s is not a known hacking item id" % id)
            return ""

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

static var _instance: HackingGame

static func calculate_attempts(robot: Robot, difficulty: int) -> int:
    var skill: int = robot.get_skill_level(RobotAbility.SKILL_BYPASS)
    return maxi(HackingGame.BASE_ATTEMPTS + skill - difficulty,  1)

static func start(difficulty: int, attempts: int, on_complete: Callable) -> void:
    _instance._start(difficulty, attempts, on_complete)

signal on_change_attempts(attempts: int)

var _danger: Danger
var _difficulty: int
var _attempts: int:
    set(value):
        _attempts = value
        on_change_attempts.emit(value)

var _on_complete: Callable
var _alphabet: PackedStringArray
var _passphrase: PackedStringArray
var _board: Array[Array]
var _width: int
var _height: int

func _ready() -> void:
    _instance = self

func _handle_new_danger(danger: Danger) -> void:
    _danger = danger

func _start(difficulty: int, attempts: int, on_complete: Callable) -> void:
    _difficulty = difficulty
    _attempts = attempts
    _on_complete = on_complete

    _generate_alphabet()
    _generate_passphrase()
    _create_solved_game_board()
    _shuffle_game_board()

func _generate_alphabet() -> void:
    var n_letters: int = 8 + mini(_difficulty, 4) * 3
    var letters: PackedInt32Array

    @warning_ignore_start("return_value_discarded")
    letters.resize(n_letters)
    _alphabet.resize(n_letters)
    @warning_ignore_restore("return_value_discarded")

    for idx: int in range(n_letters):
        var value: int = randi_range(0, 255)
        while letters.has(value):
            value = randi_range(0, 255)

        letters[idx] = value
        _alphabet[idx] = "%02X" % value

func _generate_passphrase() -> void:
    var n_letters: int = 3 + mini(3, _difficulty)
    @warning_ignore_start("return_value_discarded")
    _passphrase.resize(n_letters)
    @warning_ignore_restore("return_value_discarded")

    for idx: int in range(n_letters):
        _passphrase[idx] = _alphabet[randi_range(0, _alphabet.size() - 1)]

    print_debug("Passphrase is %s" % _passphrase)

func _create_solved_game_board() -> void:
    var other_letters: Array[String]
    for letter: String in _alphabet:
        if _passphrase.has(letter):
            continue

        other_letters.append(letter)

    _width = 10 - mini(3, _difficulty)
    _height = 5 if _difficulty < 4 else 4
    var tiles: int = _width * _height

    var random_letters: int = tiles - _passphrase.size()
    var non_solution_letters: PackedStringArray
    @warning_ignore_start("return_value_discarded")
    non_solution_letters.resize(random_letters)
    @warning_ignore_restore("return_value_discarded")

    var wanted_dupes_of_passphrase: int = _passphrase.size() * 2 - _difficulty

    for idx: int in range(random_letters):
        if idx < other_letters.size():
            non_solution_letters[idx] = other_letters[idx]
        elif wanted_dupes_of_passphrase > 0:
            non_solution_letters[idx] = _passphrase[randi_range(0, _passphrase.size() - 1)]
            wanted_dupes_of_passphrase -= 1
        else:
            non_solution_letters[idx] = other_letters[randi_range(0, other_letters.size() - 1)]

    _shuffle_packed_string_array(non_solution_letters)

    var passphrase_row: int = randi_range(0, _height - 1)
    var passphrase_col: int = randi_range(0, _width - 1 - _passphrase.size())

    var phrase_next: int = 0
    var non_solution_idx: int = 0
    _board.clear()
    for row: int in range(_height):
        var row_arr: Array = []
        _board.append(row_arr)

        for col: int in range(_width):
            if passphrase_row == row && passphrase_col == col:
                row_arr.append(_passphrase[0])
                phrase_next = _passphrase.size() - 1
            elif phrase_next > 0:
                row_arr.append(_passphrase[_passphrase.size() - phrase_next])
                phrase_next -= 1
            else:
                row_arr.append(non_solution_letters[non_solution_idx])
                non_solution_idx += 1

    print_debug(_board)

func _shuffle_game_board() -> void:
    pass

func _shuffle_packed_string_array(arr: PackedStringArray) -> void:
    for from: int in range(arr.size() - 1, 0, -1):
        var to: int = randi_range(0, from - 1)
        var val: String = arr[to]
        arr[to] = arr[from]
        arr[from] = val
