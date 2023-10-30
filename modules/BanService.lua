-- @XnLogical 17/09/2023
local Players = game:GetService("Players")
local DatastoreService = game:GetService("DataStoreService")
local Database = DatastoreService:GetDataStore("BanData")

local BanService = {}

local Signal = require(script.Parent.signal)
BanService.PlayerBanned = Signal.new()
BanService.PlayerPardoned = Signal.new()

function BanService:Init(UserId: number)
	local player = Players:GetPlayerByUserId(UserId)
	local Info = {	
		["Banned"] = false,
		["BannedOn"] = nil,
		["Duration"] = nil,
		["Administrator"] = nil
	}
	assert(player, "Could not get player by UserId")
	
	if not Database:GetAsync(UserId) then
		Database:SetAsync(UserId, Info)
	else
		local BanInfo = Database:GetAsync(UserId)
		local CurrentTime = tick()
		local Banned = BanInfo["Banned"]
		if Banned then
			local TimeLeft = BanInfo["Duration"] - ((CurrentTime / 86400) - (BanInfo["BannedOn"] / 86400))
			if TimeLeft <= 0 then
				BanService:Pardon(UserId)
				player:Kick("Your ban has expired. Please rejoin to continue playing.")
			else
				player:Kick("You have been banned by a moderator. Days until unban: "..math.round(TimeLeft))
			end
		end
	end
end 

function BanService:BanUser(UserId: number, Duration: number, Administrator: number)
	local Player = Players:GetPlayerByUserId(UserId)
	local Info = Database:GetAsync(Player.UserId)
	Info["Banned"] = true
	Info["BannedOn"] = tick()
	Info["Duration"] = Duration
	Info["Administrator"] = Administrator.UserId
	
	assert(Player, "Could not get player by UserId")
	Database.SetAsync(Player.UserId, Info)
	Player:Kick("You have been banned by a moderator. Days until unban: "..Duration)
	
	self.PlayerBanned:Fire(Player)
end

function BanService:Pardon(PlayerId: number)
	local Info = {	
		["Banned"] = false,
		["BannedOn"] = nil,
		["Duration"] = nil,
		["Administrator"] = nil
	}
	if Database:GetAsync(PlayerId) then
		if Database.GetAsync(PlayerId).Banned == true then
			Database:SetAsync(PlayerId, Info)
			self.PlayerPardoned:Fire(game.Players:GetPlayerByUserId(PlayerId))
		else
			return error("[Ban Service] Attempt to pardon unbanned player.")
		end
	else
		return error("[Ban Service] Attempt to ban player: nil, did you forget to initialize?")
	end
end

return BanService
