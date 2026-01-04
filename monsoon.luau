if getgenv().AoInjected == true then
	return
end
getgenv().AoInjected = true

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Version = "v1.0.0 [FREE]"

-- Create Notification --
--local Notifier = Library.newNotify()

-- Loading UI (Icon <string> , Duration <number>) --
--Library:Loader("rbxassetid://463021019", 2).yield()

-- Creating Window --
local Window = Library:CreateWindow({
	Title = "Monsoon [F]",
	Footer = "version: 1.0.0",
	Icon = 6956634044,
	NotifySide = "Right",
})

-- Watermark --

-- Sets the watermark visibility
--Library:SetWatermarkVisibility(true)
local Watermark = Library:AddDraggableLabel(
	("Monsoon | %s | %s | %s"):format(
		Version,
		game.Players.LocalPlayer.Name,
		DateTime.now():FormatLocalTime("LT", "en-us")
	)
)
local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
	Watermark:SetText(
		("Monsoon | %s | %s | %s"):format(
			Version,
			game.Players.LocalPlayer.Name,
			DateTime.now():FormatLocalTime("LT", "en-us")
		)
	)
end)

-- Services
local Workspace = cloneref(game:GetService("Workspace"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local StarterGui = cloneref(game:GetService("StarterGui"))

-- Core Objects
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local CurrentCamera = Workspace.CurrentCamera
local Map = Workspace:WaitForChild("Map", 10)
local DarkSeaFolder = Map.SeaContent:WaitForChild("DarkSea", 10)
local NPCs = Workspace:WaitForChild("NPCs")
local BoatsFolder = Workspace:WaitForChild("Boats")
local RS = ReplicatedStorage:WaitForChild("RS", 10)
local Remotes = RS:WaitForChild("Remotes")
local TeleportBind = Instance.new("BindableFunction")
local enemiesFolder = Workspace:WaitForChild("Enemies")

-- Modules
local MagicModule = require(RS.Modules.Magic)
local MeleeModule = require(RS.Modules.Melee)
local BasicModule = require(RS.Modules.Basic)
local AttackClientModule = require(RS.Modules.AttackClient)
local InventoryModule = require(RS.Modules.Inventory)

-- State Variables
local teleportDebounce = false
local StaminaBoostDebounce = false
local fillDebounce = false
local hecatePart = nil
local hoverFrameConnection = nil
local infiniteZoomConnection = nil
local oldZoomDistance = LocalPlayer.CameraMaxZoomDistance
local OldTimeModule = BasicModule.GetTime
local OldAtmosphere = nil
local NaNNumber = 0 / 0
local childAddedConnection
local fishingTask

local modifiedStats = {
	Melee = nil,
	Melee2 = nil,
	Weapon = nil,
	Weapon2 = nil,
	Weapon3 = nil,
	Magic = nil,
	Magic2 = nil,
	Armor = nil,
	FoodItem = nil,
	SpoofedMagic = nil,
}

local espData = {
	Island = nil,
	Gui = nil,
	RegisteredItems = {},
	TrackingFrame = nil,
}

local NpcEspData = {}
local SpoofMagicTable = { "None" }

local settings = {
	DamageMultiplier = 1,
	BoatSpeedMultiplier = 1,
	RepairMultiplier = 1,
	ChestRadius = 25,
	EnableDamageMultiplier = false,
	GodMode = false,
	BlockNPCAggro = false,
	FastBoatRepair = false,
	NoTracking = false,
	ReduceStamina = false,
	OneTapStructures = false,
	QuickFillBottles = false,
	SpawnLightning = false,
	SilentBottleDrinking = false,
	AutoFish = false,
	AutoWash = false,
	HecateNotifier = false,
	EpicenterESP = false,
	BoatESP = false,
	BoostBoatSpeed = false,
	AutoEat = false,
	IsEating = false,
	PlayerDamageMulti = false,
	NPCEspActive = false,
	SpoofingMagic = false,
	ChestAura = false,
	WeaponDamageMultiplier = false,
	WeaponDamageAmt = 0,
}

-- Constants
local DAMAGE_REMOTES = {
	"DealAttackDamage",
	"DealStrengthDamage",
	"DealWeaponDamage",
	"DealMagicDamage",
	"DealDamageBoat",
	"DealDamageBoat3",
	"DealDamageBoat2",
	"DealDamageBoat1",
}

local ANIMATION_PACKS = { "Coward", "Boss", "Cute", "Lazy", "Fighter" }
local FOOD_ITEMS = { "Banana", "Red apple", "Green apple" }
local ALLOWED_ESP_TYPES = { "BasePart", "MeshPart", "Part", "Model" }

-- Lists for dropdowns
local teleportLocations = {}
local teleportLocationsExtended = {}
local magicTypes = { "None" }
local meleeTypes = { "None" }
local weaponTypes = { "None" }
local fishingTypes = { "Silent", "Legit" }
local itemTypes = {}
local FishingTool = nil
local fishingType = "Silent"
local NPCConnections = {}

-- Populate lists
for _, folder in Map:GetChildren() do
	if folder:FindFirstChild("Center") then
		table.insert(teleportLocations, folder.Name)
		table.insert(teleportLocationsExtended, folder.Name)
	end
end

table.insert(teleportLocationsExtended, "Diving Spots")
table.insert(teleportLocationsExtended, "Sealed Chests")
table.insert(teleportLocationsExtended, "Dark Sea Islands")

for _, Magic in MagicModule.Types do
	if Magic["Type"] ~= "Base Magic" then
		continue
	end
	table.insert(magicTypes, _)
end

for meleeType in MeleeModule.Types do
	table.insert(meleeTypes, meleeType)
end

for _, Magic in MagicModule.Types do
	if Magic["Type"] == "Base Magic" or Magic["Type"] == "Lost Magic" then
		table.insert(SpoofMagicTable, _)
	end
end

for itemName, itemData in InventoryModule.Items do
	if itemData.WeaponType then
		table.insert(weaponTypes, itemName)
	end
	if itemData.Type == "Accessory" or itemData.Type == "Chestpiece" or itemData.Type == "Leggings" then
		table.insert(itemTypes, itemName)
	end
end

-- Creating Tab Categories --
--Window:DrawCategory({ Text = "Main" })
local MainTab = Window:AddTab({
	Name = "Main",
	Icon = "house",
	EnableScrolling = true,
})
local GodmodeSection = MainTab:AddLeftGroupbox("Godmode")
local DamageSection = MainTab:AddLeftGroupbox("Damage Exploits")
local NPCSection = MainTab:AddLeftGroupbox("NPC Exploits")
local EatSection = MainTab:AddLeftGroupbox("Auto eat")

--Window:DrawCategory({ Text = "Exploits" })
local ExploitsTab = Window:AddTab({
	Name = "Exploits",
	Icon = "bug",
	EnableScrolling = true,
})
local BoatSection = ExploitsTab:AddLeftGroupbox("Boat Exploits")
local WeaponEXPSection = ExploitsTab:AddLeftGroupbox("Weapon Exploits")
local PlayerSection = ExploitsTab:AddLeftGroupbox("Player Exploits")

--Window:DrawCategory({ Text = "Item Exploits" })
local ItemExploitsTab = Window:AddTab({
	Name = "Item Exploits",
	Icon = "bug",
	EnableScrolling = true,
})
local ItemsSection = ItemExploitsTab:AddLeftGroupbox("Item Exploits")

--Window:DrawCategory({ Text = "Fishing Exploits" })
local FishingExploitsTab = Window:AddTab({
	Name = "Fishing Exploits",
	Icon = "bug",
	EnableScrolling = true,
})
local FishingSection = FishingExploitsTab:AddLeftGroupbox("Fish Exploits")

--Window:DrawCategory({ Text = "Module Exploits" })
local ModuleExploitsTab = Window:AddTab({
	Name = "Module Exploits",
	Icon = "bug",
	EnableScrolling = true,
})
local MagicSection = ModuleExploitsTab:AddLeftGroupbox("Magic Exploits")
local MeleeSection = ModuleExploitsTab:AddLeftGroupbox("Melee Exploits")
local WeaponsSection = ModuleExploitsTab:AddLeftGroupbox("Weapon Exploits")

--Window:DrawCategory({ Text = "Dark Sea" })
local DarkSeaTab = Window:AddTab({
	Name = "Dark Sea",
	Icon = "waves",
	EnableScrolling = true,
})
local DarkSeaSection = DarkSeaTab:AddLeftGroupbox("Dark Sea Exploits")

--Window:DrawCategory({ Text = "Teleports" })
local TeleportsTab = Window:AddTab({
	Name = "Teleports",
	Icon = "shell",
	EnableScrolling = true,
})
local TeleportSection = TeleportsTab:AddLeftGroupbox("Teleports")

--Window:DrawCategory({ Text = "Misc" })
local MiscTab = Window:AddTab({
	Name = "Misc",
	Icon = "apple",
	EnableScrolling = true,
})
local MiscSection = MiscTab:AddLeftGroupbox("Misc")
local DiscordSection = MiscTab:AddLeftGroupbox("Discord")

-- Helper Functions
local function generateRandomString()
	local length = math.random(10, 20)
	local chars = {}
	for i = 1, length do
		chars[i] = string.char(math.random(32, 126))
	end
	return table.concat(chars)
end

local function toPercentage(value)
	return string.format("%d%%", math.floor((value / 10000)))
end

local function OpenChest(Chest)
	if not Chest:IsA("Model") then
		return
	end
	if not Chest:FindFirstChild("Base") then
		return
	end

	local ProximityPrompt = Chest.Base:FindFirstChildOfClass("ProximityPrompt")
	if not ProximityPrompt then
		return
	end
	if Chest.Base.Transparency >= 0.3 then
		return
	end
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local Magnitude = (Character.HumanoidRootPart.Position - Chest.Base.Position).Magnitude
	if Magnitude > settings.ChestRadius then
		return
	end

	fireproximityprompt(ProximityPrompt)
end

local function scanIslandItems(Map, Character, registerItemESP)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	if not RootPart then
		warn("No HumanoidRootPart")
		return
	end

	local function isWithinDistance(part)
		return part and part:IsA("BasePart") and (RootPart.Position - part.Position).Magnitude <= 2000
	end

	local function tryRegister(part, className)
		if part and isWithinDistance(part) then
			registerItemESP(part, className or part.ClassName)
		end
	end

	for _, island in Map:GetChildren() do
		for _, folder in island:GetChildren() do
			if
				folder.Name == "Herbs"
				or folder.Name == "Fruits"
				or folder.Name == "Chests"
				or folder.Name == "Coconuts"
				or folder.Name == "Seaweed"
				or folder.Name == "Shells"
			then
				for _, item in folder:GetChildren() do
					if folder.Name == "Chests" then
						tryRegister(item:FindFirstChild("Base"), "BasePart")
					else
						tryRegister(item, item.ClassName)
					end
				end
			end
		end
	end

	-- Scan diving spots
	for _, model in Map.SeaContent:GetChildren() do
		if model.Name == "DivingSpot" or model.Name == "UWStructure" then
			for _, folder in model:GetChildren() do
				if folder.Name == "Chests" then
					for _, chest in folder:GetChildren() do
						tryRegister(chest:FindFirstChild("Base"), "BasePart")
					end
				elseif folder.Name == "Details" then
					for _, herb in folder:GetChildren() do
						if herb:FindFirstChildOfClass("ProximityPrompt") then
							tryRegister(herb, herb.ClassName)
						end
					end
				end
			end
		end
	end

	-- Scan sealed chests
	local tempFolder = Map:FindFirstChild("Temporary")
	if tempFolder then
		for _, sealed in tempFolder:GetChildren() do
			if
				(
					sealed.Name == "Bronze Sealed Chest"
					or sealed.Name == "Nimbus Sealed Chest"
					or sealed.Name == "Dark Sealed Chest"
				) and sealed:FindFirstChildOfClass("ProximityPrompt")
			then
				tryRegister(sealed, "MeshPart")
			end
		end
	end

	local darkSea = Map.SeaContent:FindFirstChild("DarkSea")
	for _, model in darkSea:GetChildren() do
		for _, folder in model:GetChildren() do
			if
				folder.Name == "Herbs"
				or folder.Name == "Fruits"
				or folder.Name == "Coconuts"
				or folder.Name == "Seaweed"
				or folder.Name == "Shells"
			then
				for _, Item in folder:GetChildren() do
					tryRegister(Item, Item.ClassName)
				end
			elseif folder.Name == "Chests" then
				for _, Item in folder:GetChildren() do
					tryRegister(Item:FindFirstChild("Base"), "BasePart")
				end
			end
		end
	end
end

local function getPlayerBoat()
	local Boat, SkyShip =
		BoatsFolder:FindFirstChild(LocalPlayer.Name .. "Boat"),
		BoatsFolder:FindFirstChild(LocalPlayer.Name .. "TempBoat")
	return Boat, SkyShip
end

local function clearItemESP()
	for _, entry in espData.RegisteredItems do
		local part, ui = unpack(entry)
		if ui then
			ui:Destroy()
		end
	end
	espData.RegisteredItems = {}
end

function ClearNpcEsp()
	for i = #NpcEspData, 1, -1 do
		local _, espGui, NPCConnections = unpack(NpcEspData[i])

		if NPCConnections then
			for _, conn in NPCConnections do
				if conn and conn.Connected then
					conn:Disconnect()
				end
			end
		end

		if espGui then
			espGui:Destroy()
		end
		table.remove(NpcEspData, i)
	end
end

local function NPCESP()
	local existingEspModels = {}
	for _, entry in NpcEspData do
		existingEspModels[entry[1]] = true
	end

	for _, Model in enemiesFolder:GetChildren() do
		if not Model:IsA("Model") then
			continue
		end
		local humanoid = Model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end

		if existingEspModels[Model] then
			continue
		end

		local adorneePart = Model:FindFirstChild("HumanoidRootPart")
		if not adorneePart then
			for _, Part in Model:GetChildren() do
				if Part:IsA("BasePart") then
					adorneePart = Part
					break
				end
			end
		end

		if adorneePart then
			local espGui = Instance.new("BillboardGui")
			espGui.Text = generateRandomString()
			espGui.Parent = adorneePart
			espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			espGui.Active = true
			espGui.AlwaysOnTop = true
			espGui.LightInfluence = 0
			espGui.Size = UDim2.new(0, 180, 0, 35)
			espGui.StudsOffset = Vector3.new(0, adorneePart.Size.Y / 2 + 1.5, 0)
			espGui.MaxDistance = math.huge

			local frame = Instance.new("Frame")
			frame.Parent = espGui
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 0, 1, 0)

			local label = Instance.new("TextLabel")
			label.Parent = frame
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.fromRGB(255, 0, 0)
			label.TextScaled = true
			label.Text = string.format("%s | %.0f/%.0f", Model.Name, humanoid.Health, humanoid.MaxHealth)

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.new(0, 0, 0)
			stroke.Parent = label

			local NPCConnections = {}

			local function updateHealthText()
				label.Text = string.format("%s | %.0f/%.0f", Model.Name, humanoid.Health, humanoid.MaxHealth)
			end

			table.insert(NPCConnections, humanoid.HealthChanged:Connect(updateHealthText))

			table.insert(NpcEspData, { Model, espGui, NPCConnections })

			table.insert(
				NPCConnections,
				Model.AncestryChanged:Connect(function()
					if not Model:IsDescendantOf(enemiesFolder) then
						for _, conn in pairs(NPCConnections) do
							if conn and conn.Connected then
								conn:Disconnect()
							end
						end
						for i = #NpcEspData, 1, -1 do
							if NpcEspData[i][1] == Model then
								if NpcEspData[i][2] then
									NpcEspData[i][2]:Destroy()
								end
								table.remove(NpcEspData, i)
								break
							end
						end
					end
				end)
			)

			table.insert(
				NPCConnections,
				humanoid.Died:Connect(function()
					for _, conn in NPCConnections do
						if conn and conn.Connected then
							conn:Disconnect()
						end
					end
					for i = #NpcEspData, 1, -1 do
						if NpcEspData[i][1] == Model then
							if NpcEspData[i][2] then
								NpcEspData[i][2]:Destroy()
							end
							table.remove(NpcEspData, i)
							break
						end
					end
				end)
			)
		end
	end

	for i = #NpcEspData, 1, -1 do
		local registeredModel, espGui, NPCConnections = unpack(NpcEspData[i])
		if
			not registeredModel.Parent
			or not registeredModel:IsDescendantOf(enemiesFolder)
			or not registeredModel:FindFirstChildOfClass("Humanoid")
		then
			if NPCConnections then
				for _, conn in NPCConnections do
					if conn and conn.Connected then
						conn:Disconnect()
					end
				end
			end
			if espGui then
				espGui:Destroy()
			end
			table.remove(NpcEspData, i)
		end
	end
end

local function unregisterItemESP(part)
	for i, entry in espData.RegisteredItems do
		local registeredPart, ui = unpack(entry)
		if registeredPart == part then
			if ui then
				ui:Destroy()
			end
			table.remove(espData.RegisteredItems, i)
			break
		end
	end
end

local function registerItemESP(part, itemType)
	if not part or not table.find(ALLOWED_ESP_TYPES, part.ClassName) or part.Transparency >= 1 then
		return
	end

	for _, entry in espData.RegisteredItems do
		if entry[1] == part then
			return
		end
	end

	local espGui = Instance.new("BillboardGui")
	espGui.Text = generateRandomString()
	espGui.Parent = part:IsA("Model") and (part.PrimaryPart or part:FindFirstChildOfClass("BasePart")) or part
	espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	espGui.Active = true
	espGui.AlwaysOnTop = true
	espGui.LightInfluence = 1
	espGui.Size = UDim2.new(0, 150, 0, 25)
	espGui.StudsOffset = Vector3.new(0, 1.5, 0)
	espGui.MaxDistance = math.huge

	local frame = Instance.new("Frame")
	frame.Parent = espGui
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 1, 0)

	local label = Instance.new("TextLabel")
	label.Parent = frame
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(102, 102, 102)
	label.TextScaled = true

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = label

	if part:FindFirstChildOfClass("ProximityPrompt") then
		label.Text = part:FindFirstChildOfClass("ProximityPrompt").ObjectText
	elseif itemType:lower() == "model" then
		label.Text = part.Parent.Name
	else
		label.Text = part.Name
	end

	part.Destroying:Connect(function()
		unregisterItemESP(part)
	end)

	part:GetPropertyChangedSignal("Transparency"):Connect(function()
		if part.Transparency >= 1 then
			unregisterItemESP(part)
		end
	end)

	table.insert(espData.RegisteredItems, { part, espGui })
