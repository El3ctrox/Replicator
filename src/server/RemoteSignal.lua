--.// Packages
local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Parent.Signal)
type Signal<data...> = Signal.Signal<data...>
type Connection = Signal.Connection

--[=[
	@server
	@class RemoteSignal
	
	A RemoteEvent wrapper using Signals.
]=]
local RemoteSignal = {}

--// Cache
local remoteSignals = setmetatable({}, { __mode = "k" })
--[=[
	@within RemoteSignal
	@function find
	@param remoteEvent RemoteEvent
	@return RemoteSignal?
	
	Find the RemoteSignal which is wrapping given RemoteEvent, if not finded, returns nil.
]=]
function RemoteSignal.find(remoteEvent: RemoteEvent): RemoteSignal?
	
	return remoteSignals[remoteEvent]
end
--[=[
	@within RemoteSignal
	@function get
	@param bindableEvent BindableEvent & { Replicator: RemoteEvent }
	@return RemoteSignal
	
	Find the remoteSignal which is wrapping given bindableEvent, if not exists, will return the given remoteEvent wrapped by a new RemoteSignal.
]=]
function RemoteSignal.get(bindableEvent: BindableEvent & { Replicator: RemoteEvent }): RemoteSignal
	
	return RemoteSignal.find(bindableEvent) or RemoteSignal.wrap(bindableEvent)
end

--[=[
	@within RemoteSignal
	@function new
	@param name string
	@return RemoteSignal
	
	Creates a new RemoteEvent with given name, then wraps with a new RemoteSignal.
]=]
function RemoteSignal.new(name: string): RemoteSignal
	
	local bindableEvent = Instance.new("BindableEvent")
	bindableEvent.name = name
	bindableEvent:AddTag("RemoteField")
	
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "Replicator"
	
	return RemoteSignal.wrap(bindableEvent)
end
--[=[
	@within RemoteSignal
	@function wrap
	@param remoteEvent RemoteEvent
	@return RemoteSignal
	
	Wraps the remoteEvent with a new RemoteSignal and Signal.
]=]
function RemoteSignal.wrap(bindableEvent: BindableEvent & { Replicator: RemoteEvent })
	
    local self = Signal.wrap(bindableEvent)
	local remoteEvent = bindableEvent.Replicator
	
	--[=[
		@within RemoteSignal
		@method _tryEmitOff
		@param blacklist {Player}	-- players which will not receive the signal
		@param ... any	-- data
		@return boolean	-- returns false if any error occurred while calling some listener, else returns true
		
		Call all listeners, if havent any error, fires the remote event for all players, except the
		players within blacklist, then returns true, if some error occurred while calling some listener,
		this will return false.
		Useful to send data for all players, excluding some players.
	]=]
	function self:_tryEmitOff(blacklist: {Player},...: any): boolean
		
		return pcall(self._tryEmitOff, self, blacklist,...)
	end
	--[=[
		@within RemoteSignal
		@method _emitOff
		@param blacklist {Player}	-- players which will not receive the signal
		@param ... any	-- data
		
		Call all listeners and fires the remote event for all players, except the players within blacklist.
		Useful to send data for all players, excluding some players.
	]=]
	function self:_emitOff(blacklist: {Player},...: any)
		
		self:_emit(...)
		
		for _,player in Players:GetPlayers() do
			
			if table.find(blacklist, player) then continue end
			remoteEvent:FireClient(player,...)
		end
	end
	
	--[=[
		@within RemoteSignal
		@method _tryEmitOn
		@param whitelist {Player}	-- players which will receive the signal
		@param ... any	-- data
		@return boolean	-- returns false if any error occurred while calling some listener, else returns true
		
		Call all listeners, if havent any error, fires the remote event only for whitelist players and
		then return true, if some error occurred while calling some listener, this will return false.
		Useful for send data for specific players
	]=]
	function self:_tryEmitOn(whitelist: {Player},...: any): boolean
		
		return pcall(self._emitOn, self, whitelist,...)
	end
	--[=[
		@within RemoteSignal
		@method _emitOn
		@param whitelist {Player}	-- players which will receive the signal
		@param ... any	-- data
		
		Call all listeners and fires the remote event only for whitelist players and then return true.
		Useful for send data for specific players
	]=]
	function self:_emitOn(whitelist: {Player},...: any)
		
		self:_emit(...)
		
		for _,player in whitelist do
			
			remoteEvent:FireClient(player,...)
		end
	end
	
	--[=[
		@within RemoteSignal
		@method _tryEmitAll
		@param ... any	-- data
		@return boolean	-- returns false if any error occurred while calling some listener, else returns true
		
		Call all listeners, if havent any error, fires the remote event for all players and
		then return true, if some error occurred while calling some listener, this will return false.
		Useful for send data for all players
	]=]
	function self:_tryEmitAll(...: any): boolean
		
		return pcall(self._emitAll, self,...)
	end
	--[=[
		@within RemoteSignal
		@method _emitAll
		@param ... any	-- data
		
		Call all listeners and fires the remote event for all players.
		Useful for send data for specific players
	]=]
	function self:_emitAll(...: any)
		
		self:_emit(...)
		remoteEvent:FireAllClients(...)
	end
	
	--// End
	remoteSignals[bindableEvent] = self
	return self
end
export type RemoteSignal<data... = ...any> = Signal<data...> & {
	_tryEmitOff: (any, blacklist: {Player}, data...) -> boolean,
	_emitOff: (any, blacklist: {Player}, data...) -> (),
	_tryEmitOn: (any, whitelist: {Player}, data...) -> boolean,
	_emitOn: (any, whitelist: {Player}, data...) -> (),
}

--// End
return RemoteSignal