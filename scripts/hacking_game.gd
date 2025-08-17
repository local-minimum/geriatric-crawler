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

static func danger_to_drawn_cards_count(danger: Danger) -> int:
    match danger:
        Danger.LOW:
            return 0 if randf() < 0.85 else 1
        Danger.SLIGHT:
            return 0 if randf() < 0.5 else 1
        Danger.DEFAULT:
            var v: float = randf()
            if v < 0.05:
                return 2
            elif v < 0.9:
                return 1
            else:
                return 0
        Danger.SEVERE:
            var v: float = randf()
            if v < 0.1:
                return 1
            elif v < 0.8:
                return 2
            else:
                return 3
        _:
            push_error("Danger %s not handled" % danger)
            return 1

static var _instance: HackingGame

static func calculate_attempts(robot: Robot, difficulty: int) -> int:
    var skill: int = robot.get_skill_level(RobotAbility.SKILL_BYPASS)
    return maxi(HackingGame.BASE_ATTEMPTS + skill - difficulty,  1)

static func start(
    robot: Robot,
    difficulty: int,
    attempts: int,
    alphabet: PackedStringArray,
    passphrase: PackedStringArray,
    on_complete_success: Callable,
    on_complete_fail: Callable,
) -> void:
    _instance._start(
        robot,
        difficulty,
        attempts,
        alphabet,
        passphrase,
        on_complete_success,
        on_complete_fail,
    )

signal on_change_attempts(attempts: int)
signal on_solve_game(solution_start: Vector2i)
signal on_fail_game()
signal on_new_attempts(attempts: Array[Array], statuses: Array[Array])
signal on_board_changed()

@export var ui: HackingGameUI

var _danger: Danger
var _difficulty: int
var attempts_remaining: int:
    set(value):
        attempts_remaining = maxi(value, 0)
        on_change_attempts.emit(attempts_remaining)
        if attempts_remaining == 0 && !_solved:
            on_fail_game.emit()

var _on_complete_success: Callable
var _on_complete_fail: Callable
var _alphabet: PackedStringArray
var _passphrase: PackedStringArray

func get_passphrase_length() -> int: return _passphrase.size()

var discovered_present: Array[String]
var discovered_not_present: Array[String]
var word_counts: Dictionary[String, int]

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

func _start(
    robot: Robot,
    difficulty: int,
    attempts: int,
    alphabet: PackedStringArray,
    passphrase: PackedStringArray,
    on_complete_success: Callable,
    on_complete_fail: Callable,
) -> void:
    _robot = robot
    _solved = false
    _difficulty = difficulty
    attempts_remaining = attempts
    _alphabet = alphabet
    _passphrase = passphrase

    _on_complete_success = on_complete_success
    _on_complete_fail = on_complete_fail

    discovered_present.clear()
    discovered_not_present.clear()
    word_counts.clear()

    _create_solved_game_board()
    _shuffle_game_board()

    print_debug("Hacking: passphrase is %s" % passphrase)

    ui.show_game()

func end_game() -> void:
    if _solved:
        _on_complete_success.call()
    else:
        _on_complete_fail.call()

static func generate_alphabet(difficulty: int) -> PackedStringArray:
    var alphabet: PackedStringArray
    var n_letters: int = 8 + mini(difficulty, 4) * 3
    var letters: PackedInt32Array

    @warning_ignore_start("return_value_discarded")
    letters.resize(n_letters)
    alphabet.resize(n_letters)
    @warning_ignore_restore("return_value_discarded")

    for idx: int in range(n_letters):
        var value: int = randi_range(0, 255)
        while letters.has(value):
            value = randi_range(0, 255)

        letters[idx] = value
        alphabet[idx] = "%02X" % value

    return alphabet

static func generate_passphrase(difficulty: int, alphabet: PackedStringArray) -> PackedStringArray:
    var passphrase: PackedStringArray
    var n_letters: int = 3 + mini(3, difficulty)
    @warning_ignore_start("return_value_discarded")
    passphrase.resize(n_letters)
    @warning_ignore_restore("return_value_discarded")

    for idx: int in range(n_letters):
        passphrase[idx] = alphabet[randi_range(0, alphabet.size() - 1)]

    # print_debug("Passphrase is %s" % passphrase)
    return passphrase

