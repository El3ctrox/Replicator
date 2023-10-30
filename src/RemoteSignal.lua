--.// Packages
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local wrapper = require(ReplicatedStorage.Packages.Wrapper)
local Signal = require(ReplicatedStorage.Packages.Signal)
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
	@param remoteEvent RemoteEvent
	@return RemoteSignal
	
	Find the remoteSignal which is wrapping given remoteEvent, if not exists, will return the given remoteEvent wrapped by a new RemoteSignal.
]=]
function RemoteSignal.get(remoteEvent: RemoteEvent): RemoteSignal
	
	return RemoteSignal.find(remoteEvent) or RemoteSignal.wrap(remoteEvent)
end

--[=[
	@within RemoteSignal
	@function new
	@param name string
	@return RemoteSignal
	
	Creates a new RemoteEvent with given name, then wraps with a new RemoteSignal.
]=]
function RemoteSignal.new(name: string): RemoteSignal
	
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	
	return RemoteSignal.wrap(remoteEvent)
end
--[=[
	@within RemoteSignal
	@function wrap
	@param remoteEvent RemoteEvent
	@return RemoteSignal
	
	Wraps the remoteEvent with a new RemoteSignal and Signal.
]=]
function RemoteSignal.wrap(remoteEvent: RemoteEvent)
	
    local self = wrapper(remoteEvent, "RemoteSignal", "RemoteField")
    local signal = self:_host(Signal.new("LocalEvent"))
	
	--[=[
		@within Signal
		@method connect
		@param callback function	-- function called when signal fired
		@return Connection		-- object to handle the callback, like disconnect the callback or reconnect
		
		Create a listener/observer for signal.
		Useful to bind and unbind functions to some emitter, which can be fired when something happens during game.
	]=]
	function self:connect(callback: (...any) -> ())
		
		return signal:connect(callback)
	end
	--[=[
		@within RemoteSignal
		@method once
		@param callback function	-- function called when signal fired
		@return Connection		-- object to handle the callback, like disconnect the callback or reconnect
		
		Create a listener/observer for signal.
		Like Signal:connect, but the connection is :disconnect()'ed after triggered, but can be :reconnect()'ed multiple times.
	]=]
	function self:once(callback: (...any) -> ())
		
		return signal:once(callback)
	end
	
	--[=[
		@within RemoteSignal
		@method awaitWithinTimeout
		
		Wait until the signal was fired within a given timeout, and returns your data if signal was fired before timeout.
		Useful to wait some event without blocking infinitely the coroutine. Such wait some client response.
	]=]
	function self:awaitWithinTimeout(timeout: number): any...
		
		return signal:awaitWithinTimeout(timeout)
	end
	--[=[
		@within RemoteSignal
		@method await
		
		Wait until the signal was fired and returns your data.
	]=]
	function self:await(): any...
		
		return signal:await()
	end
	
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
		
		signal:_emit(...)
		
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
		
		signal:_emit(...)
		
		for _,player in whitelist do
			
			remoteEvent:FireClient(player,...)
		end
	end
	
	--[=[
		@within RemoteSignal
		@method _tryEmit
		@param ... any	-- data
		@return boolean	-- returns false if any error occurred while calling some listener, else returns true
		
		Call all listeners, if havent any error, fires the remote event for all clients and then return true,
		if some error occurred while calling some listener, this will return false.
		Useful for signals which can be cancelled for some listener.
	]=]
	function self:_tryEmit(...: any): boolean
		
		return pcall(self._emit, self,...)
	end
	--[=[
		@within RemoteSignal
		@method _emit
		@param ... any	-- data
		
		Fire all listeners then fire the remote event for all clients.
	]=]
	function self:_emit(...: any)
		
		signal:_emit(...)
		remoteEvent:FireAllClients(...)
	end
	
	--// End
	remoteSignals[remoteEvent] = self
	return self
end
export type RemoteSignal<data...> = Signal<data...> & {
	_tryEmitOff: (any, blacklist: {Player}, data...) -> boolean,
	_emitOff: (any, blacklist: {Player}, data...) -> (),
	_tryEmitOn: (any, whitelist: {Player}, data...) -> boolean,
	_emitOn: (any, whitelist: {Player}, data...) -> (),
}

--// End
return RemoteSignal