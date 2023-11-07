-- @XnLogicaL 31/10/2023
-- This is a math library consisting of some much need functions and fun/interesting functions (such as willans' formula and hexation)
local rng = Random.new()
local math_extra = {}

math_extra.e = 2.7182818

-- Private functions
local function check_if_number_is_floating_point(n)
	if n % 1 == 0 then
		return false
	else
		return true
	end
end

local function odd(n)
	if n == 0 then return false end
	if check_if_number_is_floating_point(n/2) then
		return true
	else
		return false
	end
end

local function square(n)
	return n^2
end

local function power_self(n)
	return n^n
end

local function sum(n, i)
	local r = 0
	for j=i, n do
		r += j
	end
	return r
end

local function factorial(n)
	local current_n = 1
	for i=1, n do
		current_n = current_n * i
	end 
	return current_n
end

local function willans_iterator(i)
	local r = 0
	for j=1, i do
		r += (math.floor(math.cos(math.pi*((factorial(j-1)+1)/j)))^2)
		task.wait(0.01)
	end
	return r
end

-- Module (public) functions
function math_extra.toboolean(arg)
	if arg == (1 or "true") then return true end
	if arg == (0 or "false") then return false end
	return nil
end

function math_extra.NumberType(n)
	if check_if_number_is_floating_point(n) then
		return "floating"
	elseif not check_if_number_is_floating_point(n) then
		return "integer"
	else
		return 
	end
end

function math_extra.IsPrime(n)
	if check_if_number_is_floating_point(n) then return end
	local to_div = {}
	for i=2, n do
		if check_if_number_is_floating_point(n/2) then continue end
		table.insert(to_div, i)
	end
	for _, v in pairs(to_div) do
		if check_if_number_is_floating_point(n/v) then 
			return false 
		else
			continue
		end
	end
	return true
end

function math_extra.Circumfrance(diameter): number
	return diameter * math.pi
end

function math_extra.RoundPrime(n): number
	for i=n, n+4096 do
		if not odd(n) then continue end
		if math_extra.IsPrime(i) then
			return i
		else
			continue
		end
	end
	return error("could not calculate next prime: prime(n) - prime(n+1) exceeds 4096")
end

function math_extra.Willans(n) -- VERY VERY VERY SLOW AFTER THE VALUE OF 6, DUE TO EXPONENTIATION
	local r = 0
	for i=1, 2^n do
		r += math.floor((n/willans_iterator(i))^(1/n))
		task.wait(0.01)
	end
	return 1+r
end

function math_extra.Factorial(n)
	return factorial(n)
end

function math_extra.Sum(n)
	return sum(n)
end

function math_extra.Limit(func, min_value, max_value, increment): nil
	assert(typeof(func) == "function", `function expected; got {type(func)}`)
	for i = min_value, max_value, increment do
		local index_func = func(i)
		assert(index_func, `limit of function: {func} hit, largest value: {i}`)
		print(func(i))
		task.wait(.005)
	end
end

function math_extra.BetterRandom(n)
	return string.sub(tostring(math.abs(((((n / n^2) * n) / factorial(n)) / n^3) * 100)), 1, string.len(tostring(n)))
end

function math_extra.Tetrate(n, pow)
	local current_n = n
	for i=1, pow do
		current_n = power_self(current_n)
	end
	return current_n
end

function math_extra.Pentate(n, pow)
	local current_n = n
	for i=1, pow do
		current_n = math_extra.Tetration(n, pow)
	end
	return current_n
end

function math_extra.Hexate(n, pow) -- This will prob crash your studio
	local current_n = n
	for i=1, pow do
		current_n = math_extra.Pentate(n, pow)
	end
	return current_n
end

return math_extra

