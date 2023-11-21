-- @XnLogicaL 29/10/2023 (MAJOR UPDATE 13/11/2023)
-- File: Inventory.lua
--[[

	Please report any issues to my discord:
	@ceo_oftaxfraud
	
	Or message me on Roblox:
	@CE0_OfTrolling
	
	CHANGELOG:
	- Added crafting support (use Inventory:Craft())
	- Added recipe support (use InventoryManager:SetCraftingRecipe())
	- Added Item and Recipe types
	- Fixed major logic issues
	- Added better debugging support
	- Removed some useless functions
	- Optimization changes
	
	HOW TO USE:
	<-- Module:GetInventory(Player) -->
		- Yields the inventory
		- If the player does not have an inventory, creates a new one.
		
	<-- Module:RemoveInventory(Player) -->
		- Removes the player's inventory.
		
	<-- Module:SetCraftingRecipe(CraftInfo) -->
		- Will throw an error if recipe already exists
		- CraftInfo is a table with the following properties:
			```lua
				{
					ID = "ID",
					Input = {
						Item = {...},
						...
					},
					Output = {
						Item = {...},
						...
					}
				}
				
				@example:
				
				local Recipe = {
					ID = "IronSword",
					Input = {
						iron,
						wood,
					},
					
					Output = {
						iron_sword
					}
				}
			
			module:SetCraftingRecipe(Recipe)
			```
			
	<-- Module:OverwriteCraftingRecipe(OldRecipe, NewRecipe) -->
		- Pretty much what it sounds like.
		
	<-- Inventory:AddItem(ItemID, Quantity) -->
		- Adds the specified item to the inventory (self)
		
	<-- Inventory:RemoveItem(ItemID, Quantity) -->
		- Removes the specified item
		- If no quantity is provided removes the item completely
	
	<-- Inventory:HasItem(ItemID) -->
		- Returns a boolean value
		- Returns true if the inventory has the item
		
	<-- Inventory:Clear() -->
		- Sets all the keys inside Inventory.Contents to nil, basically clears all the items.
		
	<-- Inventory:Release() -->
		- Saves and deletes the inventory.
		
	<-- Inventory:Clone() -->
		- Returns Inventory.Contents
		
	<-- Inventory:Craft(Recipe) -->
		- Crafts the item if all the conditions required to craft are met.
		
	NOTES:
	- I do not recommend using this module on the client.
	- I recommend ProfileService for inventory saving, it is perfectly made for this.
	
]]--
local Config = {
	ClientCheck = true
}
export type Item = {
	ItemID: string?,
	Quantity: number,
	Rarity: number,
}
export type Inventory = {
	Contents: {Item},
	Capacity: number,
	Saves: boolean,
	GetItemQuantity: (ItemID: string) -> number,
	AddItem: (ItemID: string, Quantity: number) -> (),
	RemoveItem: (ItemID: string, Quantity: number) -> (),
	ClearInventory: () -> (),
	Release: () -> (),
	Clone: () -> {any},
	ItemAdded: RBXScriptSignal,
	ItemRemoved: RBXScriptSignal,
	InventoryCleared: RBXScriptSignal,
	ItemAddRequestRejected: RBXScriptSignal
}
export type Recipe = {
	ID: string,
	Input: {Item},
	Output: {Item},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(script.Parent.signal)
local ManagerMS = require(script.Manager)

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
	if not Config.ClientCheck then return end
	if game:GetService("RunService"):IsClient() then
		game.Players.LocalPlayer:Kick("attempt to run server-only module on client")
	end
end

local function assert_string(condition, str)
	if condition == (false or nil) then
		return str
	end
end

local function save_inventory(plr)
	local target_inventory = ManagerMS.Inventories[plr]
	
	if target_inventory ~= nil then
		-- TODO:
		-- ADD SAVE FUNCTIONALITY
		-- USE PROFILESERVICE PLS
	else
		Error(`Could not save inventory of {plr.Name} (inventory does not exist)`)
	end
end

local InventoryManager = {Manager = ManagerMS, LocalRecipes = {}}
local Inventory = {}
InventoryManager.__index = InventoryManager
Inventory.__index = Inventory

function Inventory.new(Player: Player, Saves: boolean): Inventory
	client_check()
	local saves_default = false
	if Saves ~= nil then
		saves_default = Saves
	end
	local new_inventory: Inventory = {}
	new_inventory.Saves = saves_default
	new_inventory.Contents = {}
	new_inventory.Capacity = 15
	new_inventory.ItemAdded = Signal.new()
	new_inventory.ItemRemoving = Signal.new()
	new_inventory.InventoryCleared = Signal.new()
	new_inventory.ItemAddRequestRejected = Signal.new()
	
	function new_inventory:GetItemQuantity(ItemID): (string) -> number
		client_check()
		local target_item = self.Contents[ItemID]
		
		if target_item ~= nil then
			return self.Contents[ItemID]
		else
			return nil
		end
	end
	
	function new_inventory:AddItem(ItemID, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemID]
		if #self.Contents >= self.Capacity then self.ItemAddRequestRejected:Fire("inventory_full") return end
		if target_item ~= nil then
			self.Contents[ItemID] += quantity
		else
			self.Contents[ItemID] = quantity
		end
		self.ItemAdded:Fire(ItemID)
	end
	
	function new_inventory:RemoveItem(ItemID, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemID]
		assert(target_item, String(`[INVENTORYSERVICE] Could not process removal {ItemID} (entry is nil)`))
		
		if quantity ~= nil then
			if target_item == 0 then
				self.Contents[ItemID] = nil
				return
			end
			self.Contents[ItemID] -= quantity
		else
			self.Contents[ItemID] = nil
		end
		self.ItemRemoving:Fire(ItemID)
	end
	
	function new_inventory:HasItem(ItemID): () -> boolean
		if self.Contents[ItemID] ~= nil then
			return true
		end
		return false
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
	
	function new_inventory:Craft(Recipe: Recipe): (Recipe) -> ()
		client_check()
		assert_string(self.Contents[Recipe.Ingredient1.ItemID] == nil, "missing_ingredient1")
		assert_string(self.Contents[Recipe.Ingredient2.ItemID] == nil, "missing_ingredient2")
		assert_string(self.Contents[Recipe.Ingredient1.ItemID] < Recipe.Ingredient1.Quantity, "insufficient_quantity1")
		assert_string(self.Contents[Recipe.Ingredient2.ItemID] < Recipe.Ingredient2.Quantity, "insufficient_quantity2")
		
		for _, v in pairs(Recipe.Input) do
			self:RemoveItem(v.ItemID, v.Quantity)
		end
		for _, v in pairs(Recipe.Output) do
			self:AddItem(v.ItemID, v.Quantity)
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
	local type_recipe: Recipe = {}
	assert(type(CraftInfo) == type(type_recipe), String(`CraftInfo expected; got {type(CraftInfo)}`))
	assert(self.LocalRecipes[CraftInfo.ID] == nil, String(`Recipe name already exists; use :OverwriteRecipe()`))
	
	self.LocalRecipes[CraftInfo.ID] = CraftInfo
end

function InventoryManager:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	assert(self.LocalRecipes[Recipe] ~= nil, String("Attempt to overwrite nil recipe"))
	self.LocalRecipes[Recipe] = NewRecipe
end


return InventoryManager