end

-- UI Components
GodmodeSection:AddToggle("Godmode", {
	Text = "Godmode",
	Default = false,
	Callback = function(value)
		settings.GodMode = value
	end,
})

NPCSection:AddToggle("No NPC Aggro", {
	Text = "No NPC Aggro",
	Default = false,
	Callback = function(value)
		settings.BlockNPCAggro = value
	end,
})

NPCSection:AddToggle("NPC Esp", {
	Text = "NPC Esp",
	Default = false,
	Callback = function(value)
		if value == true then
			settings.NPCEspActive = value
		else
			settings.NPCEspActive = value
			task.delay(1, function()
				ClearNpcEsp()
			end)
		end
	end,
})

PlayerSection:AddSlider("FOV (Field Of View)", {
	Text = "FOV (Field Of View)",
	Default = CurrentCamera.FieldOfView,
	Min = 70,
	Max = 120,
	Rounding = 0,
	Callback = function(value)
		if tonumber(value) then
			CurrentCamera.FieldOfView = value
		end
	end,
})

PlayerSection:AddToggle("Reduced stamina consumption", {
	Text = "Reduced stamina consumption",
	Default = false,
	Callback = function(value)
		settings.ReduceStamina = value
	end,
})

PlayerSection:AddToggle("Drink Bottles Silently", {
	Text = "Drink Bottles Silently",
	Default = false,
	Callback = function(value)
		settings.SilentBottleDrinking = value
		Library:Notify({ Title = "Keybind!", Description = "The default keybind is '.'" })
	end,
})

