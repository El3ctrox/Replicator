return if game:GetService("RunService"):IsServer()
    then require(script.server)
    else require(script.client)