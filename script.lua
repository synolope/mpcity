local function service(...) return game:GetService(...) end
local Players = service("Players")
local MarketplaceService = service("MarketplaceService")
local ReplicatedStorage = service("ReplicatedStorage")
local HttpService = service("HttpService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Connection = ReplicatedStorage:WaitForChild("Connection")
local ConnectionEvent = ReplicatedStorage:WaitForChild("ConnectionEvent")

local function getservers()
	return Connection:InvokeServer(399)
end

local function joinserver(instid)
	return Connection:InvokeServer(400,instid)
end

local library = loadstring(game:HttpGet("https://pastebin.com/raw/6EEJc0M5",true))() -- https://pastebin.com/raw/SjcYQ23F

local Window,frame = library:AddWindow("   " .. MarketplaceService:GetProductInfo(game.PlaceId).Name .. "      THIS GUI WAS MADE BY SYNOLOPE", {
	main_color = Color3.fromRGB(151, 85, 163),
	min_size = Vector2.new(500, 600),
	toggle_key = Enum.KeyCode.RightShift,
	can_resize = true,
})

frame:GetPropertyChangedSignal("Position"):Connect(function()
	local pos = frame.Position
	writefile("meepcityguipos.txt",tostring(pos.X.Scale) .. "," .. tostring(pos.X.Offset) .. "," .. tostring(pos.Y.Scale) .. "," .. tostring(pos.Y.Offset))
end)

if isfile("meepcityguipos.txt") then
	local posnums = string.split(readfile("meepcityguipos.txt"),",")
	coroutine.wrap(function()
		service("RunService").Heartbeat:Wait()
		for i = 1,10,1 do frame.Position = UDim2.new(table.unpack(posnums)) end
	end)()
end

local Avatar = Window:AddTab("Avatar")
local AvatarEditor = Window:AddTab("Avatar Editor")
local Shop = Window:AddTab("Shop")
local Fishing = Window:AddTab("Fishing")
local Servers = Window:AddTab("Servers")
local Extra = Window:AddTab("Extras")

local function colorToTable(clr) return {tostring(clr.R*255),tostring(clr.G*255),tostring(clr.B*255)} end

local function ExtractData(humdes)
	local ava = {}

	for _,v in pairs({"WidthScale", "HeadScale","HeightScale","DepthScale","BodyTypeScale","ProportionScale"}) do
		ava[v] = humdes[v]
	end

	for _,v in pairs({"Face","Head","LeftArm","RightArm","LeftLeg","RightLeg","Torso"}) do
		ava[v] = humdes[v]
	end

	for _,v in pairs({"HeadColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor","TorsoColor"}) do
		ava[v] = colorToTable(humdes[v])
	end

	for _,v in pairs({"GraphicTShirt","Shirt","Pants"}) do
		ava[v] = humdes[v]
	end

	for _,v in pairs({"ClimbAnimation","FallAnimation","IdleAnimation","JumpAnimation","RunAnimation","SwimAnimation","WalkAnimation"}) do
		ava[v] = humdes[v]
	end


	for _,v in pairs({"Hat","Hair","Back","Face","Front","Neck","Shoulders","Waist"}) do
		ava[v .. "Accessory"] = humdes[v .. "Accessory"]
	end
	ava.Emotes = humdes:GetEmotes()

	local layered = humdes:GetAccessories(false)

	for i,v in pairs(layered) do
		if v.AccessoryType and typeof(v.AccessoryType) == "EnumItem" then
			v.AccessoryType = v.AccessoryType.Name
		end
	end

	ava.AccessoryBlob = layered

	return ava
end

Avatar:AddLabel("Load Avatar")

Avatar:AddTextBox("Load Avatar From UserId",function(userid)
	if userid and tonumber(userid) and Players:GetHumanoidDescriptionFromUserId(tonumber(userid)) then
		local data = ExtractData(Players:GetHumanoidDescriptionFromUserId(tonumber(userid)))
		ConnectionEvent:FireServer(315,data,true)
	end
end)

Avatar:AddTextBox("Load Avatar From Username",function(username)
	if username and Players:GetUserIdFromNameAsync(username) then
		local data = ExtractData(Players:GetHumanoidDescriptionFromUserId(Players:GetUserIdFromNameAsync(username)))
		ConnectionEvent:FireServer(315,data,true)
	end
end)

local cliplabel = Avatar:AddLabel("")

local avatarclipboard = nil
local avatarclipboardname = "Unnamed"

local function copytoclip(data,name)
	if not data then
		avatarclipboard = nil
		avatarclipboardname = "Unnamed"
		cliplabel.Text = "Avatar Clipboard"
	else
		avatarclipboard = data
		avatarclipboardname = name
		cliplabel.Text = "Avatar Clipboard: " .. name
	end
end

local function LoadPlayer(player)
	coroutine.wrap(function()
		if player ~= Players.LocalPlayer then
			local function LoadCharacter(character)
				local prox = Instance.new("ProximityPrompt",character:WaitForChild("HumanoidRootPart"))
				prox.ActionText = "Copy Avatar To Clipboard"
				prox.ObjectText = player.DisplayName
				prox.KeyboardKeyCode = Enum.KeyCode.C
				prox.HoldDuration = .2
				prox.RequiresLineOfSight = false
				prox.Triggered:Connect(function()
					if character and character:FindFirstChild("Humanoid") and character.Humanoid:FindFirstChild("HumanoidDescription") then
						copytoclip(ExtractData(character.Humanoid.HumanoidDescription),player.DisplayName)
					end
				end)
			end
			LoadCharacter(player.Character or player.CharacterAdded:Wait())
			player.CharacterAdded:Connect(LoadCharacter)
		end
	end)()
end

for _,player in pairs(Players:GetPlayers()) do LoadPlayer(player) end
Players.PlayerAdded:Connect(LoadPlayer)

local clipbuttons = Avatar:AddHorizontalAlignment()

copytoclip()

clipbuttons:AddButton("Copy Current Avatar",function()
	local player = Players.LocalPlayer
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") and character.Humanoid:FindFirstChild("HumanoidDescription") then
		copytoclip(ExtractData(character.Humanoid.HumanoidDescription),player.DisplayName)
	end
end)

clipbuttons:AddButton("Load Avatar",function()
	if avatarclipboard then
		ConnectionEvent:FireServer(315,avatarclipboard,true)
	end
end)

clipbuttons:AddButton("Load Hair Combo",function()
	if avatarclipboard then
		local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
		local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
		wearing.HairAccessory = avatarclipboard.HairAccessory
		ConnectionEvent:FireServer(315,wearing,true)
	end
end)

clipbuttons:AddButton("Save Avatar",function()
	if avatarclipboard then
		Connection:InvokeServer(65,avatarclipboardname)

		Connection:InvokeServer(319,avatarclipboard)
	end
end)

Avatar:AddLabel("Fun")

Avatar:AddButton("Big Head",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.HeadScale = 99999
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Small Head",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.HeadScale = 0
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Huge Scales",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.HeadScale = 99999
	wearing.BodyTypeScale = 99999
	wearing.DepthScale = 99999
	wearing.HeightScale = 99999
	wearing.ProportionScale = 99999
	wearing.WidthScale = 99999
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Small Scales",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.HeadScale = 0
	wearing.BodyTypeScale = 0
	wearing.DepthScale = 0
	wearing.HeightScale = 0
	wearing.ProportionScale = 0
	wearing.WidthScale = 0
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Naked",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.Shirt = "0"
	wearing.Pants = "0"
	wearing.GraphicTShirt = "0"
	wearing.AccessoryBlob = {}
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Bypassed Shading",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.GraphicTShirt = "9196895619"
	ConnectionEvent:FireServer(315,wearing,true)
end)

Avatar:AddButton("Trapify",function()
	local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
	local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
	wearing.GraphicTShirt = "9196895619"
	wearing.Pants = "7591261065"
	wearing.Shirt = "0"
	wearing.AccessoryBlob = {}
	ConnectionEvent:FireServer(315,wearing,true)
end)

Servers:AddButton("Join Most Populated Server",function()
	local server = getservers()[1]
	joinserver(server.InstanceId)
end)

local function rnd()
	return math.random(-25,25)
end

local crazyloop = nil
local cameravec = Players.LocalPlayer:WaitForChild("Data"):WaitForChild("CameraVector")

Extra:AddSwitch("Go Crazy",function(bool)
	if bool then
		if crazyloop then
			crazyloop:Disconnect()
			crazyloop = nil
		end
		crazyloop = service("RunService").Heartbeat:Connect(function()
			local vec = Vector3.new(rnd(),rnd(),rnd())
			cameravec.Value = vec
			ConnectionEvent:FireServer(163, vec)
		end)
	else
		crazyloop:Disconnect()
		crazyloop = nil
	end
end)

local h = 0
local rainbowloop = nil

Extra:AddSwitch("Rainbow Boy",function(bool)
	if bool then
		if rainbowloop then
			rainbowloop:Disconnect()
			rainbowloop = nil
		end
		rainbowloop = service("RunService").Heartbeat:Connect(function()
			if h > 1 then
				h = h - 1
			end
			local data = Connection:InvokeServer(Constants.AE_REQUEST_AE_DATA)
			local wearing = data.PlayerCurrentTemporaryOutfit or data.PlayerCurrentlyWearing
			for _,v in pairs({"HeadColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor","TorsoColor"}) do
				wearing[v] = colorToTable(Color3.fromHSV(h,1,1))
			end
			ConnectionEvent:FireServer(315,wearing,true)
			h = h + 0.001
		end)
	else
		rainbowloop:Disconnect()
		rainbowloop = nil
	end
end)

Fishing:AddSwitch("Fishing Silent Aim",function(b)
	if b then
		Constants.STATS.FISHCastObjectMinDistanceToCatch = 9999999
	else
		Constants.STATS.FISHCastObjectMinDistanceToCatch = 50
	end
end)

Fishing:AddSwitch("Client Unlimited Bucket Size",function(b)
	if b then
		Constants.STATS.FISHMaxAllowedInBucket = 9999999
	else
		Constants.STATS.FISHMaxAllowedInBucket = 20
	end
end)

AvatarEditor:AddSwitch("No Outfit Max",function(b)
	if b then
		Constants.STATS.MAXAvatarEditorCustomOutfits = 999999
	else
		Constants.STATS.MAXAvatarEditorCustomOutfits = 3
	end
end)

Extra:AddSwitch("Unlimited Whisper Length",function(b)
	if b then
		Constants.STATS.WHISPER_MAX_CHARACTERS = 999999
	else
		Constants.STATS.WHISPER_MAX_CHARACTERS = 80
	end
end)

local oldplusfunc = nil

Extra:AddButton("Spoof PLUS",function()
	local v9 = require(ReplicatedStorage:WaitForChild("Global"));
	oldplusfunc = hookfunction(v9.IsPlayerPLUS,function(p80)
		local v110 = Players:GetPlayerByUserId(p80);
		if not v110 then
			return;
		end;
		if v110 == Players.LocalPlayer then
			v110:SetAttribute("PLUS",true)
			return true;
		else
			return v110:GetAttribute("PLUS") and false;
		end
	end)
end)

--[[local selectedasset = nil

local Furniture = {table.unpack(require(ReplicatedStorage.Shop_Furniture).Assets),table.unpack(require(ReplicatedStorage.Shop_HomeImprovement).Assets),table.unpack(require(ReplicatedStorage.Shop_PetShop).Assets),table.unpack(require(ReplicatedStorage.Shop_Toys).Assets)}
local AssetList = {}

for _,v in pairs(require(ReplicatedStorage.AssetList)) do
	table.insert(AssetList,v)
end

table.sort(AssetList, function(a,b)
    return a.Title < b.Title
end)

local assetlabels = {}

local function GetAssetData(assetid)
	local data = nil
	for i,v in pairs(Furniture) do
		if v.AssetId == assetid then
			data = v
			break
		end
	end
	return data
end

local function SelectAsset(title)
	local asset = nil
	table.sort(AssetList, function(a,b)
    	return false
	end)
	for i,v in pairs(AssetList) do
		if v.Title == title then
			asset = v
			break
		end
	end
	selectedasset = asset
	local data = GetAssetData(asset.AssetId)
	if data then
		assetlabels.name.Text = "Name: " .. asset.Title
		assetlabels.assetid.Text = "AssetId: " .. tostring(asset.AssetId)
		assetlabels.cost.Text = "Price: " .. tostring(data.Details.Price.Coins or "No Price In Coins")
	else
		assetlabels.name.Text = "Name: " .. asset.Title
		assetlabels.assetid.Text = "AssetId: " .. tostring(asset.AssetId)
		assetlabels.cost.Text = "Price: Data Not Found"
	end
end

local assetdropdown = Shop:AddDropdown("Asset",SelectAsset)

assetlabels.name = Shop:AddLabel("Asset Name")
assetlabels.assetid = Shop:AddLabel("AssetId")
assetlabels.cost = Shop:AddLabel("Asset Price")

for i,v in pairs(AssetList) do
	assetdropdown:Add(v.Title)
end

local assetbuttons = Shop:AddHorizontalAlignment()

assetbuttons:AddButton("Purchase Asset",function()
	if selectedasset then
		local data = GetAssetData(selectedasset.AssetId)
		if data then
			Connection:InvokeServer(19,1,data.ObjectId,{["Quantity"] = 1,["PreferredPaymentMethod"] = "coins"})
		end
	end
end)]]

local onsaleran = false

Shop:AddButton("Make Offsale Assets Available",function()
	if not onsaleran then
		onsaleran = true
		local function onsale(module)
			local fd = require(module)
			local id = 666
			fd.Categories[id] = {
				CategoryId = id,
				Image = 5277185610,
				CatTitle = "offsale ;)"

			}
			for i,v in pairs(fd.Assets) do
				if not fd.Assets[i].ForSale then
					fd.Assets[i].ForSale = true
					if fd.Assets[i].Details.Price.HalloweenCandy then
						fd.Assets[i].Details.Price.HalloweenCandy = nil
					end
					fd.Assets[i].CatId = id
					fd.Assets[i].Desc = "this is an offsale item that got brought back to life"
				end
			end
		end
		onsale(game.ReplicatedStorage:WaitForChild("Shop_Furniture"))
		onsale(game.ReplicatedStorage:WaitForChild("Shop_Toys"))
		onsale(game.ReplicatedStorage:WaitForChild("Shop_HomeImprovement"))
		onsale(game.ReplicatedStorage:WaitForChild("Shop_PetShop"))
	end
end)

Extra:AddButton("Generate Coins",function()
	syn.queue_on_teleport([[
if not game:IsLoaded() then game.Loaded:Wait() end
local gui = Instance.new("ScreenGui",game.CoreGui)
gui.IgnoreGuiInset = true
local frame = Instance.new("Frame",gui)
frame.BorderSizePixel = 0
frame.Size = UDim2.new(1,0,1,0)
frame.Position = UDim2.new(0.5,0,0.5,0)
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.BackgroundColor3 = Color3.new(0,0,0)
local tb = Instance.new("TextLabel",frame)
tb.Size = UDim2.new(.2,0,.2,0)
tb.Position = UDim2.new(0.5,0,0.5,0)
tb.AnchorPoint = Vector2.new(0.5,0.5)
tb.BackgroundTransparency = 1
tb.TextColor3 = Color3.new(.9,.9,.9)
tb.Font = "Code"
tb.Text = ""
tb.TextScaled = true

game.RunService.Heartbeat:Connect(function()
for _,v in pairs(game.CoreGui:GetChildren()) do
if v ~= gui then
v:Destroy()
end
end
end)

wait(5)
print("running")
local c = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

wait(2)

local c = 0

for i = 1,10,1 do
for i = 1,1000,1 do
coroutine.wrap(function()
local args = {
    [1] = 369
}

game:GetService("ReplicatedStorage").Connection:InvokeServer(unpack(args))
c = c + 1
tb.Text = "Generated " .. tostring(c*60) .. " coins"
wait()
end)()
end
wait(1)
end

syn.queue_on_teleport("loadstring(game:HttpGet(\"https://raw.githubusercontent.com/synolope/mpcity/main/loader.lua\",true))()")

wait(2)

game:GetService("ReplicatedStorage").Connection:InvokeServer(293, 3, {
	DestinationVW = 7
})

]])

wait(1)

ConnectionEvent:FireServer(Constants.PIZZASHACK_REQUEST_FAKE_DELIVERY)
end)

Avatar:Show()
library:FormatWindows()