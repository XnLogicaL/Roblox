-- @XnLogicaL 29/10/2023 (MAJOR UPDATE 13/11/2023)
-- File: Inventory.lua
--[[

	Please report any issues to my discord:
	@ceo_oftaxfraud
	
	Or message me on Roblox:
	@CE0_OfTrolling
	
	Feel free to change, edit, distribute this module as long as you credit me.
	
	HOW TO USE:
	<-- Module:GetInventory(Player) -->
		- Returns the player's inventory
		- If the player does not have an inventory, returns a blank one.
		
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
						iron = {
							ItemID = "iron",
							Quantity = 2
						},
						wood = {
							ItemID = "wood",
							Quantity = 1
						},
					},
					
					Output = {
						iron_sword = {
							ItemID = "iron_sword",
							Quantity = 1
						}
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
		
	<-- Inventory:GetQuantity(ItemID) -->
		- Returns the quantity of the item
		- Returns 0 if the item is nil/null
	
	<-- Inventory:HasItem(ItemID) -->
		- Returns a boolean value
		- Returns true if the inventory has the item
		
	<-- Inventory:Clear() -->
		- Sets all the keys inside Inventory.Contents to nil, basically clears all the items.
		
	<-- Inventory:Release() -->
		- Saves and deletes the inventory.
		- Only use when you are done with it.
		
	<-- Inventory:Clone() -->
		- Esentially returns Inventory.Contents
		
	<-- Inventory:Craft(Recipe) -->
		- Crafts the item if all the conditions required to craft are met.
		
	NOTES:
	- I heavily discourage using this module on the client.
	- I recommend ProfileService for inventory saving, it is perfectly made for this.
	
]]--
local Config = {
	ClientCheck = true -- Heavily recommended
}
export type Item = {
	ItemID: string?,
	Quantity: number,
	Rarity: number,
}
export type Inventory = {
	Contents: {Item},
	Capacity: number,
	_saves: boolean,
	GetItemQuantity: (ItemID: string) -> number,
	AddItem: (ItemID: string, Quantity: number) -> (),
	RemoveItem: (ItemID: string, Quantity: number) -> (),
	ClearInventory: () -> (),
	Release: () -> (),
	Clone: () -> {any},
	ItemAdded: RBXScriptSignal,
	ItemRemoved: RBXScriptSignal,
	InventoryCleared: RBXScriptSignal,
	_add_fail: RBXScriptSignal,
	_remove_fail: RBXScriptSignal,
	_craft_fail: RBXScriptSignal
}
export type Recipe = {
	ID: string,
	Input: {Item},
	Output: {Item},
}
export type Module = {
	GetInventory: (Player) -> Inventory,
	RemoveInventory: (Player) -> (),
	SetCraftingRecipe: (CraftInfo: Recipe) -> (),
	OverwriteCraftingRecipe: (oldRecipe: Recipe, newRecipe: Recipe) -> ()
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Signal = require(script.Signal)
local ManagerMS = require(script.Manager)

local function String(...: string)
	return "[INVENTORYSERVICE] ▶ ".. ...
end

local function client_check()
	if not Config.ClientCheck then return end
	if game:GetService("RunService"):IsClient() then
		Players.LocalPlayer:Kick("attempt to run server-only module on client")
	end
end

local function assert_string(condition: boolean, str: string): string | nil
	if condition == (false or nil) then
		return str
	end
	return nil
end

local Module = {_manager = ManagerMS, _local = {}}
Module.__index = Module
Module.SaveFunction = function(Player: Player, InventoryToSave: Inventory)
	-- TODO: ADD SAVE FUNCTIONALITY WITH YOUR PREFERED DATASTORE SERVICE.
end

function newInventory(Player: Player, Saves: boolean): Inventory
	client_check()
	local new_inventory: Inventory = {}
	new_inventory._saves = Saves or true -- Default: true
	new_inventory.Contents = {} -- Default: {}
	new_inventory.Capacity = 15 -- Default: 15
	new_inventory.ItemAdded = Signal.new()
	new_inventory.ItemRemoving = Signal.new()
	new_inventory.InventoryCleared = Signal.new()
	---- DEBUGGING ----
	new_inventory._add_fail = Signal.new()
	new_inventory._remove_fail = Signal.new()
	new_inventory._craft_fail = Signal.new()

	function new_inventory:GetQuantity(ItemID: string): (string) -> number
		client_check()
		local target_item: number = self.Contents[ItemID]

		if target_item ~= nil then
			return target_item
		else
			return 0
		end
	end

	function new_inventory:AddItem(ItemID, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemID]
		if #self.Contents >= self.Capacity then self._add_fail:Fire("inventory_full") return end
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
		assert(target_item, String(`Could not process removal {ItemID} (entry is nil)`))

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
		if self._saves then
			Module.SaveFunction(Player, new_inventory)
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
		for _, v in pairs(Recipe.Input) do
			if self.Contents[v.ItemID] < v.Quantity then
				self._craft_fail:Fire("insufficient_quantity")
				return
			end
		end

		for _, v in pairs(Recipe.Input) do
			self:RemoveItem(v.ItemID, v.Quantity)
		end
		for _, v in pairs(Recipe.Output) do
			self:AddItem(v.ItemID, v.Quantity)
		end
	end

	table.insert(Module._manager, new_inventory)

	return new_inventory :: Inventory
end

function Module:GetInventory(Player: Player): (Player) -> Inventory
	client_check()
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then 
		return target_inventory
	else
		self._manager[Player] = newInventory(Player)
	end

	return target_inventory
end

function Module:RemoveInventory(Player: Player): (Player) -> ()
	client_check()
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then
		target_inventory:Release()
		self._manager[Player] = nil
	else
		error(`[INVENTORYSERVICE] ▶ Attempt to remove inventory before initializing ({Player.Name})`)
	end
end

function Module:SetCraftingRecipe(CraftInfo: Recipe): Recipe
	client_check()
	local RecipeType: Recipe = {}
	assert(typeof(CraftInfo) == typeof(RecipeType), String(`CraftInfo expected; got {typeof(CraftInfo)}`))
	assert(self._local[CraftInfo.ID] == nil, String(`Recipe ID already exists; use :OverwriteRecipe()`))

	self._local[CraftInfo.ID] = CraftInfo
end

function Module:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	client_check()
	assert(typeof(NewRecipe) == typeof(Recipe), String(`CraftInfo expected; got {typeof(NewRecipe)}`))
	assert(self._local[Recipe] ~= nil, String("Could not overwrite; recipe is nil"))
	self._local[Recipe] = NewRecipe
end


return Module :: Module --and newInventory :: (Player, boolean) -> Inventory
