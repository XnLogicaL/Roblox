--@XnLogicaL 11/07/2023 (W.I.P)
--Useful module for creating basic matrices (2 dimensional arrays)
export type matrix = {
	Table1: {any},
	Table2: {any},
	Table3: {any},
}

local module = {}

function module.new(column): matrix
	local new_matrix = {}
	for i=1, column do
		table.insert(new_matrix, {})
	end
	return new_matrix
end

function module.insert(matrix, column, row, value)
	if not (type(matrix[column][row]) == "table") then return nil end
	table.insert(matrix[column][row])
end

return module

