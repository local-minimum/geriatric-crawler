extends Node
class_name MinimumDevCommand

## Last is the actual command/sub command and earlier is its place in the hierarchy
@export var command: Array[String]
@export var usage: String
@export_multiline var description: String

## This is the code to execute the command. Returns true if parameters could be executed
## To make a command group simply override with.
## [code]
## func execute(parameters: String, console: MinimumDevConsole) -> void:
##     console.set_context(command)
##     return true
## [/code]
func execute(parameters: String, console: MinimumDevConsole) -> bool:
    push_error("[Minimum Dev Command] %s doesn't handle command its execution, ignoring message \"%s\"" % [command, parameters])
    return false

func in_context(context: Array[String]) -> bool:
    if command.size() < context.size():
        return false

    for idx: int in range(context.size()):
        if command[idx].to_lower() != context[idx].to_lower():
            return false

    return true

func is_context(context) -> bool:
    return in_context(context) && context.size() == command.size()

func is_command(context: Array[String], cmd: String) -> bool:
    if !in_context(context):
        return false

    var remain: Array[String] = command.slice(context.size())
    if remain.is_empty():
        return true

    var parts: PackedStringArray = cmd.split(" ")
    if parts.size() < remain.size():
        return false

    for idx: int in range(remain.size()):
        if remain[idx].to_lower() != parts[idx].to_lower():
            return false

    return true

func visible_command_from_context(context_depth: int) -> String:
    if command.size() > context_depth:
        return " ".join(command.slice(context_depth))

    return ""

func get_subcommand(context_depth: int) -> String:
    if command.size() > context_depth:
        return command[context_depth]
    elif command.size() == context_depth:
        return ""

    push_error("[Minimum Dev Command] %s doesn't have enough depth %s" % [command, context_depth])
    return ""

func strip_cmd(cmd: String, context: Array[String]):
    return cmd.substr(" ".join(command.slice(context.size())).length() + 1).strip_edges()
