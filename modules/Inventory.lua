-- @XnLogicaL 26/10/2023 (UPDATED 11/07/2023)
export type Inventory = {
	Contents: {any},
	Capacity: number,
	Saves: boolean,
	GetItemQuantity: (self: string) -> number,
	AddItem: (self: string, self: number) -> (),
	RemoveItem: (self: string, self: number) -> (),
	ClearInventory: () -> (),
	Release: () -> (),
	Clone: () -> {any},
	ItemAdded: RBXScriptSignal,
	ItemRemoved: RBXScriptSignal,
	InventoryCleared: RBXScriptSignal,
	ItemAddRequestRejected: RBXScriptSignal
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(script.Parent.signal)
local Util = require(script.Parent.UtilityPlus)
local ManagerMS = require(script.Manager)

main_notation = {
	_get_save_location = function(player: Player) return require(ReplicatedStorage.ProfileManager).Profiles[player].Data end;
	_save_location_array_name = "Inventory";
	_default_inventory_capacity = 15;
	_default_inventory_contents = {};
}

local function Error(...: string?)
	return error("[INVENTORYSERVICE] ".. ...)
end

local function Warn(...: string?)
	warn("[INVENTORYSERVICE] ".. ...)
end

local function set_nil(v: any)
	v = nil
	return nil
end

local function is_nil(v: any)
	if v == (nil or 0) then
		return true
	else
		return false
	end
end

local function q_is_nil(v: any)
	if v ~= (nil or 0) then
		return true
	else
		return false
	end
end

local function save_inventory(plr)
	local target_inventory = ManagerMS.Inventories[plr]
	
	if q_is_nil(target_inventory) then
		main_notation._get_save_location(plr)[main_notation._save_location_array_name] = target_inventory
	else
		Error("Could not save inventory "..plr.Name.." (inventory does not exist)")
	end
end

local InventoryManager = {Manager = ManagerMS.Inventories}
local Inventory = {}
InventoryManager.__index = InventoryManager
Inventory.__index = Inventory

function Inventory.new(Player: Player, Saves: boolean): Inventory
	local saves_default = false
	if q_is_nil(Saves) then
		saves_default = Saves
	end
	local new_inventory = {}
	new_inventory.Saves = saves_default
	new_inventory.Contents = main_notation._default_inventory_contents
	new_inventory.Capacity = main_notation._default_inventory_capacity
	new_inventory.ItemAdded = Signal.new()
	new_inventory.ItemRemoving = Signal.new()
	new_inventory.InventoryCleared = Signal.new()
	new_inventory.ItemAddRequestRejected = Signal.new()
	
	function new_inventory:GetItemQuantity(ItemName): (string) -> number
		local target_item = self.Contents[ItemName]
		
		if q_is_nil(target_item) then
			return target_item
		else
			return nil
		end
	end
	
	function new_inventory:AddItem(ItemName, quantity): (string, number) -> () 
		local target_item = self.Contents[ItemName]
		if #self.Contents >= self.Capacity then self.ItemAddRequestRejected:Fire("inventory_full") return end
		if target_item then
			target_item += quantity
		else
			target_item = quantity
		end
		self.ItemAdded:Fire(ItemName)
	end
	
	function new_inventory:RemoveItem(ItemName, quantity): (string, number) -> () 
		local target_item = self.Contents[ItemName]
		assert(target_item, "Could not process removal "..ItemName.." (entry is nil)")
		
		if q_is_nil(quantity) then
			if target_item == 0 then
				set_nil(target_item)
				return
			end
			target_item -= quantity
		else
			set_nil(target_item)
		end
		self.ItemRemoving:Fire(ItemName)
	end
	
	function new_inventory:ClearInventory(): () -> ()
		table.clear(self.Contents)
		self.InventoryCleared:Fire()
	end
	
	function new_inventory:Release(): () -> ()
		if self.Saves then
			save_inventory(Player)
			task.wait()
		end
		table.clear(self)
	end
	
	function new_inventory:Clone(): () -> {any}
		return self.Contents
	end
	
	table.insert(InventoryManager.Manager, new_inventory)
	
	return new_inventory
end

function InventoryManager:GetInventory(Player: Player): (Player) -> Inventory
	local target_inventory = self.Manager[Player]
	if q_is_nil(target_inventory) then 
		return target_inventory
	else
		target_inventory = Inventory.new(Player)
	end
	
	return target_inventory
end

function InventoryManager:RemoveInventory(Player: Player): (Player) -> ()
	local target_inventory = self.Manager[Player]
	if q_is_nil(target_inventory) then
		target_inventory:Release()
		set_nil(target_inventory)
	else
		Error("Attempt to remove inventory before initializing ("..Player.Name..")")
	end
end

return InventoryManager
