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

static func start(robot: Robot, difficulty: int, attempts: int, on_complete_success: Callable, on_complete_fail: Callable) -> void:
    _instance._start(robot, difficulty, attempts, on_complete_success, on_complete_fail)

signal on_change_attempts(attempts: int)
signal on_solve_game(solution_start: Vector2i)
signal on_fail_game()
signal on_new_attempts(attempts: Array[Array], statuses: Array[Array])
signal on_board_changed()

@export
var ui: HackingGameUI

var _danger: Danger
var _difficulty: int
var _attempts: int:
    set(value):
        _attempts = maxi(value, 0)
        on_change_attempts.emit(_attempts)
        if _attempts == 0 && !_solved:
            on_fail_game.emit()

var _on_complete_success: Callable
var _on_complete_fail: Callable
var _alphabet: PackedStringArray
var _passphrase: PackedStringArray

func get_passphrase_length() -> int: return _passphrase.size()

var discovered_present: Array[String]
var discovered_not_present: Array[String]

var _board: Array[Array]
var _statuses: Array[Array]

var width: int
var height: int
var _solved: bool
var _robot: Robot

func _ready() -> void:
    _instance = self

func _handle_new_danger(danger: Danger) -> void:
    _danger = danger

func _start(robot: Robot, difficulty: int, attempts: int, on_complete_success: Callable, on_complete_fail: Callable) -> void:
    _robot = robot
    _solved = false
    _difficulty = difficulty
    _attempts = attempts
    _on_complete_success = on_complete_success
    _on_complete_fail = on_complete_fail

    discovered_present.clear()
    discovered_not_present.clear()

    _generate_alphabet()
    _generate_passphrase()
    _create_solved_game_board()
    _shuffle_game_board()
    ui.show_game()

func end_game() -> void:
    if _solved:
        _on_complete_success.call()
    else:
        _handle_punishment()
        _on_complete_fail.call()

func _handle_punishment() -> void:
    # TODO: Add punishments
    pass

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

var _longest_solution_start: Vector2i

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

            if current_length > max_length:
                max_length = current_length
                _longest_solution_start = Vector2i(col - current_length + 1, row)

    return max_length

func has_coordinates(coords: Vector2i) -> bool:
    return coords.y >= 0 && coords.y < height && coords.x >= 0 && coords.x < width

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
    var attempts: Array[Array]
    var statuses: Array[Array]
    var attempt: Array[String]
    var solution: Array[WordStatus]

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
                if current_length == 0:
                    solution = [WordStatus.CORRECT]
                    statuses.append(solution)
                    attempt = [word]
                    attempts.append(attempt)
                    current_length += 1
                elif _has_unsused_word_occurance(word):
                    solution.append(WordStatus.CORRECT)
                    attempt.append(word)
                    current_length += 1
                    if current_length >= _passphrase.size():
                        current_length = 0
                else:
                    current_length = 0
                    solution = [WordStatus.CORRECT]
                    statuses.append(solution)
                    attempt = [word]
                    attempts.append(attempt)

                _statuses[row][col] = WordStatus.CORRECT
                if !discovered_present.has(word):
                    discovered_present.append(word)

            elif current_length > 0 && _has_unsused_word_occurance(word):
                _statuses[row][col] = WordStatus.WRONG_POSITION
                solution.append(WordStatus.WRONG_POSITION)
                attempt.append(word)
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
    var reduced_attempts: Array[Array]
    var reduced_statuses: Array[Array]
    _reduce_hacked_attempts(attempts, statuses, reduced_attempts, reduced_statuses)

    on_new_attempts.emit(reduced_attempts, reduced_statuses)

    if _solved:
        print_debug(_board_solution_length())
        on_solve_game.emit(_longest_solution_start)

func _has_unsused_word_occurance(word: String) -> bool:
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

func _reduce_hacked_attempts(attempts: Array[Array], statuses: Array[Array], reduced_attempts: Array[Array], reduced_statuses: Array[Array]) -> void:
    if statuses.size() == 0:
        return

    var sort_order: Array = range(statuses.size())
    sort_order.sort_custom(
        func (a_idx: int, b_idx: int) -> bool:
            var a: Array[WordStatus] = statuses[a_idx]
            var b: Array[WordStatus] = statuses[b_idx]
            if a.size() > b.size():
                return true
            elif a.size() == b.size():
                return a.count(WordStatus.CORRECT) > b.count(WordStatus.CORRECT)

            return false
    )

    ArrayUtils.order_by(attempts, sort_order)
    ArrayUtils.order_by(statuses, sort_order)

    for idx: int in range(attempts.size()):
        var attempt: Array[String] = attempts[idx]
        var status: Array[WordStatus] = statuses[idx]

        if status.count(WordStatus.CORRECT) == _passphrase.size():
            _solved = true
            reduced_attempts.clear()
            reduced_statuses.clear()
            reduced_attempts.append(attempt)
            reduced_statuses.append(status)
            return

        var has_better: bool = false
        for better: Array[String] in reduced_attempts:
            has_better = true
            for idx2: int in range(status.size()):
                if attempt[idx2] != better[idx2]:
                    has_better = false
                    break

            if has_better:
                break

        if !has_better:
            reduced_attempts.append(attempt)
            reduced_statuses.append(status)

const target_offsets: Array[Vector2i] = [
    Vector2i.ZERO,
    Vector2i.DOWN,
    Vector2i.UP,
    Vector2i.LEFT,
    Vector2i.RIGHT,
]

func get_potential_bomb_target(center: Vector2i) -> Array[Vector2i]:
    var targets: Array[Vector2i]
    for offset: Vector2i in target_offsets:
        var coords: Vector2i = center + offset
        if !has_coordinates(coords):
            continue

        if get_word_status(coords) == WordStatus.DEFAULT:
            targets.append(coords)

    return targets

func bomb_coords(coords: Array[Vector2i]) -> void:
    if coords.size() == 0 || Inventory.active_inventory.remove_from_inventory(ITEM_HACKING_BOMB, 1.0, false, false) != 1.0:
        return

    var found: int = 0

    for coord: Vector2i in coords:
        var word: String = get_word(coord)
        var not_in_phrase: bool = !_passphrase.has(word)
        _statuses[coord.y][coord.x] = WordStatus.DESTROYED if not_in_phrase else WordStatus.WRONG_POSITION
        if not_in_phrase:
            if !discovered_not_present.has(word):
                discovered_not_present.append(word)
        else:
            found += 1
            if !discovered_present.has(word):
                discovered_present.append(word)

    var skill: RobotAbility = _robot.get_active_skill_level(RobotAbility.SKILL_HACKING_BOMBS)

    if skill != null && skill.skill_level > 0:
        if randi_range(0, 10) < found:
            if !Inventory.active_inventory.add_to_inventory(HackingGame.ITEM_HACKING_BOMB, 1.0, false):
                push_warning("Could not regain bomb")
            else:
                NotificationsManager.important(skill.skill_name, "Bomb refunded")

    on_board_changed.emit()
