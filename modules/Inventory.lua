-- @XnLogicaL 29/10/2023 (MAJOR UPDATE 13/11/2023)
--[[
	
	CHANGELOG:
	- Added crafting support (use Inventory:Craft())
	- Added recipe support (use InventoryManager:SetCraftingRecipe())
	- Added Item and Recipe types
	- Fixed major logic issues
	- Added better debugging support
	- Removed some useless functions
	- Optimization changes
	
	NOTES:
	- Recipes are LOCAL, they are not saved or replicated
	- 1 recipe can only have 1 output
	- Recipes are stored in InventoryManager
	
]]--
export type Item = {
	ItemName: any, 
	Quantity: number
}
export type Inventory = {
	Contents: {Item},
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
export type Recipe = {
	RecipeName: string,
	Ingredient1: Item,
	Ingredient2: Item,
	Ingredient3: Item,
	CraftedItem: Item,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(script.Parent.signal)
local Util = require(script.Parent.UtilityPlus)
local ManagerMS = require(script.Manager)

main_notation = {
	_save_location = require(ReplicatedStorage.ProfileManager).Profiles;
	_default_inventory_capacity = 15;
	_default_inventory_contents = {};
}

local function Error(...: string?)
	return error("[INVENTORYSERVICE] ".. ...)
end

local function Warn(...: string?)
	warn("[INVENTORYSERVICE] ".. ...)
end

local function String(...: string?)
	return "[INVENTORYSERVICE] ".. ...
end

local function client_check()
	if game:GetService("RunService"):IsClient() then
		Error("attempt to run on client")
	end
end

local function assert_string(condition, str)
	if condition == (false or nil) then
		return str
	end
end

local function overwrite_inventory(inv: Inventory, plr: Player)
	main_notation._save_location[plr].Data.Inventory = inv
end

local function save_inventory(plr)
	local target_inventory = ManagerMS.Inventories[plr]
	
	if target_inventory ~= nil then
		overwrite_inventory(target_inventory, plr)
	else
		Error(`Could not save inventory of {plr.Name} (inventory does not exist)`)
	end
end

local InventoryManager = {Manager = ManagerMS.Inventories, LocalRecipes = {}}
local Inventory = {}
InventoryManager.__index = InventoryManager
Inventory.__index = Inventory

function Inventory.new(Player: Player, Saves: boolean): Inventory
	client_check()
	local saves_default = false
	if Saves ~= nil then
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
		client_check()
		local target_item = self.Contents[ItemName]
		
		if target_item ~= nil then
			return self.Contents[ItemName]
		else
			return nil
		end
	end
	
	function new_inventory:AddItem(ItemName, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemName]
		if #self.Contents >= self.Capacity then self.ItemAddRequestRejected:Fire("inventory_full") return end
		if target_item ~= nil then
			self.Contents[ItemName] += quantity
		else
			self.Contents[ItemName] = quantity
		end
		self.ItemAdded:Fire(ItemName)
	end
	
	function new_inventory:RemoveItem(ItemName, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemName]
		assert(target_item, String(`[INVENTORYSERVICE] Could not process removal {ItemName} (entry is nil)`))
		
		if quantity ~= nil then
			if target_item == 0 then
				self.Contents[ItemName] = nil
				return
			end
			self.Contents[ItemName] -= quantity
		else
			self.Contents[ItemName] = nil
		end
		self.ItemRemoving:Fire(ItemName)
	end
	
	function new_inventory:ClearInventory(): () -> ()
		client_check()
		table.clear(self.Contents)
		self.InventoryCleared:Fire()
	end
	
	function new_inventory:Release(): () -> ()
		client_check()
		if self.Saves then
			save_inventory(Player)
			task.wait()
		end
		table.clear(self)
	end
	
	function new_inventory:Clone(): () -> {any}
		client_check()
		return self.Contents
	end
	
	function new_inventory:Craft(Recipe: Recipe)
		client_check()
		assert_string(self.Contents[Recipe.Ingredient1.ItemName] == nil, "missing_ingredient1")
		assert_string(self.Contents[Recipe.Ingredient2.ItemName] == nil, "missing_ingredient2")
		assert_string(self.Contents[Recipe.Ingredient1.ItemName] < Recipe.Ingredient1.Quantity, "insufficient_quantity1")
		assert_string(self.Contents[Recipe.Ingredient2.ItemName] < Recipe.Ingredient2.Quantity, "insufficient_quantity2")
		
		local result, err = pcall(function()
			self:RemoveItem(Recipe.Ingredient1.ItemName, Recipe.Ingredient1.Quantity)
			self:RemoveItem(Recipe.Ingredient2.ItemName, Recipe.Ingredient2.Quantity)
			self:AddItem(Recipe.CraftedItem.ItemName, Recipe.CraftedItem.Quantity)
		end)
		
		if result then
			return tostring(result)
		else
			return tostring(err)
		end
	end
	
	table.insert(InventoryManager.Manager, new_inventory)
	
	return new_inventory
end

function InventoryManager:GetInventory(Player: Player): (Player) -> Inventory
	client_check()
	local target_inventory = self.Manager[Player]
	if target_inventory ~= nil then 
		return target_inventory
	else
		target_inventory = Inventory.new(Player)
	end
	
	return target_inventory
end

function InventoryManager:RemoveInventory(Player: Player): (Player) -> ()
	client_check()
	local target_inventory = self.Manager[Player]
	if target_inventory ~= nil then
		target_inventory:Release()
		self.Manager[Player] = nil
	else
		Error(`Attempt to remove inventory before initializing ({Player.Name})`)
	end
end

function InventoryManager:SetCraftingRecipe(CraftInfo: Recipe): Recipe
	client_check()
	local new_recipe: Recipe = {}
	assert(type(CraftInfo) == type(new_recipe), String(`CraftInfo expected; got {type(CraftInfo)}`))
	assert(self.LocalRecipes[CraftInfo.RecipeName] == nil, String(`Recipe name already exists; use :OverwriteRecipe()`))
	
	new_recipe.RecipeName = CraftInfo.RecipeName
	new_recipe.Ingredient1 = CraftInfo.Ingredient1
	new_recipe.CraftedItem = CraftInfo.CraftedItem
	if CraftInfo.Ingredient2 ~= nil then
		new_recipe.Ingredient2 = CraftInfo.Ingredient2
	end
	if CraftInfo.Ingredient3 ~= nil then
		new_recipe.Ingredient3 = CraftInfo.Ingredient3
	end
	
	self.LocalRecipes[CraftInfo.RecipeName] = new_recipe
	
	return new_recipe
end

function InventoryManager:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	assert(self.LocalRecipes[Recipe] ~= nil, String("Attempt to overwrite nil recipe"))
	self.LocalRecipes[Recipe] = NewRecipe
end

return InventoryManager
