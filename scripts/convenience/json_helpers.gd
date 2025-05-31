class_name JsonHelpers

static func to_vector3i(data: Variant) -> Vector3i:
    if data is Array[int]:
        var arr: Array[int] = data
        if arr.size() == 3:
            return Vector3i(arr[0], arr[1], arr[2])

    push_error("%s is not a serialized vector3i" % data)
    return Vector3i.ZERO
