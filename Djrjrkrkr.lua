--// LocalScript (StarterGui)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- GUI ใหม่
local screenGui2 = Instance.new("ScreenGui")
screenGui2.Name = "ExtraUI"
screenGui2.ResetOnSpawn = false
screenGui2.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- แผงใหม่ (เล็กลง)
local frame2 = Instance.new("Frame")
frame2.Size = UDim2.new(0, 180, 0, 130)
frame2.Position = UDim2.new(0.8, -90, 0.5, -65)
frame2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame2.BackgroundTransparency = 0.2
frame2.BorderSizePixel = 0
frame2.Active = true
frame2.Draggable = true
frame2.Parent = screenGui2

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 12)
corner2.Parent = frame2

-- ขอบไฟ RGB หลายสี ไล่เฉด
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame2

local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,127,0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255,255,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75,0,130)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(148,0,211)),
}
strokeGradient.Parent = stroke

task.spawn(function()
    while task.wait(0.05) do
        strokeGradient.Rotation = (strokeGradient.Rotation + 2) % 360
    end
end)

-- Title
local title2 = Instance.new("TextLabel")
title2.Size = UDim2.new(1, 0, 0, 22)
title2.BackgroundTransparency = 1
title2.Text = "🌈 วานลิต สุดยอด 🌈"
title2.Font = Enum.Font.SourceSansBold
title2.TextSize = 15
title2.TextColor3 = Color3.new(1,1,1)
title2.Parent = frame2

-- ไล่เฉดสีตัวอักษร
local textGradient = Instance.new("UIGradient")
textGradient.Color = strokeGradient.Color
textGradient.Parent = title2

task.spawn(function()
    while task.wait(0.05) do
        textGradient.Rotation = (textGradient.Rotation + 2) % 360
    end
end)

-- Layout ปุ่ม
local layout2 = Instance.new("UIListLayout")
layout2.Padding = UDim.new(0, 4)
layout2.FillDirection = Enum.FillDirection.Vertical
layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout2.VerticalAlignment = Enum.VerticalAlignment.Top
layout2.SortOrder = Enum.SortOrder.LayoutOrder
layout2.Parent = frame2

---------------------------------------------------
-- ฟังก์ชัน Float / AirWalk
---------------------------------------------------
local HRP = nil
local floating = false
local floatConn = nil
local floatSpeed = 30

local airMode = false
local airConn = nil
local fallSpeed = -2

local function Float(state)
    HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    if state and not floating then
        floating = true
        floatConn = RunService.Heartbeat:Connect(function()
            if floating and HRP then
                HRP.Velocity = Vector3.new(HRP.Velocity.X, floatSpeed, HRP.Velocity.Z)
            end
        end)
    else
        floating = false
        if floatConn then floatConn:Disconnect() floatConn = nil end
    end
end

local function AirWalk(state)
    HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    if state and not airMode then
        airMode = true
        airConn = RunService.Heartbeat:Connect(function()
            if HRP and airMode then
                HRP.Velocity = Vector3.new(HRP.Velocity.X, fallSpeed, HRP.Velocity.Z)
            end
        end)
    else
        airMode = false
        if airConn then airConn:Disconnect() airConn = nil end
    end
end

---------------------------------------------------
-- ฟังก์ชันสร้างปุ่ม
---------------------------------------------------
local function createButton2(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 130, 0, 26)
    button.Text = name
    button.Font = Enum.Font.SourceSans
    button.TextSize = 15
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.AutoButtonColor = true
    button.TextColor3 = Color3.new(1,1,1)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local gradient = Instance.new("UIGradient")
    gradient.Color = strokeGradient.Color
    gradient.Parent = button

    task.spawn(function()
        while task.wait(0.05) do
            gradient.Rotation = (gradient.Rotation + 2) % 360
        end
    end)

    button.Parent = frame2
    return button
end

---------------------------------------------------
-- ปุ่ม Desync (บนสุด)
---------------------------------------------------
local desyncButton = createButton2("ผัวเลียวานลิตโหดๆ")

local function enableMobileDesync()
    local success, error = pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not packages then return end
        local netFolder = packages:WaitForChild("Net", 5)
        if not netFolder then return end

        local useItemRemote = netFolder:WaitForChild("RE/UseItem", 5)
        local teleportRemote = netFolder:WaitForChild("RE/QuantumCloner/OnTeleport", 5)
        if not useItemRemote or not teleportRemote then return end

        local toolNames = {"Quantum Cloner", "Brainrot", "brainrot"}
        local tool
        for _, toolName in ipairs(toolNames) do
            tool = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
            if tool then break end
        end
        if not tool then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then tool=item break end
            end
        end
        if tool and tool.Parent==backpack then
            humanoid:EquipTool(tool)
            task.wait(0.5)
        end

        if setfflag then setfflag("WorldStepMax", "-9999999999") end
        task.wait(0.2)
        useItemRemote:FireServer()
        task.wait(1)
        teleportRemote:FireServer()
        task.wait(2)
        if setfflag then setfflag("WorldStepMax", "-1") end
        print("✅ Mobile Desync ativado!")
    end)
    if not success then
        warn("❌ Erro ao ativar desync: " .. tostring(error))
    end
end

desyncButton.MouseButton1Click:Connect(function()
    enableMobileDesync()
    desyncButton.BackgroundColor3 = Color3.fromRGB(200,200,0)
    task.delay(1, function()
        desyncButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end)
end)

---------------------------------------------------
-- ปุ่ม Float
---------------------------------------------------
local floatBtn = createButton2("ผัวเลียวานลิต")
floatBtn.MouseButton1Click:Connect(function()
    if not floating then
        Float(true)
        floatBtn.Text = "ผัวหยุดเลียวานลิต"
        floatBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    else
        Float(false)
        floatBtn.Text = "ผัวเลียวานลิต"
        floatBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

---------------------------------------------------
-- ปุ่ม AirWalk
---------------------------------------------------
local airBtn = createButton2("ผัวเลียวานลิฟ")
airBtn.MouseButton1Click:Connect(function()
    if not airMode then
        AirWalk(true)
        airBtn.Text = "ผัวหยุดเลียวายลิฟ"
        airBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    else
        AirWalk(false)
        airBtn.Text = "ผัวเลียวานลิฟ"
        airBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)
