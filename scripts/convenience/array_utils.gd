class_name ArrayUtils

static func erase_all_occurances(arr: Array, element: Variant) -> void:
    for idx: int in range(arr.count(element)):
        arr.erase(element)

static func shift_nulls_to_end(arr: Array) -> void:
    var x: int = arr.size() - 1
    while x >= 0:
        if arr[x] != null:
            for y: int in range(x - 1, -1, -1):
                if arr[y] == null:
                    for z: int in range(y, x):
                        arr[z] = arr[z + 1]
                    arr[x] = null
                    x = y
                    break
                if y == 0:
                    return
        x -= 1


static func int_range(n: int) -> Array[int]:
    var r: Array[int] = []

    if r.resize(n) != OK:
        pass

    for idx: int in range(n):
        r[idx] = idx

    return r

static func sumi(arr: Array[int], start_value: int = 0) -> int:
    return arr.reduce(
        func summer(acc: Variant, value: Variant) -> Variant:
            return acc + value,
        start_value,
    )

static func maxi(arr: Array, pred: Callable, start_value: int = 0) -> int:
    return arr.reduce(
        func summer(acc: Variant, item: Variant) -> int:
            var value: Variant = pred.call(item)
            if value is int:
                @warning_ignore_start("unsafe_cast")
                return max(acc, value as int)
                @warning_ignore_restore("unsafe_cast")
            return acc,
        start_value,
    )

static func shuffle_array(arr: Array) -> void:
    for from: int in range(arr.size() - 1, 0, -1):
        var to: int = randi_range(0, from - 1)
        var val: Variant = arr[to]
        arr[to] = arr[from]
        arr[from] = val

static func shuffle_packed_string_array(arr: PackedStringArray) -> void:
    for from: int in range(arr.size() - 1, 0, -1):
        var to: int = randi_range(0, from - 1)
        var val: String = arr[to]
        arr[to] = arr[from]
        arr[from] = val

static func order_by(arr: Array, order_indexes: Array) -> void:
    var copy: Array = arr.duplicate()
    for idx: int in range(order_indexes.size()):
        arr[idx] = copy[order_indexes[idx]]

static func first(arr: Array, predicate: Callable) -> Variant:
    for item: Variant in arr:
        if predicate.call(item):
            return item

    return null
