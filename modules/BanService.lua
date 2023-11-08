--@XnLogical 17/08/2023 (Final Update 08/11/2023, Discontinued)
export type BanInfo = {
	Banned: boolean,
	BannedOn: number,
	Duration: number,
	Administrator: number,
	Reason: string,
}
local BanTemplate: BanInfo = {
	Banned = false,
	BannedOn = nil,
	Duration = nil,
	Administrator = nil,
	Reason = nil,
}

local Players = game:GetService(`Players`)
local DatastoreService = game:GetService(`DataStoreService`)
local Database = DatastoreService:GetDataStore(`BanData`)

local BanService = {}

function BanService.Init(UserId: number)
	local player = Players:GetPlayerByUserId(UserId)
	assert(player, `[BANSERVICE] Could not get player by UserId`)
	
	if Database:GetAsync(UserId) == nil then Database:SetAsync(UserId, BanTemplate) return end
	local NewBanInfo: BanInfo = Database:GetAsync(UserId)
	
	if NewBanInfo.Banned ~= true then return end
	local Reason = NewBanInfo.Reason
	local TimeLeft = NewBanInfo.Duration - ((tick() / 86400) - (NewBanInfo.BannedOn / 86400))
	
	if Reason == (nil or "") then Reason = "[NOREASONSPECIFIED]" end
	if TimeLeft <= 0 then
		BanService:Pardon(UserId)
		player:Kick(`[BANSERVICE] Your ban has expired. Please rejoin to continue playing.`)
		return
	end
	if TimeLeft > 0 then
		player:Kick(`[BANSERVICE] You have been banned for {NewBanInfo.Reason}. Ban expires after: `..math.round(TimeLeft))
		return
	end
end 

function BanService.BanUser(UserId: number, Duration: number, AdministratorId: number, Reason: string)
	local Player = Players:GetPlayerByUserId(UserId)
	local Admin = Players:GetPlayerByUserId(AdministratorId)
	assert(Player, `[BANSERVICE] Could not get player by UserId`)
	assert(Admin, `[BANSERVICE] Could not get administrator by UserId`)
	
	local NewInfo: BanInfo = Database:GetAsync(Player.UserId)
	NewInfo.Banned = true
	NewInfo.BannedOn = tick()
	NewInfo.Duration = Duration
	NewInfo.Administrator = AdministratorId
	if Reason == (nil or "") then Reason = "[NOREASONSPECIFIED]" end
	NewInfo.Reason = Reason
	
	Database:SetAsync(Player.UserId, NewInfo)
	Player:Kick(`You have been banned for {Reason}. Ban expires after: `..Duration)
end

function BanService.Pardon(UserId: number)
	assert(Players:GetPlayerByUserId(UserId), `[BANSERVICE] Could not get player from UserId`)
	assert(Database:GetAsync(UserId) ~= nil, `[BANSERVICE] Could not access database entry; did you forget to initialize?`)
	assert(Database:GetAsync(UserId).Banned ~= false, `[BANSERVICE] Attempt to pardon unbanned player.`)
	
	Database:SetAsync(UserId, BanTemplate)
end

return BanService