PlayerSection:AddToggle("One tap buildings/structures", {
	Text = "One tap buildings/structures",
	Default = false,
	Callback = function(value)
		settings.OneTapStructures = value
	end,
})

PlayerSection:AddToggle("Infinite camera zoom", {
	Text = "Infinite camera zoom",
	Default = false,
	Callback = function(value)
		if value then
			infiniteZoomConnection = LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
				LocalPlayer.CameraMaxZoomDistance = math.huge
			end)
			LocalPlayer.CameraMaxZoomDistance = math.huge
		elseif infiniteZoomConnection then
			infiniteZoomConnection:Disconnect()
			LocalPlayer.CameraMaxZoomDistance = oldZoomDistance
		end
	end,
})

PlayerSection:AddToggle("No fog", {
	Text = "No fog",
	Default = false,
	Callback = function(value)
		if value then
			OldAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
			if OldAtmosphere then
				OldAtmosphere.Parent = ReplicatedStorage
			end

			local NewAtmosphere = Instance.new("Atmosphere")
			NewAtmosphere.Parent = Lighting
			NewAtmosphere.Density = 0
		else
			Lighting:FindFirstChildOfClass("Atmosphere"):Destroy()
			if OldAtmosphere then
				OldAtmosphere.Parent = Lighting
			end
		end
	end,
})

