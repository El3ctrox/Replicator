--// Packages
local wrapper = require(script.Parent.Parent.Wrapper)

local RemoteSignal = require(script.RemoteSignal)
type RemoteSignal = RemoteSignal.RemoteSignal

--[=[
    @server
    @class Replicator
    
    A class which disponibilize some functions for replication.
    Useful for create remote events and remote functions.
]=]
local Replicator = {}
local replicators = setmetatable({}, { __mode = "k" })

--// Functions
local function query(self: Instance, params: { Name: string?, ClassName: string? }): ...Instance
    
    local result = {}
    
    for _,child in self:GetChildren() do
        
        if params.Name and child.Name ~= params.Name then continue end
        if params.ClassName and not child:IsA(params.ClassName) then continue end
        
        table.insert(result, child)
    end
    
    return unpack(result)
end

--[=[
    @within Replicator
    @function wrap
    @param instance Instance
    @return Replicator
    
    Wraps the instance with a new Replicator.
]=]
function Replicator.wrap(instance: Instance)
    
    local self, meta = wrapper(instance)
    
    --// Owning
    local owner
    local function updateOwner()
        
        owner = instance
        
        while not owner:IsA("Player") do
            
            if owner:IsA("BasePart") and owner:GetNetworkOwner()
                then owner = owner:GetNetworkOwner()
                else owner = owner.Parent end
        end
    end
    instance.AncestryChanged:Connect(updateOwner)
    updateOwner()
    
    --// Replication
    local remoteFields = 0
    self.releasedRemoteFields = nil :: number?
    task.defer(function() self.releasedRemoteFields = remoteFields end)
    
    local function logRemoteField(label: string)
        
        if self.releasedRemoteFields then
            
            warn(`{instance:GetFullName()} {label} has created after client release (you need to avoid yielding since Replicator.get call)`)
            self.releasedRemoteFields += 1
        else
            
            remoteFields += 1
        end
    end
    
    --// Methods
    --[=[
        @within Replicator
        @method _signal
        @param name string  -- name of RemoteEvent
        @return RemoteSignal -- RemoteEvent wrapper
        
        Create a RemoteEvent wrapped by a RemoteSignal.
    ]=]
    function self:_signal(name: string): RemoteSignal
        
        logRemoteField(`signal '{name}'`)
        return self:_host(RemoteSignal.new(name))
    end
    --[=[
        @within Replicator
        @method _function
        @param name string  -- name of RemoteFunction
        @param callback (player: Player,...any) -> any...   -- used as value for RemoteFunction.OnServerInvoke
        
        Creates a RemoteFunction with the given name
    ]=]
    function self:_function<params..., result...>(name: string, callback: (player: Player, params...) -> result...)
        
        assert(not query(instance, { Name = name, ClassName = "RemoteFunction" }))
        logRemoteField(`function '{name}'`)
        
        local remoteFunction = self:_host(Instance.new("RemoteFunction"))
        remoteFunction:AddTag("RemoteField")
        remoteFunction.Name = name
        
        function remoteFunction.OnServerInvoke(player,...)
            
            assert(not owner or player == owner, `permission denied`)
            return callback(player,...)
        end
    end
    
    --// Behaviour
    local super = meta.__newindex
    function meta:__newindex(index, value)
        
        if type(value) == "function" then
            
            self:_function(index, value)
        else
            
            super(self, index, value)
        end
    end
    
    --// End
    replicators[instance] = self
    return self
end

--[=[
    @within Replicator
    @function find
    @param instance Instance
    @return Replicator?
    
    Find the replicator which is wrapping given instance, if not finded, will be returned nil.
]=]
function Replicator.find(instance: Instance): Replicator?
    
    return replicators[instance]
end
--[=[
    @within Replicator
    @function get
    @param instance Instance
    @return Replicator
    
    Find the replicator which is wrapping given instance, if not exists, will return the given
    instance wrapped by a new replicator.
]=]
function Replicator.get(instance: Instance): Replicator
    
    return Replicator.find(instance) or Replicator.wrap(instance)
end

--// End
export type Replicator = typeof(Replicator.wrap())
return Replicator