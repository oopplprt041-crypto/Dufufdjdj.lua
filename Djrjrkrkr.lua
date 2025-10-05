--// ===============================
-- รวม Teleguiado + ExtraUI (ไม่แก้เนื้อหาเดิม)
-- รันทีเดียวขึ้นทั้งสอง GUI
--// ===============================

-- =================================
-- Teleguiado (Fly + Smart Avoid + Strong Escape + Camera Assist Control)
-- =================================
do
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local guidedOn = false
    local guidedConn
    local coilLoop
    local savedPos
    local offsetY = 9
    local flySpeed = 27
    local lastPos = nil
    local stuckTimer = 0
    local spinning = false
    local cameraInfluence = 0.4 -- 40% ควบคุมด้วยกล้อง

    -- GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleguiadoUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,200,0,100)
    frame.Position = UDim2.new(0.5,-100,0.5,-50)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0,6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local saveButton = Instance.new("TextButton", frame)
    saveButton.Size = UDim2.new(0,180,0,40)
    saveButton.Text = "บันทึกผัวลิต"
    saveButton.Font = Enum.Font.SourceSansBold
    saveButton.TextSize = 18
    saveButton.TextColor3 = Color3.new(1,1,1)
    saveButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
    saveButton.AutoButtonColor = false
    Instance.new("UICorner", saveButton).CornerRadius = UDim.new(0,8)

    local flyButton = Instance.new("TextButton", frame)
    flyButton.Size = UDim2.new(0,180,0,40)
    flyButton.Text = "ลอยไปหาผัวลิต ปิดอยู่"
    flyButton.Font = Enum.Font.SourceSansBold
    flyButton.TextSize = 18
    flyButton.TextColor3 = Color3.new(1,1,1)
    flyButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
    flyButton.AutoButtonColor = false
    Instance.new("UICorner", flyButton).CornerRadius = UDim.new(0,8)

    local function forceEquipItem(name)
        local char = LocalPlayer.Character
        if not char then return end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(name)
            if tool then tool.Parent = char end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local toolInChar = char:FindFirstChild(name)
        if hum and toolInChar then hum:EquipTool(toolInChar) end
    end

    local function checkObstacle(hrp, dir)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = Workspace:Raycast(hrp.Position, dir * 6, params)
        return (result and result.Instance) and true or false
    end

    local function spinAndSearch(hrp)
        spinning = true
        local startTime = tick()
        while tick() - startTime < 1.2 do
            local angle = (tick() * 6) % (2 * math.pi)
            local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
            if not checkObstacle(hrp, dir) then
                spinning = false
                return dir
            end
            RunService.RenderStepped:Wait()
        end
        spinning = false
        return nil
    end

    local function emergencyPhaseOut(hrp)
        local randomDir = Vector3.new(math.random(-100,100)/100, 0, math.random(-100,100)/100).Unit
        local startPos = hrp.Position
        local pushPower = 3.5
        for i = 1, 20 do
            local newPos = startPos + randomDir * pushPower
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(newPos), 0.6)
            RunService.RenderStepped:Wait()
        end
    end

    local function tryUnstuck(hrp)
        local escapeDir = spinAndSearch(hrp)
        if escapeDir then return escapeDir end
        emergencyPhaseOut(hrp)
        return (-hrp.CFrame.LookVector).Unit
    end

    flyButton.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        guidedOn = not guidedOn
        flyButton.Text = guidedOn and "ลอยไปหาผัวลิต เปิดอยู่" or "ลอยไปหาผัวลิต ปิดอยู่"

        if guidedOn and hum and hrp and savedPos then
            if coilLoop then coilLoop:Disconnect() end
            coilLoop = RunService.Heartbeat:Connect(function()
                forceEquipItem("Speed Coil")
            end)

            lastPos = hrp.Position

            guidedConn = RunService.RenderStepped:Connect(function(dt)
                if guidedOn and hrp and hum then
                    local targetPos = Vector3.new(savedPos.X, savedPos.Y + offsetY, savedPos.Z)
                    local toTarget = (targetPos - hrp.Position)
                    local dir = toTarget.Unit

                    local cam = Workspace.CurrentCamera
                    if cam and not spinning then
                        local camDir = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
                        dir = (dir * (1 - cameraInfluence) + camDir * cameraInfluence).Unit
                    end

                    if checkObstacle(hrp, dir) then
                        dir = (-hrp.CFrame.RightVector).Unit
                    end

                    if (hrp.Position - lastPos).Magnitude < 0.5 then
                        stuckTimer += dt
                        if stuckTimer > 1 then
                            dir = tryUnstuck(hrp)
                            stuckTimer = 0
                        end
                    else
                        stuckTimer = 0
                    end
                    lastPos = hrp.Position

                    if toTarget.Magnitude > 3 then
                        hrp.Velocity = dir * flySpeed
                        hum:Move(Vector3.zero)
                    else
                        guidedOn = false
                        flyButton.Text = "ลอยไปหาผัวลิต ปิดอยู่"
                        hrp.Velocity = Vector3.zero
                        hum:Move(Vector3.zero)
                        if guidedConn then guidedConn:Disconnect(); guidedConn = nil end
                        if coilLoop then coilLoop:Disconnect(); coilLoop = nil end
                    end
                end
            end)
        else
            if guidedConn then guidedConn:Disconnect(); guidedConn = nil end
            if coilLoop then coilLoop:Disconnect(); coilLoop = nil end
        end
    end)

    saveButton.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        savedPos = char:WaitForChild("HumanoidRootPart").Position
        saveButton.Text = "บันทึกผัวลิต👉👌"
        task.delay(1.5, function() saveButton.Text = "บันทึกผัวลิต" end)
    end)