PlayerSection:AddToggle("No blur", {
	Text = "No blur",
	Default = false,
	Callback = function(value)
		Lighting:FindFirstChildOfClass("BlurEffect").Enabled = not value
	end,
})

PlayerSection:AddToggle("No depth of field", {
	Text = "No depth of field",
	Default = false,
	Callback = function(value)
		Lighting:FindFirstChildOfClass("DepthOfFieldEffect").Enabled = not value
	end,
})

PlayerSection:AddToggle("No sun rays", {
	Text = "No sun rays",
	Default = false,
	Callback = function(value)
		Lighting:FindFirstChildOfClass("SunRaysEffect").Enabled = not value
	end,
})

PlayerSection:AddToggle("No color correction", {
	Text = "No color correction",
	Default = false,
	Callback = function(value)
		Lighting:FindFirstChildOfClass("ColorCorrectionEffect").Enabled = not value
	end,
})

PlayerSection:AddToggle("No bloom", {
	Text = "No bloom",
	Default = false,
	Callback = function(value)
		Lighting:FindFirstChildOfClass("BloomEffect").Enabled = not value
	end,
})

PlayerSection:AddToggle("Full bright", {
	Text = "Full bright",
	Default = false,
	Callback = function(value)
		Lighting.Brightness = value and 1 or 0
		Lighting.ClockTime = value and 12 or OldTimeModule()
		Lighting.FogEnd = value and 100000 or 500
		Lighting.GlobalShadows = not value
		Lighting.Ambient = value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
	end,
})

PlayerSection:AddButton({
	Text = "Discover all islands",
	Func = function()
		for _, island in Map:GetChildren() do
			if island:FindFirstChild("Center") then
				Remotes.Misc.UpdateLastSeen:FireServer(island.Name, "")
				task.wait(0.05)
			end
		end
	end,
})

DamageSection:AddToggle("Enable damage multiplier", {
	Text = "Enable damage multiplier",
	Default = false,
	Callback = function(value)
		settings.EnableDamageMultiplier = value
	end,
})

DamageSection:AddSlider("Damage Multiplier", {
	Text = "Damage Multiplier",
	Default = 1,
	Min = 1,
	Max = 500,
	Rounding = 0,
	Callback = function(value)
		if tonumber(value) then
			settings.DamageMultiplier = tonumber(value)
		end
	end,
})

BoatSection:AddToggle("Fast boat repair", {
	Text = "Fast boat repair",
	Default = false,
	Callback = function(value)
		settings.FastBoatRepair = value
	end,
})

BoatSection:AddSlider("Repair Multiplier", {
	Text = "Repair Multiplier",
	Default = 1,
	Min = 1,
	Max = 50,
	Rounding = 0,
	Callback = function(value)
		if tonumber(value) then
			settings.RepairMultiplier = tonumber(value)
		end
	end,
})

BoatSection:AddToggle("Boost boat speed", {
	Text = "Boost boat speed",
	Default = false,
	Callback = function(value)
		settings.BoostBoatSpeed = value
	end,
})

BoatSection:AddSlider("Boat speed multiplier", {
	Text = "Boat speed multiplier",
	Default = 1,
	Min = 1,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		if tonumber(value) then
			settings.BoatSpeedMultiplier = tonumber(value)
		end
	end,
})

BoatSection:AddButton({
	Text = "Teleport to boat.",
	Func = function(value)
		local boat = getPlayerBoat()
		if not boat then
			return
		end
		local humanoidRoot = Character:FindFirstChild("HumanoidRootPart")
		if humanoidRoot then
			humanoidRoot.CFrame = boat:WaitForChild("Center", 5).CFrame * CFrame.new(0, 25, 0)
		end
	end,
})

EatSection:AddToggle("Toggle auto eat", {
	Text = "Toggle auto eat",
	Default = false,
	Callback = function(value)
		settings.AutoEat = value
	end,
})

EatSection:AddDropdown("Food Item", {
	Text = "Food Item",
	Values = FOOD_ITEMS,
	Callback = function(value)
		modifiedStats.FoodItem = value
	end,
})

ItemsSection:AddButton({
	Text = "Item ESP",
	Func = function(value)
		scanIslandItems(Map, Character, registerItemESP)
	end,
})

ItemsSection:AddButton({
	Text = "Clear Item ESP",
	Func = clearItemESP,
})

