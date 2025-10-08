class_name NodeUtils

static func find_parent_types(node: Node, types: Array[String]) -> Node:
    for type: String in types:
        var parent: Node = find_parent_type(node, type)
        if parent != null:
            return parent

    return null

static func find_parent_type(node: Node, type: String) -> Node:
    if node == null:
        return null

    if node.is_class(type):
        return node
    else:
        var script: Script = node.get_script()
        if script != null:
            if script.get_global_name() == type:
                return node

            while script != null:
                script = script.get_base_script()
                if script != null && script.get_global_name() == type:
                    return node


    return find_parent_type(node.get_parent(), type)
