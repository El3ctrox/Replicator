--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
type Signal = Signal.Signal

--// Module
local ServerSignal = {}

--// Factory
function ServerSignal.wrap(bindableEvent: BindableEvent & { Replicator: RemoteEvent })
    
    --// Instance
    local self = Signal.wrap(bindableEvent)
    local remoteEvent = bindableEvent.Replicator
    
    --// Listeners
	remoteEvent.OnClientEvent:Connect(function(...)
		
		self:_tryEmit(...)
	end)
	
    --// End
    return self
end
export type ServerSignal<data...> = Signal<data...>

--// End
return ServerSignal