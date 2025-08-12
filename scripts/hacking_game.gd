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

@export
var ui: HackingGameUI

var _danger: Danger
var _difficulty: int
var _attempts: int:
    set(value):
        _attempts = value
        on_change_attempts.emit(value)

var _on_complete: Callable
var _alphabet: PackedStringArray
var _passphrase: PackedStringArray

var discovered_present: Array[String]
var discovered_not_present: Array[String]

var _board: Array[Array]
var _statuses: Array[Array]

var width: int
var height: int

func _ready() -> void:
    _instance = self

func _handle_new_danger(danger: Danger) -> void:
    _danger = danger

func _start(difficulty: int, attempts: int, on_complete: Callable) -> void:
    _difficulty = difficulty
    _attempts = attempts
    _on_complete = on_complete

    discovered_present.clear()
    discovered_not_present.clear()

    _generate_alphabet()
    _generate_passphrase()
    _create_solved_game_board()
    _shuffle_game_board()
    ui.show_game()

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

    width = 10 - mini(3, _difficulty)
    height = 5 if _difficulty < 4 else 4
    var tiles: int = width * height

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

    ArrayUtils.shuffle_packed_string_array(non_solution_letters)

    var passphrase_row: int = randi_range(0, height - 1)
    var passphrase_col: int = randi_range(0, width - 1 - _passphrase.size())

    var phrase_next: int = 0
    var non_solution_idx: int = 0

    _board.clear()
    _statuses.clear()

    for row: int in range(height):
        var row_arr: Array[String] = []
        var status_arr: Array[WordStatus] = []

        _board.append(row_arr)
        _statuses.append(status_arr)

        for col: int in range(width):
            if passphrase_row == row && passphrase_col == col:
                row_arr.append(_passphrase[0])
                phrase_next = _passphrase.size() - 1
            elif phrase_next > 0:
                row_arr.append(_passphrase[_passphrase.size() - phrase_next])
                phrase_next -= 1
            else:
                row_arr.append(non_solution_letters[non_solution_idx])
                non_solution_idx += 1

            status_arr.append(WordStatus.DEFAULT)

    # print_debug(_board)

func _shuffle_row(row: int, force: bool = false) -> void:
    var steps: int = randi_range(-5, 5)
    if steps == 0:
        if force:
            steps = randi_range(-5, 4)
            if steps >= 0:
                steps += 1
        else:
            return

    shift_row(row, steps)

func shift_row(row: int, steps: int) -> void:
    var original: Array[String]
    var original_statuses: Array[WordStatus]
    for col: int in range(width):
        original.append(_board[row][col])
        original_statuses.append(_statuses[row][col])

    for col: int in range(width):
        var source: int = posmod(col - steps, width)
        _board[row][col] = original[source]
        _statuses[row][col] = original_statuses[source]


func _shuffle_col(col: int, force: bool = false) -> void:
    var steps: int = randi_range(-3, 3)
    if steps == 0:
        if force:
            steps = randi_range(-5, 4)
            if steps >= 0:
                steps += 1
        else:
            return

    shift_col(col, steps)

func shift_col(col: int, steps: int) -> void:
    var original: Array[String]
    var original_statuses: Array[WordStatus]
    for row: int in range(height):
        original.append(_board[row][col])
        original_statuses.append(_statuses[row][col])

    for row: int in range(height):
        var source: int = posmod(row - steps, height)
        _board[row][col] = original[source]
        _statuses[row][col] = original_statuses[source]

func _shuffle_game_board() -> void:
    for col: int in range(width):
        _shuffle_col(col)

    for row: int in range(height):
        _shuffle_row(row)

    for _idx: int in range(10):
        if _board_solution_length() < _passphrase.size() - 2:
            break

        _shuffle_col(randi_range(0, width - 1), true)
        _shuffle_row(randi_range(0, height - 1), true)

    # print_debug(_board)

func _board_solution_length() -> int:
    var max_length: int = 0
    var in_word: bool = false
    var current_length: int = 0

    for row: int in range(height):
        for col: int in range(width):
            var letter: String = _board[row][col]
            if !in_word:
                if letter == _passphrase[0]:
                    in_word = true
                    current_length = 1
            elif letter == _passphrase[current_length]:
                current_length += 1
                if current_length == _passphrase.size():
                    return current_length
            elif _statuses[row][col] != WordStatus.DESTROYED:
                in_word = false
                current_length = 0

            max_length = maxi(max_length, current_length)

    return max_length

func get_word(coords: Vector2i) -> String:
    return _board[coords.y][coords.x]

func is_discovered_present(coords: Vector2i) -> bool:
    return discovered_present.has(_board[coords.y][coords.x])

func is_discovered_not_present(coords: Vector2i) -> bool:
    return discovered_not_present.has(_board[coords.y][coords.x])

enum WordStatus { DEFAULT, DESTROYED, CORRECT, WRONG_POSITION }


func get_word_status(coords: Vector2i) -> WordStatus:
    return _statuses[coords.y][coords.x]

var _current_pass_try: Array[bool]

func hack() -> void:
    # TODO: Track best solution
    # TODO: Track discovered words

    var current_length: int = 0
    var next_letter: String = _passphrase[0]

    for row: int in range(height):
        _current_pass_try.clear()
        @warning_ignore_start("return_value_discarded")
        _current_pass_try.resize(_passphrase.size())
        @warning_ignore_restore("return_value_discarded")

        for col: int in range(width):
            var status: WordStatus = _statuses[row][col]
            if status == WordStatus.DESTROYED:
                continue

            var word: String = _board[row][col]

            if word == next_letter:
                if _has_unsused_word_occurance(word):
                    current_length += 1
                    if current_length >= _passphrase.size():
                        current_length = 0
                else:
                    current_length = 0

                _statuses[row][col] = WordStatus.CORRECT
                if !discovered_present.has(word):
                    discovered_present.append(word)

            elif current_length > 0 && _has_unsused_word_occurance(word):
                _statuses[row][col] = WordStatus.WRONG_POSITION
                if !discovered_present.has(word):
                    discovered_present.append(word)

                current_length += 1
                if current_length >= _passphrase.size():
                    current_length = 0

            else:
                if current_length > 0:
                    if !discovered_present.has(word) && !discovered_not_present.has(word):
                        discovered_not_present.append(word)

                _statuses[row][col] = WordStatus.DEFAULT
                current_length = 0

            next_letter = _passphrase[current_length]

        current_length = 0
        next_letter = _passphrase[current_length]

    _attempts -= 1

func _has_unsused_word_occurance(word: String) -> bool:
    # TODO: This is wrong!
    for idx: int in range(_passphrase.size()):
        if _current_pass_try[idx]:
            continue
        if _passphrase[idx] == word:
            _current_pass_try[idx] = true
            return true

    _current_pass_try.clear()
    @warning_ignore_start("return_value_discarded")
    _current_pass_try.resize(_passphrase.size())
    @warning_ignore_restore("return_value_discarded")

    return false