ItemsSection:AddButton({
	Text = "Quick fill bottles.",
	Func = function(value)
		if fillDebounce then
			return
		end
		fillDebounce = true
		local humanoid = Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
			for _ = 1, 100 do
				Remotes.Misc.EmptyBottle:FireServer()
			end
			task.delay(1, function()
				fillDebounce = false
			end)
		end
	end,
})

FishingSection:AddInput("Fishing Tool", {
	Text = "Fishing Tool",
	Default = "None",
	Numeric = false,
	Callback = function(value)
		if not value then
			return
		end
		if not LocalPlayer.Backpack:FindFirstChild(value) then
			return
		end

		if Character:FindFirstChildOfClass("Tool") then
			Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
			task.wait(0.1)
		end

		FishingTool = LocalPlayer.Backpack:FindFirstChild(value)
	end,
})

FishingSection:AddToggle("Toggle auto fish", {
	Text = "Toggle auto fish",
	Default = false,
	Callback = function(value)
		if not FishingTool then
			Library:Notify("No Fishing Tool.")
			return
		end

		if fishingType == "Silent" then
			settings.AutoFish = value
			if value == false then
				return
			end
			local CharPos = Character.HumanoidRootPart.Position
			local args = { FishingTool, nil, vector.create(0 / 0, 0 / 0, 0 / 0), "Normal Bait" }

			Remotes.Misc.FishClock:FireServer(unpack(args, 1, 4))
			Library:Notify("Cast")
		elseif fishingType == "Legit" then
			settings.AutoFish = value
			if value == false then
				return
			end
			Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
			task.wait(0.2)
			Character:FindFirstChildOfClass("Humanoid"):EquipTool(FishingTool)
			task.wait(0.2)

			Remotes.Misc.ToolAction:FireServer(Character:FindFirstChildOfClass("Tool"))
		end
	end,
})

FishingSection:AddDropdown("Fishing Type", {
	Text = "Fishing Type",
	Values = fishingTypes,
	Callback = function(value)
		fishingType = value
	end,
})

PlayerSection:AddToggle("Toggle insanity", {
	Text = "Toggle insanity",
	Default = true,
	Callback = function(value)
		local insanityScript = LocalPlayer.PlayerGui:WaitForChild("Temp", 10):FindFirstChild("Insanity")
		if insanityScript then
			insanityScript.Disabled = not value
		end
	end,
})

DarkSeaSection:AddButton({
	Text = "Disable fog circle",
	Func = function(value)
		local tempGui = LocalPlayer.PlayerGui:WaitForChild("Temp", 10)
		local darkSeaGui = tempGui and tempGui:FindFirstChild("DarkSea")

		if darkSeaGui then
			local sky1 = darkSeaGui:FindFirstChild("DarkSky1")
			local sky2 = darkSeaGui:FindFirstChild("DarkSky2")

			if sky1 and sky1:FindFirstChildOfClass("SpecialMesh") then
				sky1:FindFirstChildOfClass("SpecialMesh"):Destroy()
			end
			if sky2 and sky2:FindFirstChildOfClass("SpecialMesh") then
				sky2:FindFirstChildOfClass("SpecialMesh"):Destroy()
			end
		end

		local camSky1 = CurrentCamera:FindFirstChild("DarkSky1")
		local camSky2 = CurrentCamera:FindFirstChild("DarkSky2")

		if camSky1 and camSky1:FindFirstChildOfClass("SpecialMesh") then
			camSky1:FindFirstChildOfClass("SpecialMesh"):Destroy()
		end
		if camSky2 and camSky2:FindFirstChildOfClass("SpecialMesh") then
			camSky2:FindFirstChildOfClass("SpecialMesh"):Destroy()
		end
	end,
})

DarkSeaSection:AddButton({
	Text = "Disable dark sea rain",
	Func = function(value)
		local overheadFX = Workspace.Camera:WaitForChild("OverheadFX", 10)
		if overheadFX then
			overheadFX.DSRain.Lifetime = NumberRange.new(0, 0)
			overheadFX.DSRain2.Lifetime = NumberRange.new(0, 0)
		end
	end,
})

DarkSeaSection:AddToggle("Toggle auto wash bin", {
	Text = "Toggle auto wash bin",
	Default = false,
	Callback = function(value)
		settings.AutoWash = value
	end,
})

DarkSeaSection:AddToggle("Hecate essence notifier", {
	Text = "Hecate essence notifier",
	Default = false,
	Callback = function(value)
		settings.HecateNotifier = value
	end,
})

DarkSeaSection:AddToggle("Epicenter ESP", {
	Text = "Epicenter ESP",
	Default = false,
	Callback = function(value)
		settings.EpicenterESP = value
		local centerPart = Map:FindFirstChild("The Epicenter") and Map:FindFirstChild("The Epicenter").Center

		-- Clean up if toggled OFF
		if not settings.EpicenterESP then
			if espData.Gui then
				espData.Gui:Destroy()
				espData.Gui = nil
				espData.TrackingFrame = nil
			end
			if hoverFrameConnection then
				hoverFrameConnection:Disconnect()
				hoverFrameConnection = nil
			end
			return
		end

		-- Create GUI if it doesn't exist (when toggled ON)
		if not espData.Gui then
			espData.Gui = Instance.new("ScreenGui")
			espData.Gui.Parent = game:GetService("CoreGui")
			espData.Gui.Text = "EpicenterESPGui"
			espData.Gui.ResetOnSpawn = false

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 50, 0, 50)
			frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			frame.BorderSizePixel = 2
			frame.Parent = espData.Gui
			frame.Visible = false
			frame.Text = "TrackingFrame"
			espData.TrackingFrame = frame
		end

		-- Ensure connection is managed correctly
		if hoverFrameConnection then
			hoverFrameConnection:Disconnect()
			hoverFrameConnection = nil
		end

		-- Start the update loop
		hoverFrameConnection = RunService.RenderStepped:Connect(function()
			if not settings.EpicenterESP or not espData.TrackingFrame or not espData.Gui then
				if espData.Gui then
					espData.Gui:Destroy()
					espData.Gui = nil
					espData.TrackingFrame = nil
				end
				if hoverFrameConnection then
					hoverFrameConnection:Disconnect()
					hoverFrameConnection = nil
				end
				return
			end

			local currentCenterPart = Map:FindFirstChild("The Epicenter") and Map:FindFirstChild("The Epicenter").Center

			if currentCenterPart and espData.TrackingFrame then
				local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(currentCenterPart.Position)
				if onScreen then
					espData.TrackingFrame.Position = UDim2.new(
						0,
						screenPos.X - (espData.TrackingFrame.AbsoluteSize.X / 2),
						0,
						screenPos.Y - (espData.TrackingFrame.AbsoluteSize.Y / 2)
					)
					espData.TrackingFrame.Visible = true
				else
					espData.TrackingFrame.Visible = false
				end
			elseif espData.TrackingFrame then
				espData.TrackingFrame.Visible = false
			end
		end)
	end,
})