end


-- =================================
-- ExtraUI (Float / AirWalk / Desync Panel)
-- =================================
do
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local screenGui2 = Instance.new("ScreenGui")
    screenGui2.Name = "ExtraUI"
    screenGui2.ResetOnSpawn = false
    screenGui2.Parent = LocalPlayer:WaitForChild("PlayerGui")

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

    local title2 = Instance.new("TextLabel")
    title2.Size = UDim2.new(1, 0, 0, 22)
    title2.BackgroundTransparency = 1
    title2.Text = "🌈 วานลิต สุดยอด 🌈"
    title2.Font = Enum.Font.SourceSansBold
    title2.TextSize = 15
    title2.TextColor3 = Color3.new(1,1,1)
    title2.Parent = frame2

    local textGradient = Instance.new("UIGradient")
    textGradient.Color = strokeGradient.Color
    textGradient.Parent = title2

    task.spawn(function()
        while task.wait(0.05) do
            textGradient.Rotation = (textGradient.Rotation + 2) % 360
        end
    end)

    local layout2 = Instance.new("UIListLayout")
    layout2.Padding = UDim.new(0, 4)
    layout2.FillDirection = Enum.FillDirection.Vertical
    layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout2.VerticalAlignment = Enum.VerticalAlignment.Top
    layout2.SortOrder = Enum.SortOrder.LayoutOrder
    layout2.Parent = frame2

    ---------------------------------------------------
    -- ฟังก์ชัน Float / AirWalk / Desync
    ---------------------------------------------------
    local HRP, floating, floatConn, floatSpeed = nil, false, nil, 30
    local airMode, airConn, fallSpeed = false, nil, -2

    local function Float(state)
        HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        if state and not floating then
            floating = true
            floatConn = RunService.Heartbeat:Connect(function()
                if floating and HRP then HRP.Velocity = Vector3.new(HRP.Velocity.X, floatSpeed, HRP.Velocity.Z) end
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
                if HRP and airMode then HRP.Velocity = Vector3.new(HRP.Velocity.X, fallSpeed, HRP.Velocity.Z) end
            end)
        else
            airMode = false
            if airConn then airConn:Disconnect() airConn = nil end
        end
    end

    ---------------------------------------------------
    -- สร้างปุ่ม
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
        local corner = Instance.new("UICorner", button)
        corner.CornerRadius = UDim.new(0, 6)
        local gradient = Instance.new("UIGradient", button)
        gradient.Color = strokeGradient.Color
        task.spawn(function()
            while task.wait(0.05) do gradient.Rotation = (gradient.Rotation + 2) % 360 end
        end)
        button.Parent = frame2
        return button
    end

    ---------------------------------------------------
    -- ปุ่ม Desync / Float / AirWalk
    ---------------------------------------------------
    local desyncButton = createButton2("ผัวเลียวานลิตโหดๆ")
    local floatBtn = createButton2("ผัวเลียวานลิต")
    local airBtn = createButton2("ผัวเลียวานลิฟ")

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
            if tool and tool.Parent==backpack then humanoid:EquipTool(tool) task.wait(0.5) end
            if setfflag then setfflag("WorldStepMax", "-9999999999") end
            task.wait(0.2)
            useItemRemote:FireServer()
            task.wait(1)
            teleportRemote:FireServer()
            task.wait(2)
            if setfflag then setfflag("WorldStepMax", "-1") end
            print("✅ Mobile Desync ativado!")
        end)
        if not success then warn("❌ Erro ao ativar desync: " .. tostring(error)) end
    end

    desyncButton.MouseButton1Click:Connect(function()
        enableMobileDesync()
        desyncButton.BackgroundColor3 = Color3.fromRGB(200,200,0)
        task.delay(1, function() desyncButton.BackgroundColor3 = Color3.fromRGB(60,60,60) end)
    end)

    floatBtn.MouseButton1Click:Connect(function()
        if not floating then Float(true) floatBtn.Text="ผัวหยุดเลียวานลิต" floatBtn.BackgroundColor3=Color3.fromRGB(170,0,0)
        else Float(false) floatBtn.Text="ผัวเลียวานลิต" floatBtn.BackgroundColor3=Color3.fromRGB(60,60,60) end
    end)

    airBtn.MouseButton1Click:Connect(function()
        if not airMode then AirWalk(true) airBtn.Text="ผัวหยุดเลียวายลิฟ" airBtn.BackgroundColor3=Color3.fromRGB(170,0,0)
        else AirWalk(false) airBtn.Text="ผัวเลียวานลิฟ" airBtn.BackgroundColor3=Color3.fromRGB(60,60,60) end
    end)
end
