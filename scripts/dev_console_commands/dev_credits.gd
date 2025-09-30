extends MinimumDevCommand

func execute(parameters: String, console: MinimumDevConsole) -> bool:
    var params: PackedStringArray = parameters.to_lower().split(" ")

    match Array(params):
        ["gain", var gain]:
            if gain is String:
                var gain_string: String = gain
                var value: int = gain_string.to_int()
                if value > 0:
                    __GlobalGameState.deposit_credits(value)
                    console.output_info("Gained %s credits" % value)
                    return true
        ["loose", var loss]:
            if loss is String:
                var loss_string: String = loss
                var value: int = loss_string.to_int()
                if value > 0:
                    if !__GlobalGameState.withdraw_credits(value):
                        NotificationsManager.warn("Dev-Console", "Could not withdraw %s credits" % value)
                        console.output_error("Could not withdraw %s credits" % value)
                    else:
                        console.output_info("Lost %s credits" % value)
                        return true
    return false