func _create_solved_game_board() -> void:
    var other_letters: Array[String]
    for letter: String in _alphabet:
        if _passphrase.has(letter):
            continue

        other_letters.append(letter)

    if other_letters.is_empty():
        other_letters.append_array(_alphabet)

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
                if word_counts.has(_passphrase[0]):
                    word_counts[_passphrase[0]] += 1
                else:
                    word_counts[_passphrase[0]] = 1
                phrase_next = _passphrase.size() - 1
            elif phrase_next > 0:
                var idx: int = _passphrase.size() - phrase_next
                row_arr.append(_passphrase[idx])
                if word_counts.has(_passphrase[idx]):
                    word_counts[_passphrase[idx]] += 1
                else:
                    word_counts[_passphrase[idx]] = 1
                phrase_next -= 1
            else:
                row_arr.append(non_solution_letters[non_solution_idx])
                if word_counts.has(non_solution_letters[non_solution_idx]):
                    word_counts[non_solution_letters[non_solution_idx]] += 1
                else:
                    word_counts[non_solution_letters[non_solution_idx]] = 1
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
    var solutions: Array[Array]
    var attempt: Array[String]
    var solution: Array[WordStatus]
    var word_locations: Array[int]

    var part_counts: Dictionary[String, int]

    var passphrase_length: int = _passphrase.size()

    for part: String in _passphrase:
        if part_counts.has(part):
            part_counts[part] += 1
        else:
            part_counts[part] = 1

    for row: int in range(height):
        _current_pass_try.clear()
        @warning_ignore_start("return_value_discarded")
        _current_pass_try.resize(_passphrase.size())
        @warning_ignore_restore("return_value_discarded")

        var base_col: int = -1
        while base_col < width - 1:
            base_col += 1

            solution = []
            word_locations.clear()
            var parts: Dictionary[String, int] = part_counts.duplicate()

            var first_correct: bool

            for first_pass_idx: int in range(passphrase_length):
                var col: int = base_col + first_pass_idx
                if col >= width:
                    break

                var status: WordStatus = _statuses[row][col]
                while status == WordStatus.DESTROYED:
                    base_col += 1
                    col = base_col + first_pass_idx
                    if col >= width:
                        break
                    status = _statuses[row][col]

                if col >= width:
                    break

                var word: String = _board[row][col]
                word_locations.append(col)

                if word == _passphrase[first_pass_idx]:
                    if first_pass_idx == 0:
                        first_correct = true
                    solution.append(WordStatus.CORRECT)
                    parts[word] -= 1
                elif !first_correct:
                    break
                else:
                    solution.append(WordStatus.DEFAULT)

            if !first_correct:
                _statuses[row][base_col] = WordStatus.DEFAULT
                continue

            print_debug("Hacking: locs %s solution %s" % [word_locations, solution])

            var idx: int = -1

            for col: int in word_locations:
                idx += 1

                if solution[idx] == WordStatus.CORRECT:
                    _statuses[row][col] = WordStatus.CORRECT
                    base_col = col
                    continue

                var word: String = _board[row][col]
                if parts.get(word, 0) > 0:
                    _statuses[row][col] = WordStatus.WRONG_POSITION
                    solution[idx] = WordStatus.WRONG_POSITION

                    parts[word] -= 1
                    base_col = col
                else:
                    var in_phrase: bool = _passphrase.has(word)
                    if !in_phrase && !discovered_not_present.has(word):
                        discovered_not_present.append(word)

                    word_locations = word_locations.slice(0, idx if in_phrase else idx + 1)
                    solution = solution.slice(0, word_locations.size())
                    break

            attempt = []

            for phrase_idx: int in range(passphrase_length):
                if phrase_idx < solution.size():
                    var word: String = _board[row][word_locations[phrase_idx]]
                    if _passphrase.has(word) && !discovered_present.has(word):
                        discovered_present.append(word)
                    attempt.append(word)
                else:
                    attempt.append("??")
                    solution.append(WordStatus.DEFAULT)

            solutions.append(solution)
            attempts.append(attempt)

    attempts_remaining -= 1
    var reduced_attempts: Array[Array]
    var reduced_statuses: Array[Array]
    _reduce_hacked_solutions(attempts, solutions, reduced_attempts, reduced_statuses)

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

static func _status_scoring(count: float, status: WordStatus) -> float:
    match status:
        WordStatus.CORRECT:
            return count + 1.0
        WordStatus.WRONG_POSITION:
            return count + 0.7
        _:
            return count

func _reduce_hacked_solutions(
    attempts: Array[Array],
    statuses: Array[Array],
    reduced_attempts: Array[Array],
    reduced_statuses: Array[Array],
) -> void:
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
                var na: float = a.reduce(_status_scoring, 0.0)
                var nb: int = b.reduce(_status_scoring, 0.0)
                return na > nb

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


func use_worm() -> bool:
    return Inventory.active_inventory.remove_from_inventory(ITEM_HACKING_WORM, 1.0, false, false) == 1.0

func worm_consume(coordinates: Vector2i) -> int:
    if !has_coordinates(coordinates):
        return -1

    match get_word_status(coordinates):
        WordStatus.DEFAULT:
            var word: String = get_word(coordinates)
            if _passphrase.has(word):
                _statuses[coordinates.y][coordinates.x] = WordStatus.WRONG_POSITION

                if !discovered_present.has(word):
                    discovered_present.append(word)

                on_board_changed.emit()
                return -1

            var n: int = 1
            if !discovered_not_present.has(word):
                discovered_not_present.append(word)
                n += word_counts.get(word, 1) * 2

            _statuses[coordinates.y][coordinates.x] = WordStatus.DESTROYED
            on_board_changed.emit()
            return n

        WordStatus.DESTROYED:
            return 0
        WordStatus.WRONG_POSITION, WordStatus.CORRECT:
            return -1

    return -1
