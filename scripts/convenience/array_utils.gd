class_name ArrayUtils

static func erase_all_occurances(arr: Array, element: Variant) -> void:
    for idx: int in range(arr.count(element)):
        arr.erase(element)
