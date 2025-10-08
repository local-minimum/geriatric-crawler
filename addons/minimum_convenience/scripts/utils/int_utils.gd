class_name IntUtils

static var _ROMANS: Array[String] = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
static var _DIGITS: Array[int] = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]

static func to_roman(value: int) -> String:
    var idx: int = 0
    var end: int = mini(_ROMANS.size(), _DIGITS.size()) - 1

    var result: Array[String] = []

    while idx <= end:
        if value >= _DIGITS[idx]:
            result.append(_ROMANS[idx])
            value -= _DIGITS[idx]
        else:
            idx += 1

    return "".join(result)

static func not_negative(value: int) -> bool: return value >= 0
static func negative(value: int) -> bool: return value < 0
static func positive(value: int) -> bool: return value > 0
static func not_positive(value: int) -> bool: return value <= 0
