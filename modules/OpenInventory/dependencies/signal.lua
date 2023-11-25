--!strict
-- Author: Unknown

local Signal = {}

export type Signal = {
	new: () -> signalType,
	Connect: (handler: (any) -> (any)) -> connectionType,
	Disconnect: () -> (),
	Wait: () -> any,
	Fire: (...any) -> (),
	Destroy: () -> ()
}
export type connectionType = {
	_signal: signalType,
	_handler: any,
	_connectionIndex: number,
	Disconnect: any
}
export type signalType = {
	_connections: {[number]: connectionType},
	Fire: any,
	Connect: any,
	Wait: any,
	Destroy: any
}

function Signal.new(): signalType
	local newSignal: signalType = {
		_connections = {},
		Fire = Signal.Fire,
		Connect = Signal.Connect,
		Wait = Signal.Wait,
		Destroy = Signal.Destroy
	}
	
	return newSignal
end

function Signal:Connect(handler: (any) -> (any)): connectionType
	local self: signalType = self
	
	local numConnections: number = #self._connections
	
	local newConnection: connectionType = {
		_signal = self,
		_handler = handler,
		_connectionIndex = (numConnections + 1),
		Disconnect = Signal.Disconnect
	}
	
	table.insert(self._connections, (numConnections + 1), newConnection)
	
	return newConnection
end

function Signal:Disconnect(): nil
	local self: connectionType = self
	
	local currentSignal: signalType = self._signal
	
	currentSignal._connections[self._connectionIndex] = nil
	
	table.clear(self)
	self = nil :: any
	
	return nil
end

function Signal:Wait(): any
	local self: signalType = self
	
	local thread: thread = coroutine.running()
	
	local c: connectionType; c = self:Connect(function(...)
		c:Disconnect()
		coroutine.resume(thread, ...)
	end)
	
	return coroutine.yield()
end

function Signal:Fire(...: any): nil
	local self: signalType = self
	
	for index: number, connection: connectionType in pairs(self._connections) do
		connection._handler(...)
	end
	
	return nil
end

function Signal:Destroy(): nil
	local self: signalType = self
	
	for index: number, connection: connectionType in pairs(self._connections) do
		connection:Disconnect()
	end
	
	table.clear(self)
	self = nil :: any
	
	return nil
end

function Signal:wait()
	return self:Wait()
end

function Signal:connect(...)
	return self:Connect(...)
end

function Signal:disconnect()
	return self:Disconnect()
end

function Signal:fire(...)
	return self:Fire(...)
end

function Signal:destroy()
	return self:Destroy()
end

return Signal :: Signal
