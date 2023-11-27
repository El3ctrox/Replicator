--// Packages
local wrapper = require(script.Parent.Parent.Wrapper)
local Promise = require(script.Parent.Parent.Promise)
type Promise = Promise.Promise

local ServerSignal = require(script.ServerSignal)
type ServerSignal<data...> = ServerSignal.ServerSignal<data...>

--// Module
local Replication = {}

--// Cache
local replications = setmetatable({}, { __mode = "k" })
function Replication.await(container: Instance)
    
    local replication = replications[container] or Replication.wrap(container)
    while replication:isLoading() do task.wait() end
    
    return replication
end

--// Factory
function Replication.wrap(container: Instance)
    
    local self = wrapper(container)
    local loadedFields = 0
    
    --// Functions
    local function setupRemoteFunction(remoteFunction: RemoteFunction)
        
        local function invoke(_self,...: any)
            
            return Promise.try(remoteFunction.InvokeServer, remoteFunction,...)
        end
        self[`invoke{remoteFunction.Name}Async`] = invoke
    end
    local function setupRemoteEvent(remoteEvent: RemoteEvent)
        
        remoteEvent:WaitForChild("LocalEvent")
        
        local serverSignal = ServerSignal.wrap(remoteEvent)
        self[remoteEvent.Name] = serverSignal
    end
    local function setupRemote(child: Instance)
        
        if not child:HasTag("RemoteField") then return end
        
        if child:IsA("RemoteFunction") then setupRemoteFunction(child)
        elseif child:IsA("RemoteEvent") then setupRemoteEvent(child)
        end
        loadedFields += 1
    end
    
    --// Methods
    function self:isLoading(): boolean?
        
        return not self.releasedRemoteFields or loadedFields < self.releasedRemoteFields
    end
    
    --// Setup
    for _,child in container:GetChildren() do setupRemote(child) end
    container.ChildAdded:Connect(setupRemote)
    
    --// End
    replications[container] = self
    return self
end

type asyncFunction = (...any) -> Promise
export type Replication = {
    [string]: asyncFunction|ServerSignal<...any>,
}

--// End
return Replication