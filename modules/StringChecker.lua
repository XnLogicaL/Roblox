--[[
	
	Author: @XnLogicaL (@CE0_OfTrolling)
	
	Returns the security level 1-5 of a string, useful for keys, passwords, idk
	1 = Low
	5 = High
	
	Call module(String) to use ;)
	
]]

local minLen = 8
local minDistChar = 5

-- Do not edit past this line
local function _numCheck(str: string)
	for i=1, string.len(str) do
		if type(tonumber(string.sub(str, i, i+1))) == "number" then
			return true
		end
	end 
	return false
end

local function _capCheck(str: string) -- doesn't actually cap check :(
	return str:lower() ~= str
end

local function _lenCheck(str: string)
	return string.len(str) > minLen
end

local function _distCheck(str: string)
	local distinctCharacters = {}
	for i=1, string.len(str) do
		if table.find(distinctCharacters, string.sub(str, i, i+1), 1) then
			continue
		end
		table.insert(distinctCharacters, string.sub(str, i, i+1))
	end
	return #distinctCharacters > minDistChar
end

return function(str: string)
	local rating = 1
	if _lenCheck(str) then rating += 1 end
	if _numCheck(str) then rating += 1 end
	if _capCheck(str) then rating += 1 end
	if _distCheck(str) then rating += 1 end
	return rating
end
