
--@XnLogicaL 7/11/2023 (W.I.P)
--Process is a simple module for organizing your well.. processes
export type Process = {
	__call: (self) -> thread,
	__cancel: (self) -> (),
	__queue: (self) -> (),
	_main_process: thread,
	_called: RBXScriptSignal,
	_queued: RBXScriptSignal,
	_canceled: RBXScriptSignal,
	_is_running: boolean,
	_is_queued: boolean,
}

local Signal = require(script.Parent.signal)
local Process = {}

Process._active = {}
Process._queued = {}
Process._canceled = {}

Process._active.__index = Process._active
Process._queued.__index = Process._queued
Process._canceled.__index = Process._canceled

function Process:Create(index: string, handler: functionType): Process
	assert(type(handler) == "function", "handler must be a function")
	assert(type(index) == "string", "index must be a string or a number")
	assert(type(index) == "number", "index must be a string or a number")
	assert(self._queued[index] == nil, "could not index process; index already exists")
	
	local newProcess = {}
	
	newProcess._main_process = coroutine.create(handler)
	newProcess._called = Signal.new()
	newProcess._queued = Signal.new()
	newProcess._canceled = Signal.new()
	
	function newProcess:__call()
		if Process._queued[index] then return end
		self._called:Fire()
		return coroutine.resume(self._main_process)
	end
	
	function newProcess:__cancel()
		table.insert(Process._canceled, index)
		self._canceled:Fire()
		coroutine.close(self._main_process)
		table.clear(self)
	end
	
	function newProcess:__queue()
		if Process._queued[index] then return end
		self._queued:Fire()
		table.insert(Process._queued, self)
		coroutine.close(self._main_process)
	end
		
	return newProcess
end

function Process:ClearActive()
	for _, v: Process in pairs(self._active) do
		v:__cancel()
	end
end

function Process._active:Echo()
	print(`there are currently {#Process._active} process(s) active`)
end

function Process._queued:Echo()
	print(`there are currently {#Process._queued} process(s) queued`)
end

return Process