MiscSection:AddButton({
	Text = "Quick clear notoriety",
	Func = function()
		Remotes.UI.ClearBounty:InvokeServer("ClearNotoriety")
	end,
})

MiscSection:AddDropdown("Animation Packs", {
	Text = "Animation Packs",
	Values = ANIMATION_PACKS,
	Callback = function(value)
		BasicModule.GetAnimationPack = function()
			return value
		end
		Library:Notify({ Title = "Warning!", Description = "This won't apply until you reset." })
	end,
})

DiscordSection:AddButton({
	Text = "Join our discord!",
	Func = function()
		local module = loadstring(
			game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Discord%20Inviter/Source.lua")
		)()
		module.Join("https://discord.gg/3ZtcW4V6te")
	end,
})

TeleportSection:AddDropdown("Teleports", {
	Text = "Teleports",
	Values = teleportLocations,
	Callback = function(value)
		if teleportDebounce then
			return
		end
		teleportDebounce = true

		local island = Map:FindFirstChild(value)
		if not island then
			teleportDebounce = false
			return
		end

		local center = island:FindFirstChild("Center")
		if not center then
			teleportDebounce = false
			return
		end

		if value == "Harvest Island" then
			local oldPos = center.Position
			center.Position = Vector3.new(7236, 598, 343)
			task.delay(1, function()
				center.Position = oldPos
			end)
		end

		local landingPos = value == "Mount Othrys" and CFrame.new(0, -25000, 0) or CFrame.new(0, 1000, 0)
		local humanoidRoot = Character:FindFirstChild("HumanoidRootPart")

		if humanoidRoot then
			humanoidRoot.CFrame = center.CFrame * landingPos
			humanoidRoot.Anchored = true

			task.delay(15, function()
				if humanoidRoot then
					humanoidRoot.Anchored = false
				end
				teleportDebounce = false
			end)
		else
			teleportDebounce = false
		end
	end,
})

-- Magic Exploits
MagicSection:AddDropdown("[Magic]", {
	Text = "[Magic]",
	Values = magicTypes,
	Callback = function(value)
		if MagicModule.Types[value] then
			modifiedStats.Magic = value
		end
	end,
})

MagicSection:AddDropdown("[Magic 2]", {
	Text = "[Magic 2]",
	Values = magicTypes,
	Callback = function(value)
		if MagicModule.Types[value] then
			modifiedStats.Magic2 = value
		end
	end,
})

MagicSection:AddInput("Size", {
	Text = "Size",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Magic or modifiedStats.Magic == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MagicModule.Types[modifiedStats.Magic].Size = num

		if modifiedStats.Magic2 and modifiedStats.Magic2 ~= "None" then
			MagicModule.Types[modifiedStats.Magic2].Size = num
		end

		if num > 75 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: 75",
			})
		end
	end,
})

MagicSection:AddInput("Speed", {
	Text = "Speed",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Magic or modifiedStats.Magic == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MagicModule.Types[modifiedStats.Magic].Speed = num

		if modifiedStats.Magic2 and modifiedStats.Magic2 ~= "None" then
			MagicModule.Types[modifiedStats.Magic2].Speed = num
		end

		if num > 3 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: <3",
			})
		end
	end,
})

MagicSection:AddInput("Imbue Speed", {
	Text = "Imbue Speed",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Magic or modifiedStats.Magic == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MagicModule.Types[modifiedStats.Magic].ImbueSpeed = num

		if modifiedStats.Magic2 and modifiedStats.Magic2 ~= "None" then
			MagicModule.Types[modifiedStats.Magic2].ImbueSpeed = num
		end

		if num > 3 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: <3",
			})
		end
	end,
})

-- Melee Exploits
MeleeSection:AddDropdown("[Fighting Style]", {
	Text = "[Fighting Style]",
	Values = meleeTypes,
	Callback = function(value)
		if MeleeModule.Types[value] then
			modifiedStats.Melee = value
		end
	end,
})

MeleeSection:AddDropdown("[Fighting Style 2]", {
	Text = "[Fighting Style 2]",
	Values = meleeTypes,
	Callback = function(value)
		if MeleeModule.Types[value] then
			modifiedStats.Melee2 = value
		end
	end,
})

MeleeSection:AddInput("Size", {
	Text = "Size",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Melee or modifiedStats.Melee == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MeleeModule.Types[modifiedStats.Melee].Size = num

		if modifiedStats.Melee2 and modifiedStats.Melee2 ~= "None" then
			MeleeModule.Types[modifiedStats.Melee2].Size = num
		end

		if num > 5 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: < 5",
			})
		end
	end,
})

MeleeSection:AddInput("Speed", {
	Text = "Speed",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Melee or modifiedStats.Melee == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MeleeModule.Types[modifiedStats.Melee].Speed = num

		if modifiedStats.Melee2 and modifiedStats.Melee2 ~= "None" then
			MeleeModule.Types[modifiedStats.Melee2].Speed = num
		end

		if num > 3 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: < 3",
			})
		end
	end,
})

MeleeSection:AddInput("Imbue Speed", {
	Text = "Imbue Speed",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Melee or modifiedStats.Melee == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		MeleeModule.Types[modifiedStats.Melee].ImbueSpeed = num

		if modifiedStats.Melee2 and modifiedStats.Melee2 ~= "None" then
			MeleeModule.Types[modifiedStats.Melee2].ImbueSpeed = num
		end

		if num > 3 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: < 3",
			})
		end
	end,
})

-- Weapon Exploits
WeaponsSection:AddDropdown("[Weapon]", {
	Text = "[Weapon]",
	Values = weaponTypes,
	Callback = function(value)
		if InventoryModule.Items[value] then
			modifiedStats.Weapon = value
		end
	end,
})

WeaponsSection:AddDropdown("[Weapon 2]", {
	Text = "[Weapon 2]",
	Values = weaponTypes,
	Callback = function(value)
		if InventoryModule.Items[value] then
			modifiedStats.Weapon2 = value
		end
	end,
})

