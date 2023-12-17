--// Packages
local Signal = require(script.Parent.Parent.Signal)
type Signal<data...> = Signal.Signal<data...>

--// Module
local ServerSignal = {}

--// Factory
function ServerSignal.wrap(bindableEvent: model)
    
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
export type model = BindableEvent & { Replicator: RemoteEvent }

--// End
return ServerSignal