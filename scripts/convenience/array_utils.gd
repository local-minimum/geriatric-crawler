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