WeaponsSection:AddDropdown("[Weapon 3]", {
	Text = "[Weapon 3]",
	Values = weaponTypes,
	Callback = function(value)
		if InventoryModule.Items[value] then
			modifiedStats.Weapon3 = value
		end
	end,
})

WeaponsSection:AddInput("Size", {
	Text = "Size",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Weapon or modifiedStats.Weapon == "None" or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		InventoryModule.Items[modifiedStats.Weapon].Specs["Attack Size"].Value = num

		if modifiedStats.Weapon2 and modifiedStats.Weapon2 ~= "None" then
			InventoryModule.Items[modifiedStats.Weapon2].Specs["Attack Size"].Value = num
		end

		if modifiedStats.Weapon3 and modifiedStats.Weapon3 ~= "None" then
			InventoryModule.Items[modifiedStats.Weapon3].Specs["Attack Size"].Value = num
		end

		if num > 75 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: < 75",
			})
		end
	end,
})

WeaponsSection:AddInput("Speed", {
	Text = "Speed",
	Default = "1",
	Numeric = true,
	Callback = function(value)
		if not modifiedStats.Weapon or not tonumber(value) then
			return
		end

		local num = tonumber(value)
		InventoryModule.Items[modifiedStats.Weapon].Specs["Attack Speed"].Value = num

		if modifiedStats.Weapon2 and modifiedStats.Weapon2 ~= "None" then
			InventoryModule.Items[modifiedStats.Weapon2].Specs["Attack Speed"].Value = num
		end

		if modifiedStats.Weapon3 and modifiedStats.Weapon3 ~= "None" then
			InventoryModule.Items[modifiedStats.Weapon3].Specs["Attack Speed"].Value = num
		end

		if num > 3 then
			Library:Notify({
				Title = "Warning!",
				Description = "This could break your game if you set it too high. \n Suggested value: < 3",
			})
		end
	end,
})

-- Input Handling
UserInputService.InputBegan:Connect(function(input, isChatBox)
	if isChatBox or not settings.SilentBottleDrinking or input.KeyCode ~= Enum.KeyCode.Period then
		return
	end
	Remotes.Misc.EmptyBottle:FireServer(true)
end)

task.spawn(function()
	while task.wait(1) do
		if settings.NPCEspActive == true then
			NPCESP()
		end
	end
end)

task.spawn(function()
	while task.wait(10) do
		if settings.AutoEat then
			if modifiedStats.FoodItem ~= nil then
				local foodItem = modifiedStats.FoodItem
				local Tool = LocalPlayer.Backpack:FindFirstChild(foodItem)

				if Tool then
					Remotes.Misc.ToolAction:FireServer(Tool)
				end
			end
		end
	end
end)

local function setupFishingListener()
	if childAddedConnection then
		childAddedConnection:Disconnect()
	end
	childAddedConnection = Character.ChildAdded:Connect(function(child)
		if settings.AutoFish ~= true or child.Name ~= "FishBiteGoal" then
			return
		end
		Library:Notify("Fishing")
		if FishingTool ~= nil and fishingType == "Silent" then -- silent fish when FishBiteGoal is added as child
			repeat
				Remotes.Misc.FishState:FireServer("Reel")
				Library:Notify("Reel")
				task.wait(0)
			until child.Parent == nil or child.Parent ~= Character

			task.wait(0)
			local CharPos = Character.HumanoidRootPart.Position
			local args = { FishingTool, nil, vector.create(0 / 0, 0 / 0, 0 / 0), "Normal Bait" }

			Remotes.Misc.FishClock:FireServer(unpack(args, 1, 4))
			Library:Notify("Cast")
		elseif FishingTool ~= nil and fishingType == "Legit" then
			repeat
				Remotes.Misc.ToolAction:FireServer(FishingTool)
				task.wait(0.05)
			until child.Parent == nil or child.Parent ~= Character

			Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
			task.wait(0.5)
			Character:FindFirstChildOfClass("Humanoid"):EquipTool(FishingTool)

			task.delay(1, function()
				Remotes.Misc.ToolAction:FireServer(FishingTool)
			end)
		end
	end)
end

setupFishingListener()

local function startFishingLoop()
	if fishingTask then
		task.cancel(fishingTask)
	end
	fishingTask = task.spawn(function()
		while task.wait(10) do
			if FishingTool ~= nil and fishingType == "Legit" and settings.AutoFish == true then
				if FishingTool.Parent == Character then
					if Character:FindFirstChild("FishClock") == nil then
						Remotes.Misc.ToolAction:FireServer(FishingTool)
					end
				end
			end
		end
	end)
end

startFishingLoop()

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	setupFishingListener()
	startFishingLoop()
	if FishingTool then
		FishingTool = LocalPlayer.Backpack:FindFirstChild(FishingTool.Name)
			or Character:FindFirstChild(FishingTool.Name)
		if not FishingTool then
			Library:Notify({
				Title = "Warning!",
				Description = "Fishing tool not found in backpack. Please reselect the fishing tool.",
			})
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if settings.AutoWash == true then
			Remotes.Boats.Wash:FireServer()
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if settings.HecateNotifier then
			for _, child in DarkSeaFolder:GetChildren() do
				if child.Name == "Island" and child:FindFirstChild("HecateEssence") then
					StarterGui:SetCore("SendNotification", {
						Title = "Hecate found!",
						Text = "Click the button below to teleport.",
						Duration = 5,
						Button1 = "Teleport",
						Callback = TeleportBind,
					})
					hecatePart = child:FindFirstChild("HecateEssence")
				end
			end
		end
	end
end)

TeleportBind.OnInvoke = function()
	if hecatePart ~= nil then
		local humanoidRoot = Character:FindFirstChild("HumanoidRootPart")
		if humanoidRoot then
			humanoidRoot.CFrame = hecatePart.CFrame
		end
	end
end

task.spawn(function()
	while task.wait(5) do
		for _, player in ReplicatedStorage.RS.UnloadPlayers:GetChildren() do
			player.Parent = NPCs
		end
	end
end)

