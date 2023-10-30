-- @XnLogicaL 24/10/2023
-- Usage: local Services = require(...)()
-- eg. local ReplicatedStorage = Services.ReplicatedStorage

return function()
	local Services = {}
	for _, v in pairs(game:GetChildren()) do
		table.insert(Services, game:GetService(v.Name))
	end
	return Services
end
