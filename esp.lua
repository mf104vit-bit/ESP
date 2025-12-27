_G.ESPEnabled = true

--------------------------------------------------------------------
local Holder = Instance.new("Folder", game.CoreGui)
Holder.Name = "ESP"

local players = game:GetService("Players")
local plr = players.LocalPlayer
local RunService = game:GetService("RunService")

local connections = {}

-- إنشاء NameTag للاعب
local function createNameTag(v)
	if not v.Character then return nil end
	local head = v.Character:FindFirstChild("Head")
	if not head then return nil end
	
	local nameTag = Instance.new("BillboardGui")
	nameTag.Name = v.Name .. "NameTag"
	nameTag.Enabled = _G.ESPEnabled
	nameTag.Size = UDim2.new(0, 200, 0, 50)
	nameTag.AlwaysOnTop = true
	nameTag.StudsOffset = Vector3.new(0, 2.5, 0)
	nameTag.Adornee = head
	
	local tag = Instance.new("TextLabel", nameTag)
	tag.Name = "Tag"
	tag.BackgroundTransparency = 1
	tag.Position = UDim2.new(0, -50, 0, 0)
	tag.Size = UDim2.new(0, 300, 0, 20)
	tag.TextSize = 15
	tag.TextColor3 = v.TeamColor.Color
	tag.TextStrokeColor3 = Color3.new(0, 0, 0)
	tag.TextStrokeTransparency = 0.4
	tag.Text = v.DisplayName
	tag.Font = Enum.Font.SourceSansBold
	tag.TextScaled = false
	
	return nameTag
end

-- إزالة ESP للاعب
local function removeESP(v)
	local vHolder = Holder:FindFirstChild(v.Name)
	if vHolder then
		vHolder:ClearAllChildren()
	end
end

-- إنشاء/تحديث ESP للاعب
local function setupESP(v)
	if v == plr then return end
	if not v.Character then return end
	
	local humanoid = v.Character:FindFirstChild("Humanoid")
	local head = v.Character:FindFirstChild("Head")
	
	if not humanoid or not head then return end
	if humanoid.Health <= 0 then return end
	
	-- التأكد من وجود المجلد
	local vHolder = Holder:FindFirstChild(v.Name)
	if not vHolder then
		vHolder = Instance.new("Folder", Holder)
		vHolder.Name = v.Name
	end
	
	-- التحقق من الـ NameTag
	local existingTag = vHolder:FindFirstChild(v.Name .. "NameTag")
	
	-- إذا الـ NameTag غير موجود أو الـ Adornee تالف
	if not existingTag or not existingTag.Adornee or not existingTag.Adornee.Parent then
		if existingTag then
			existingTag:Destroy()
		end
		
		local newTag = createNameTag(v)
		if newTag then
			newTag.Parent = vHolder
		end
	else
		-- تحديث اللون والاسم
		existingTag.Enabled = _G.ESPEnabled
		if existingTag:FindFirstChild("Tag") then
			existingTag.Tag.TextColor3 = v.TeamColor.Color
			existingTag.Tag.Text = v.DisplayName
		end
	end
end

-- تحميل لاعب جديد
local function loadPlayer(v)
	if v == plr then return end
	
	local vHolder = Holder:FindFirstChild(v.Name)
	if not vHolder then
		vHolder = Instance.new("Folder", Holder)
		vHolder.Name = v.Name
	end
	
	if connections[v.Name] then
		for _, conn in pairs(connections[v.Name]) do
			pcall(function() conn:Disconnect() end)
		end
	end
	connections[v.Name] = {}
	
	connections[v.Name].charAdded = v.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		setupESP(v)
		
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				task.wait(0.1)
				removeESP(v)
			end)
		end
	end)
	
	connections[v.Name].charRemoving = v.CharacterRemoving:Connect(function()
		removeESP(v)
	end)
	
	if v.Character then
		setupESP(v)
		
		local hum = v.Character:FindFirstChild("Humanoid")
		if hum then
			hum.Died:Connect(function()
				task.wait(0.1)
				removeESP(v)
			end)
		end
	end
end

-- إزالة لاعب
local function unloadPlayer(v)
	removeESP(v)
	
	if connections[v.Name] then
		for _, conn in pairs(connections[v.Name]) do
			pcall(function() conn:Disconnect() end)
		end
		connections[v.Name] = nil
	end
	
	local vHolder = Holder:FindFirstChild(v.Name)
	if vHolder then
		vHolder:Destroy()
	end
end

-- تحميل جميع اللاعبين الحاليين
for _, v in pairs(players:GetPlayers()) do
	if v ~= plr then
		task.spawn(function()
			pcall(loadPlayer, v)
		end)
	end
end

players.PlayerAdded:Connect(function(v)
	if v ~= plr then
		task.wait(0.3)
		pcall(loadPlayer, v)
	end
end)

players.PlayerRemoving:Connect(function(v)
	pcall(unloadPlayer, v)
end)

players.LocalPlayer.NameDisplayDistance = 0

-- تفعيل/إيقاف ESP
local function toggleESP()
	_G.ESPEnabled = not _G.ESPEnabled
	
	for _, v in pairs(players:GetPlayers()) do
		if v ~= plr then
			if _G.ESPEnabled then
				setupESP(v)
			else
				removeESP(v)
			end
		end
	end
	
	print("ESP " .. (_G.ESPEnabled and "مفعل ✅" or "مطفي ❌"))
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Minus then
		toggleESP()
	end
end)

-- فحص وإصلاح تلقائي
RunService.Heartbeat:Connect(function()
	if not _G.ESPEnabled then return end
	
	for _, v in pairs(players:GetPlayers()) do
		if v ~= plr and v.Character then
			local humanoid = v.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				pcall(setupESP, v)
			end
		end
	end
end)