RunService.PreSimulation:Connect(function()
	if settings.BoostBoatSpeed == false then
		return
	end
	if settings.BoatSpeedMultiplier <= 1 then
		return
	end

	local Boat, SkyShip = getPlayerBoat()
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if Boat ~= nil then
		local center = Boat:WaitForChild("Center", 2)
		local bodyVelocity = center and center:FindFirstChild("SailV")

		if bodyVelocity and bodyVelocity.Velocity.Magnitude > 5 then
			bodyVelocity.Velocity = bodyVelocity.Velocity.Unit * (Boat.Speed.Value * 0.5) * settings.BoatSpeedMultiplier
		end
	end

	if SkyShip ~= nil then
		local center = SkyShip:WaitForChild("Center", 2)
		local bodyVelocity = center and center:FindFirstChild("SailV")

		if bodyVelocity and bodyVelocity.Velocity.Magnitude > 5 then
			bodyVelocity.Velocity = bodyVelocity.Velocity.Unit
				* (SkyShip.Speed.Value * 0.5)
				* settings.BoatSpeedMultiplier
		end
	end

	if Character.Humanoid.SeatPart ~= nil then
		local Seat = Character.Humanoid.SeatPart
		local OtherShip = Seat.Parent

		if OtherShip == nil then
			return
		end
		if OtherShip == Boat then
			return
		end
		if OtherShip == SkyShip then
			return
		end

		local bodyVelocity = OtherShip.Center:FindFirstChild("SailV")

		if bodyVelocity and bodyVelocity.Velocity.Magnitude > 5 then
			bodyVelocity.Velocity = bodyVelocity.Velocity.Unit
				* (OtherShip.Speed.Value * 0.5)
				* settings.BoatSpeedMultiplier
		end
	end
end)

local masterHook
masterHook = hookmetamethod(
	game,
	"__namecall",
	newcclosure(function(self, ...)
		local args = { ... }
		local method = getnamecallmethod()
		local remoteText = tostring(self.Name)

		if not checkcaller() then
			-- Stamina Cost Hook
			if remoteName == "StaminaCost" and method == "FireServer" and settings.ReduceStamina then
				if args[1] then
					args[1] = 0
				end
				return masterHook(self, unpack(args))
			end

			-- Structure Damage Hook
			if remoteName == "DamageStructure" and method == "InvokeServer" and settings.OneTapStructures then
				for i = 1, 50 do
					task.wait(0.05)
					masterHook(self, unpack(args))
				end
				return masterHook(self, unpack(args))
			end

			-- Lightning Hook
			if remoteName == "UpdateLastSeen" and method == "FireServer" and settings.SpawnLightning then
				if args[1] then
					args[1] = "The Dark Sea"
				end
				if args[2] then
					args[2] = ""
				end
				return masterHook(self, unpack(args))
			end

			-- NPC Aggro Hook
			if (remoteName == "TargetBehavior" or remoteName == "ChangeStatus") and settings.BlockNPCAggro then
				return
			end

			-- Damage Multiplier Hook
			if
				table.find(DAMAGE_REMOTES, remoteName)
				and method == "FireServer"
				and settings.EnableDamageMultiplier
			then
				if remoteName == "DealAttackDamage" or remoteName == "DealBossDamage" then
					if args[2] == Character and settings.GodMode then
						return
					end
				elseif remoteName == "DealWeaponDamage" or remoteName == "DealStrengthDamage" then
					if args[3] == Character and settings.GodMode then
						return
					end
				end

				for i = 1, settings.DamageMultiplier do
					masterHook(self, unpack(args))
				end
				return masterHook(self, unpack(args))
			end

			-- Weapon dmg mult
			if remoteName == "DealWeaponDamage" and method == "FireServer" and settings.WeaponDamageMultiplier then
				if args[3] == Character then
					return
				end
				if args[1] then
					args[1] = settings.WeaponDamageAmt
				end
				return masterHook(self, unpack(args))
			end

			-- God Mode Hook
			if method == "FireServer" and settings.GodMode then
				if remoteName == "DealAttackDamage" or remoteName == "DealBossDamage" then
					if args[2] == Character then
						args[2] = nil
					end
				elseif remoteName == "DealMagicDamage" then
					if args[2] == Character then
						args[2] = nil
					end
				elseif remoteName == "DealWeaponDamage" or remoteName == "DealStrengthDamage" then
					if args[3] == Character then
						args[3] = nil
					end
				elseif remoteName == "TouchDamage" or remoteName == "MiscDamage" or remoteName == "TakeSideDamage" then
					return
				end
				return masterHook(self, unpack(args))
			end

			-- Magic Spoofing Hook
			if remoteName == "DealAttackDamage" and method == "FireServer" and settings.SpoofingMagic then
				if args[3] and type(args[3]) == "string" then
					args[3] = modifiedStats.SpoofedMagic
				end
				return masterHook(self, unpack(args))
			end

			-- Boat Repair Hook
			if remoteName == "RepairHammer" and method == "InvokeServer" and settings.FastBoatRepair then
				for i = 1, settings.RepairMultiplier do
					masterHook(self, unpack(args))
				end
				return masterHook(self, unpack(args))
			end
		end

		return masterHook(self, unpack(args))
	end)
)

local SettingTab = Window:AddTab({
	Icon = "settings",
	Name = "Settings",
	Type = "Single",
	EnableScrolling = true,
})

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("Monsoon")
SaveManager:SetFolder("Monsoon/Arcane Odyssey")
SaveManager:SetSubFolder(BasicModule.ResolvePlaceId()) -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(SettingTab)

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox

local AccentKeyframe1 = Color3.fromHex("#02a3f5")
local AccentKeyframe2 = Color3.fromHex("#1546c1")
local AdvancedAccent = true

local Section = ThemeManager:CreateGroupBox(SettingTab)
ThemeManager:CreateThemeManager(Section)
Section:AddDivider()
Section:AddLabel("Accent Keyframe 1", false):AddColorPicker("Accent Keyframe 1", {
	Default = Color3.fromHex("#02a3f5"),
	Title = "Accent Keyframe 1",
	Callback = function(Value)
		AccentKeyframe1 = Value
	end,
})
Section:AddLabel("Accent Keyframe 2", false):AddColorPicker("Accent Keyframe 2", {
	Default = Color3.fromHex("#1546c1"),
	Title = "Accent Keyframe 2",
	Callback = function(Value)
		AccentKeyframe2 = Value
	end,
})
local Toggle = Section:AddToggle("Advanced Accent Enabled", {
	Text = "Enabled",
	Default = true,
	Callback = function(Value)
		AdvancedAccent = Value
		local Time = 0
		while AdvancedAccent do
			Time += task.wait() * 0.8
			Library.Options.AccentColor:SetValueRGB(AccentKeyframe1:Lerp(AccentKeyframe2, math.abs((Time % 2) - 1)), 0)
		end
	end,
})

if SaveManager:GetAutoloadConfig() == "none" then
	Library:SafeCallback(Toggle.Callback, Toggle.Default)
end

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
