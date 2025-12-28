local Nexus = _G.Nexus

local Visual = {
    Connections = {},
    ESP = {
        lastUpdate = 0,
        UPDATE_INTERVAL = 0.1,
        settings = {
            Survivors  = {Enabled=false, Color=Color3.fromRGB(100,255,100), Colorpicker = nil},
            Killers    = {Enabled=false, Color=Color3.fromRGB(255,100,100), Colorpicker = nil},
            Generators = {Enabled=false, Color=Color3.fromRGB(100,170,255)},
            Pallets    = {Enabled=false, Color=Color3.fromRGB(120,80,40), Colorpicker = nil},
            ExitGates  = {Enabled=false, Color=Color3.fromRGB(200,200,100), Colorpicker = nil},
            Windows    = {Enabled=false, Color=Color3.fromRGB(100,200,200), Colorpicker = nil},
            Hooks      = {Enabled=false, Color=Color3.fromRGB(100, 50, 150), Colorpicker = nil}
        },
        trackedObjects = {},
        espConnections = {},
        espLoopRunning = false,
        showGeneratorPercent = true
    },
    PlayerESP = {
        enabled = false,
        settings = {
            Box_Color = Color3.fromRGB(255, 0, 0),
            Box_Thickness = 2,
            Team_Check = false,
            Team_Color = false,
            Autothickness = true,
            Show_Names = true,
            Show_HealthBar = true
        },
        colorMap = {
            DarkGreen = Color3.fromRGB(0,80,0),
            DarkOrange = Color3.fromRGB(140,70,0),
            DarkRed = Color3.fromRGB(100,0,0)
        },
        connections = {},
        espObjects = {},
        playerConnections = {}
    },
    Effects = {
        noShadowEnabled = false,
        noFogEnabled = false,
        fullbrightEnabled = false,
        timeChangerEnabled = false,
        originalFogEnd = nil,
        originalFogStart = nil,
        originalFogColor = nil,
        fogCache = nil,
        originalClockTime = nil        
    }
}

-- Вспомогательные функции для боксов
function Visual.NewLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

function Visual.Vis(lib, state)
    for i, v in pairs(lib) do
        v.Visible = state
    end
end

function Visual.Colorize(lib, color)
    for i, v in pairs(lib) do
        v.Color = color
    end
end

function Visual.GetGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

function Visual.EnsureHighlight(model, color, isObject)
    if not model then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = model
        hl.FillColor = color
        hl.FillTransparency = 0.8
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
    else
        hl.FillColor = color
        if isObject then
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        else
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        end
    end
end

function Visual.ClearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

function Visual.EnsureLabel(model, text, isGenerator, textColor)
    if not model then return end
    local lbl = model:FindFirstChild("VD_Label")
    if not lbl then
        lbl = Instance.new("BillboardGui")
        lbl.Name = "VD_Label"
        if isGenerator then
            lbl.Size = UDim2.new(0,100,0,25)
            lbl.StudsOffset = Vector3.new(0,2.5,0)
        else
            lbl.Size = UDim2.new(0,120,0,20)
            lbl.StudsOffset = Vector3.new(0,3,0)
        end
        lbl.AlwaysOnTop = true
        lbl.MaxDistance = 1000
        lbl.Parent = model
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        if isGenerator then
            textLabel.TextSize = 10
        else
            textLabel.TextSize = 10
        end
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.RichText = true
        textLabel.TextStrokeTransparency = 0.1
        textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        textLabel.Text = text
        textLabel.Parent = lbl
    else
        local textLabel = lbl:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.RichText = true
            textLabel.Text = text
            if isGenerator then
                textLabel.TextSize = 14
                lbl.StudsOffset = Vector3.new(0,2.5,0)
            else
                textLabel.TextSize = 12
                lbl.StudsOffset = Vector3.new(0,3,0)
            end
            textLabel.TextStrokeTransparency = 0.1
            textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        end
    end
end

function Visual.ClearLabel(model)
    if model and model:FindFirstChild("VD_Label") then
        pcall(function() model.VD_Label:Destroy() end)
    end
end

function Visual.EnsureGeneratorESP(generator, progress)
    if not generator then return end
    
    local function getGeneratorColor(percent)
        if percent >= 0.999 then
            return Color3.fromRGB(100, 255, 100)
        elseif percent >= 0.5 then
            local factor = (percent - 0.5) * 2
            return Color3.fromRGB(255, 200 + 55 * factor, 100 - 100 * factor)
        else
            local factor = percent * 2
            return Color3.fromRGB(255 - 155 * factor, 100 - 100 * factor, 100 - 100 * factor)
        end
    end
    
    local color = getGeneratorColor(progress)
    local percentText = Visual.ESP.showGeneratorPercent and string.format("%d%%", math.floor(progress * 100)) or ""
    
    local hl = generator:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = generator
        hl.FillColor = color
        hl.FillTransparency = 0.7
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = generator
    else
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.1
    end
    
    if Visual.ESP.showGeneratorPercent then
        Visual.EnsureLabel(generator, percentText, true, color)
    else
        Visual.ClearLabel(generator)
    end
end

function Visual.GetRole(targetPlayer)
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

function Visual.AddObjectToTrack(obj)
    local nameLower = obj.Name:lower()
    
    if nameLower:find("generator") then 
        Visual.ESP.trackedObjects[obj] = "Generators"
    elseif nameLower:find("pallet") then
        if Visual.IsValidPallet(obj) then
            Visual.ESP.trackedObjects[obj] = "Pallets"
        end
    elseif nameLower:find("gate") then 
        Visual.ESP.trackedObjects[obj] = "ExitGates"
    elseif nameLower:find("window") then 
        Visual.ESP.trackedObjects[obj] = "Windows"
    elseif nameLower:find("hook") then 
        Visual.ESP.trackedObjects[obj] = "Hooks"
    end
end

function Visual.IsValidPallet(obj)
    if obj.Name:lower():find("palletpoint") then
        return true
    end
    
    for _, child in ipairs(obj:GetChildren()) do
        if child.Name:lower():find("palletpoint") then
            return true
        end
    end
    
    if obj:IsA("Model") and obj.PrimaryPart then
        local primaryName = obj.PrimaryPart.Name:lower()
        if primaryName:find("palletpoint") or primaryName:find("pallet") then
            return true
        end
    end
    
    return false
end

function Visual.TrackObjects()
    Visual.ESP.trackedObjects = {}
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end
    
    Visual.ESP.espConnections.descendantAdded = Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end)
end

function Visual.UpdateESP()
    local currentTime = tick()
    if currentTime - Visual.ESP.lastUpdate < Visual.ESP.UPDATE_INTERVAL then return end
    Visual.ESP.lastUpdate = currentTime
    
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer ~= Nexus.Player and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local role = Visual.GetRole(targetPlayer)
                local setting = (role == "Killer") and Visual.ESP.settings.Killers or Visual.ESP.settings.Survivors
                
                if setting and setting.Enabled then
                    local color = setting.Colorpicker and setting.Colorpicker.Value or setting.Color
                    Visual.EnsureHighlight(targetPlayer.Character, color, false)
                else
                    Visual.ClearHighlight(targetPlayer.Character)
                    Visual.ClearLabel(targetPlayer.Character)
                end
            end
        end
    end
    
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            local setting = Visual.ESP.settings[typeName]
            if setting and setting.Enabled then
                if typeName == "Generators" then
                    local progress = Visual.GetGeneratorProgress(obj)
                    Visual.EnsureGeneratorESP(obj, progress)
                else
                    local color = setting.Colorpicker and setting.Colorpicker.Value or setting.Color
                    Visual.EnsureHighlight(obj, color, true)
                    Visual.ClearLabel(obj)
                end
            else
                Visual.ClearHighlight(obj)
                Visual.ClearLabel(obj)
            end
        end
    end
end

function Visual.StartESPLoop()
    Visual.ESP.espConnections.mainLoop = task.spawn(function()
        while Visual.ESP.espLoopRunning do
            Visual.UpdateESP()
            task.wait(Visual.ESP.UPDATE_INTERVAL)
        end
    end)
end

function Visual.StartESP()
    if Visual.ESP.espLoopRunning then return end
    Visual.ESP.espLoopRunning = true
    
    Visual.TrackObjects()
    Visual.StartESPLoop()
end

function Visual.StopESP()
    Visual.ESP.espLoopRunning = false
    
    Visual.ClearAllESP()
    
    for _, connection in pairs(Visual.ESP.espConnections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.ESP.espConnections = {}
end

function Visual.ClearAllESP()
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            Visual.ClearHighlight(targetPlayer.Character)
            Visual.ClearLabel(targetPlayer.Character)
        end
    end
    
    for obj, _ in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            Visual.ClearHighlight(obj)
            Visual.ClearLabel(obj)
        end
    end
end

function Visual.ToggleESPSetting(settingName, enabled)
    if Visual.ESP.settings[settingName] then
        Visual.ESP.settings[settingName].Enabled = enabled
        
        local anyEnabled = false
        for _, setting in pairs(Visual.ESP.settings) do
            if setting.Enabled then
                anyEnabled = true
                break
            end
        end
        
        if anyEnabled and not Visual.ESP.espLoopRunning then
            Visual.StartESP()
        elseif not anyEnabled and Visual.ESP.espLoopRunning then
            Visual.StopESP()
        end
    end
end

function Visual.UpdateESPColors()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP()
    end
end

function Visual.UpdateESPDisplay()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP()
    end
end

function Visual.TogglePlayerESP(enabled)
    Visual.PlayerESP.enabled = enabled
    
    if enabled then
        Visual.StartPlayerESP()
    else
        Visual.StopPlayerESP()
    end
end

function Visual.ClearPlayerESP(plr)
    local d = Visual.PlayerESP.espObjects[plr]
    if d then
        local function safeRemove(obj)
            if obj and typeof(obj) == "userdata" then
                pcall(function()
                    if obj.Remove then
                        obj:Remove()
                    elseif obj.Destroy then
                        obj:Destroy()
                    end
                    obj = nil
                end)
            end
        end
        
        -- Удаляем линии бокса
        if d.BoxLines then
            for _, line in pairs(d.BoxLines) do
                safeRemove(line)
            end
        end
        
        -- Удаляем часть для расчета
        if d.BoxPart and d.BoxPart.Parent then
            safeRemove(d.BoxPart)
        end
        
        -- Удаляем имя и хилтбар
        safeRemove(d.Name)
        safeRemove(d.HealthBg)
        safeRemove(d.HealthBar)
        safeRemove(d.HealthMask)
        safeRemove(d.HealthText)
        
        for i = 1, 24 do
            safeRemove(d["HealthStripe"..i])
        end
        
        for k, v in pairs(d) do
            if typeof(v) == "userdata" then
                d[k] = nil
            end
        end
        
        Visual.PlayerESP.espObjects[plr] = nil
    end
    
    if Visual.PlayerESP.playerConnections[plr] then
        for connName, connection in pairs(Visual.PlayerESP.playerConnections[plr]) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                pcall(function() connection:Disconnect() end)
            end
            Visual.PlayerESP.playerConnections[plr][connName] = nil
        end
        Visual.PlayerESP.playerConnections[plr] = nil
    end
end

function Visual.ForceCleanupDrawings()
    for plr, d in pairs(Visual.PlayerESP.espObjects) do
        if d then
            local drawingObjects = {
                d.Name, d.HealthBg, d.HealthBar, d.HealthMask, d.HealthText
            }
            
            for _, obj in ipairs(drawingObjects) do
                if obj and typeof(obj) == "userdata" then
                    pcall(function() 
                        obj.Visible = false
                        task.wait()
                        if obj.Remove then
                            obj:Remove()
                        end
                    end)
                end
            end
            
            -- Удаляем линии бокса
            if d.BoxLines then
                for _, line in pairs(d.BoxLines) do
                    if line and typeof(line) == "userdata" then
                        pcall(function() 
                            line.Visible = false
                            if line.Remove then
                                line:Remove()
                            end
                        end)
                    end
                end
            end
            
            for i = 1, 24 do
                local stripe = d["HealthStripe"..i]
                if stripe and typeof(stripe) == "userdata" then
                    pcall(function() 
                        stripe.Visible = false
                        if stripe.Remove then
                            stripe:Remove()
                        end
                    end)
                end
            end
            
            -- Удаляем часть
            if d.BoxPart and d.BoxPart.Parent then
                pcall(function() d.BoxPart:Destroy() end)
            end
        end
    end
    
    Visual.PlayerESP.espObjects = {}
end

function Visual.CreatePlayerESP(plr)
    if Visual.PlayerESP.espObjects[plr] then
        Visual.ClearPlayerESP(plr)
        task.wait(0.05)
    end
    
    local settings = Visual.PlayerESP.settings
    local colorMap = Visual.PlayerESP.colorMap
    
    local function create(tp, props)
        local o = Drawing.new(tp)
        for i,v in pairs(props) do o[i]=v end
        return o
    end
    
    local d = {
        Name = nil,
        HealthBg = nil,
        HealthBar = nil,
        HealthMask = nil,
        HealthText = nil,
        BoxLines = {},
        BoxPart = nil
    }
    
    -- Создаем линии для бокса
    local boxColor = settings.Box_Color
    local boxThickness = settings.Box_Thickness
    
    d.BoxLines = {
        TL1 = Visual.NewLine(boxColor, boxThickness),
        TL2 = Visual.NewLine(boxColor, boxThickness),
        TR1 = Visual.NewLine(boxColor, boxThickness),
        TR2 = Visual.NewLine(boxColor, boxThickness),
        BL1 = Visual.NewLine(boxColor, boxThickness),
        BL2 = Visual.NewLine(boxColor, boxThickness),
        BR1 = Visual.NewLine(boxColor, boxThickness),
        BR2 = Visual.NewLine(boxColor, boxThickness)
    }
    
    -- Создаем часть для расчета
    d.BoxPart = Instance.new("Part")
    d.BoxPart.Parent = Nexus.Services.Workspace
    d.BoxPart.Transparency = 1
    d.BoxPart.CanCollide = false
    d.BoxPart.Size = Vector3.new(1, 1, 1)
    d.BoxPart.Position = Vector3.new(0, 0, 0)
    
    -- Создаем полоски для хилтбара
    for i=1,24 do
        d["HealthStripe"..i] = Drawing.new("Square")
        d["HealthStripe"..i].Filled = true
        d["HealthStripe"..i].Visible = false
    end
    
    -- Создаем имя
    d.Name = create("Text",{
        Size = 20,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    -- Создаем хилтбар
    d.HealthBg = Drawing.new("Square")
    d.HealthBg.Visible = false
    d.HealthBg.Filled = true
    d.HealthBg.Color = Color3.new(0,0,0)
    d.HealthBg.Transparency = 1

    d.HealthBar = Drawing.new("Square")
    d.HealthBar.Visible = false
    d.HealthBar.Filled = true
    d.HealthBar.Transparency = 1

    d.HealthMask = Drawing.new("Square")
    d.HealthMask.Visible = false
    d.HealthMask.Filled = true
    d.HealthMask.Color = Color3.new(0,0,0)
    d.HealthMask.Transparency = 0.3

    d.HealthText = create("Text",{
        Size = 14,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    Visual.PlayerESP.espObjects[plr] = d
    
    if not Visual.PlayerESP.playerConnections[plr] then
        Visual.PlayerESP.playerConnections[plr] = {}
    end
    
    return d
end

function Visual.SetupPlayerESP(plr)
    if plr == Nexus.Player then return end
    
    Visual.CreatePlayerESP(plr)
    
    local charAddedConnection = plr.CharacterAdded:Connect(function(char)
        wait(0.5)
        
        if not Visual.PlayerESP.espObjects[plr] then
            Visual.CreatePlayerESP(plr)
        end
        
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            if Visual.PlayerESP.playerConnections[plr] then
                if Visual.PlayerESP.playerConnections[plr].died then
                    Visual.PlayerESP.playerConnections[plr].died:Disconnect()
                end
                
                Visual.PlayerESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                    Visual.ClearPlayerESP(plr)
                end)
            end
        end
    end)
    
    local charRemovingConnection = plr.CharacterRemoving:Connect(function()
        Visual.ClearPlayerESP(plr)
    end)
    
    if Visual.PlayerESP.playerConnections[plr] then
        Visual.PlayerESP.playerConnections[plr].charAdded = charAddedConnection
        Visual.PlayerESP.playerConnections[plr].charRemoving = charRemovingConnection
    end
    
    if plr.Character then
        task.spawn(function()
            local char = plr.Character
            wait(0.5)
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if Visual.PlayerESP.playerConnections[plr] then
                    Visual.PlayerESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                        Visual.ClearPlayerESP(plr)
                    end)
                end
            end
        end)
    end
end

function Visual.CleanupPlayerESP(plr)
    Visual.ClearPlayerESP(plr)
end

function Visual.GetHealthGradientColor(y, h)
    local colorMap = Visual.PlayerESP.colorMap
    
    local t = 1 - (y / math.max(h, 1))
    if t >= 0.5 then
        local s = (t - 0.5) * 2
        local midColor = colorMap.DarkOrange
        local topColor = colorMap.DarkGreen
        return midColor:Lerp(topColor, s)
    else
        local s = t * 2
        local bottomColor = colorMap.DarkRed
        local midColor = colorMap.DarkOrange
        return bottomColor:Lerp(midColor, s)
    end
end

function Visual.UpdatePlayerESP()
    if not Visual.PlayerESP.enabled then return end
    
    local Camera = Nexus.Camera
    local camPos = Camera.CFrame.Position
    
    for plr, d in pairs(Visual.PlayerESP.espObjects) do
        if not plr or not plr.Parent then
            Visual.ClearPlayerESP(plr)
            continue
        end
        
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health <= 0 then
                -- Скрываем все элементы
                Visual.Vis(d.BoxLines, false)
                if d.Name then d.Name.Visible = false end
                if d.HealthBg then d.HealthBg.Visible = false end
                if d.HealthText then d.HealthText.Visible = false end
                for i=1,24 do
                    if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                end
                continue
            end
            
            local root = char.HumanoidRootPart
            local head = char.Head

            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

            if onScreen then
                local rawHeight = footPos.Y - headPos.Y
                local height = rawHeight
                local x = headPos.X
                local y = headPos.Y
                
                -- Обновляем бокс
                if d.BoxPart and d.BoxLines then
                    -- Обновляем размер и позицию части для расчета
                    d.BoxPart.Size = Vector3.new(root.Size.X, root.Size.Y * 1.5, root.Size.Z)
                    d.BoxPart.CFrame = CFrame.new(root.CFrame.Position, Camera.CFrame.Position)
                    
                    local SizeX = d.BoxPart.Size.X
                    local SizeY = d.BoxPart.Size.Y
                    
                    -- Рассчитываем углы бокса
                    local TL = Camera:WorldToViewportPoint((d.BoxPart.CFrame * CFrame.new(SizeX, SizeY, 0)).p)
                    local TR = Camera:WorldToViewportPoint((d.BoxPart.CFrame * CFrame.new(-SizeX, SizeY, 0)).p)
                    local BL = Camera:WorldToViewportPoint((d.BoxPart.CFrame * CFrame.new(SizeX, -SizeY, 0)).p)
                    local BR = Camera:WorldToViewportPoint((d.BoxPart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).p)
                    
                    -- Определяем цвет бокса в зависимости от команды
                    local boxColor = Visual.PlayerESP.settings.Box_Color
                    if Visual.PlayerESP.settings.Team_Check then
                        if plr.TeamColor == Nexus.Player.TeamColor then
                            boxColor = Color3.fromRGB(0, 255, 0)
                        else 
                            boxColor = Color3.fromRGB(255, 0, 0)
                        end
                    end
                    
                    if Visual.PlayerESP.settings.Team_Color then
                        boxColor = plr.TeamColor.Color
                    end
                    
                    -- Обновляем цвет линий
                    Visual.Colorize(d.BoxLines, boxColor)
                    
                    local ratio = (Camera.CFrame.p - root.Position).magnitude
                    local offset = math.clamp(1/ratio*750, 2, 300)
                    
                    -- Обновляем позиции линий
                    d.BoxLines.TL1.From = Vector2.new(TL.X, TL.Y)
                    d.BoxLines.TL1.To = Vector2.new(TL.X + offset, TL.Y)
                    d.BoxLines.TL2.From = Vector2.new(TL.X, TL.Y)
                    d.BoxLines.TL2.To = Vector2.new(TL.X, TL.Y + offset)

                    d.BoxLines.TR1.From = Vector2.new(TR.X, TR.Y)
                    d.BoxLines.TR1.To = Vector2.new(TR.X - offset, TR.Y)
                    d.BoxLines.TR2.From = Vector2.new(TR.X, TR.Y)
                    d.BoxLines.TR2.To = Vector2.new(TR.X, TR.Y + offset)

                    d.BoxLines.BL1.From = Vector2.new(BL.X, BL.Y)
                    d.BoxLines.BL1.To = Vector2.new(BL.X + offset, BL.Y)
                    d.BoxLines.BL2.From = Vector2.new(BL.X, BL.Y)
                    d.BoxLines.BL2.To = Vector2.new(BL.X, BL.Y - offset)

                    d.BoxLines.BR1.From = Vector2.new(BR.X, BR.Y)
                    d.BoxLines.BR1.To = Vector2.new(BR.X - offset, BR.Y)
                    d.BoxLines.BR2.From = Vector2.new(BR.X, BR.Y)
                    d.BoxLines.BR2.To = Vector2.new(BR.X, BR.Y - offset)
                    
                    -- Показываем линии
                    Visual.Vis(d.BoxLines, true)
                    
                    -- Обновляем толщину
                    if Visual.PlayerESP.settings.Autothickness then
                        local distance = (Nexus.Player.Character.HumanoidRootPart.Position - d.BoxPart.Position).magnitude
                        local value = math.clamp(1/distance*100, 1, 4)
                        for _, line in pairs(d.BoxLines) do
                            line.Thickness = value
                        end
                    else 
                        for _, line in pairs(d.BoxLines) do
                            line.Thickness = Visual.PlayerESP.settings.Box_Thickness
                        end
                    end
                    
                    -- Позиция для имени (вверху по центру бокса)
                    local nameY = math.min(TL.Y, TR.Y) - 25
                    local nameX = (TL.X + TR.X) / 2
                    
                    if d.Name and Visual.PlayerESP.settings.Show_Names then
                        d.Name.Text = plr.Name
                        d.Name.Size = 20
                        d.Name.Position = Vector2.new(nameX, nameY)
                        d.Name.Visible = true
                    elseif d.Name then
                        d.Name.Visible = false
                    end
                    
                    -- Хилтбар (слева от бокса, той же высоты)
                    if Visual.PlayerESP.settings.Show_HealthBar then
                        local leftmostX = math.min(TL.X, BL.X) - 20  -- Левее левой стороны бокса
                        local barY = math.min(TL.Y, TR.Y)
                        local barHeight = math.max(BL.Y, BR.Y) - barY
                        
                        local HEALTH_STRIPES = 24
                        local hpPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        
                        -- Обновляем полоски хилтбара
                        for i = 1, HEALTH_STRIPES do
                            local stripeY = barY + barHeight * (i - 1) / HEALTH_STRIPES
                            local stripeH = barHeight / HEALTH_STRIPES
                            local stripeColor = Visual.GetHealthGradientColor(stripeY - barY, barHeight)
                            
                            if not d["HealthStripe"..i] then
                                d["HealthStripe"..i] = Drawing.new("Square")
                                d["HealthStripe"..i].Filled = true
                            end
                            
                            local stripe = d["HealthStripe"..i]
                            stripe.Color = stripeColor
                            stripe.Position = Vector2.new(leftmostX, stripeY)
                            stripe.Size = Vector2.new(10, stripeH)  -- Ширина хилтбара 10 пикселей
                            stripe.Visible = (i - 1) / HEALTH_STRIPES < hpPerc
                            stripe.Transparency = 1
                        end
                        
                        -- Текст здоровья
                        if d.HealthText then
                            d.HealthText.Text = tostring(math.floor(hum.Health))
                            d.HealthText.Size = 14
                            d.HealthText.Position = Vector2.new(leftmostX - 20, barY + barHeight / 2)
                            d.HealthText.Visible = true
                        end
                    else
                        -- Скрываем хилтбар, если выключен
                        for i = 1, 24 do
                            if d["HealthStripe"..i] then
                                d["HealthStripe"..i].Visible = false
                            end
                        end
                        if d.HealthText then
                            d.HealthText.Visible = false
                        end
                    end
                end
            else
                -- Игрок не на экране - скрываем все
                if d.BoxLines then
                    Visual.Vis(d.BoxLines, false)
                end
                if d.Name then d.Name.Visible = false end
                if d.HealthBg then d.HealthBg.Visible = false end
                if d.HealthText then d.HealthText.Visible = false end
                for i = 1, 24 do
                    if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                end
            end
        else
            Visual.ClearPlayerESP(plr)
        end
    end
end

function Visual.StartPlayerESP()
    Nexus.Services.Players.PlayerAdded:Connect(function(plr)
        Visual.SetupPlayerESP(plr)
    end)
    
    Nexus.Services.Players.PlayerRemoving:Connect(function(plr)
        Visual.CleanupPlayerESP(plr)
    end)
    
    for _, plr in pairs(Nexus.Services.Players:GetPlayers()) do
        if plr ~= Nexus.Player then
            Visual.SetupPlayerESP(plr)
        end
    end
    
    Visual.PlayerESP.connections.renderStepped = Nexus.Services.RunService.RenderStepped:Connect(function()
        Visual.UpdatePlayerESP()
    end)
end

function Visual.StopPlayerESP()
    if Visual.PlayerESP.connections.renderStepped then
        pcall(function() 
            Visual.PlayerESP.connections.renderStepped:Disconnect() 
        end)
        Visual.PlayerESP.connections.renderStepped = nil
    end
    
    local playersToClear = {}
    for plr, _ in pairs(Visual.PlayerESP.espObjects) do
        table.insert(playersToClear, plr)
    end
    
    for _, plr in ipairs(playersToClear) do
        Visual.ClearPlayerESP(plr)
    end
    
    table.clear(Visual.PlayerESP.espObjects)
    table.clear(Visual.PlayerESP.playerConnections)
    table.clear(Visual.PlayerESP.connections)
end

function Visual.ToggleNoShadow(enabled)
    Visual.Effects.noShadowEnabled = enabled
    if enabled then
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = false 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = false
    else
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = true 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = true
    end
end

function Visual.ToggleNoFog(enabled)
    Visual.Effects.noFogEnabled = enabled
    
    if enabled then
        pcall(function()
            local lighting = Nexus.Services.Lighting
            
            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("Atmosphere") or 
                   effect.Name:lower():find("fog") or 
                   effect.Name:lower():find("bloom") or
                   effect.Name:lower():find("blur") or
                   effect.Name:lower():find("color") then
                    effect:Destroy()
                end
            end
            
            local map = Nexus.Services.Workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Atmosphere") or 
                       obj:IsA("BloomEffect") or 
                       obj:IsA("BlurEffect") or 
                       obj:IsA("ColorCorrectionEffect") or
                       obj.Name:lower():find("fog") then
                        obj:Destroy()
                    end
                end
            end
            
            lighting.FogEnd = 10000000
            lighting.FogStart = 0
            lighting.FogDensity = 0
            lighting.GlobalShadows = true
            
            if Visual.ESP.espConnections.noFog then
                Visual.ESP.espConnections.noFog:Disconnect()
            end
            
            Visual.ESP.espConnections.noFog = Nexus.Services.RunService.Heartbeat:Connect(function()
                if Visual.Effects.noFogEnabled then
                    lighting.FogEnd = 10000000
                    lighting.FogStart = 0
                    lighting.FogDensity = 0
                end
            end)
        end)
    else
        if Visual.ESP.espConnections.noFog then
            Visual.ESP.espConnections.noFog:Disconnect()
            Visual.ESP.espConnections.noFog = nil
        end
    end
end

function Visual.ToggleFullBright(enabled)
    Visual.Effects.fullbrightEnabled = enabled
    Nexus.States.fullbrightEnabled = enabled
    
    if enabled then
        Nexus.Services.Lighting.GlobalShadows = false
        Nexus.Services.Lighting.FogEnd = 100000
        Nexus.Services.Lighting.Brightness = 2
        Nexus.Services.Lighting.ClockTime = 14
    else
        Nexus.Services.Lighting.GlobalShadows = true
        Nexus.Services.Lighting.FogEnd = 1000
        Nexus.Services.Lighting.Brightness = 1
    end
end

function Visual.ToggleTimeChanger(enabled)
    Visual.Effects.timeChangerEnabled = enabled
    
    if enabled then
        if not Visual.Effects.originalClockTime then
            Visual.Effects.originalClockTime = Nexus.Services.Lighting.ClockTime
        end
        
        local currentTime = Nexus.Options.TimeValue.Value
        Nexus.Services.Lighting.ClockTime = currentTime
    else
        if Visual.Effects.originalClockTime then
            Nexus.Services.Lighting.ClockTime = Visual.Effects.originalClockTime
        end
    end
end

function Visual.SetTime(time)
    Nexus.Services.Lighting.ClockTime = time
end

function Visual.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    local NoShadowToggle = Tabs.Visual:AddToggle("NoShadow", {
        Title = "No Shadow", 
        Description = "", 
        Default = false
    })
    NoShadowToggle:OnChanged(function(v) Visual.ToggleNoShadow(v) end)

    local NoFogToggle = Tabs.Visual:AddToggle("NoFog", {
        Title = "No Fog", 
        Description = "", 
        Default = false
    })
    
    NoFogToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            Visual.ToggleNoFog(v)
        end)
    end)

    local FullBrightToggle = Tabs.Visual:AddToggle("FullBright", {
        Title = "FullBright", 
        Description = "", 
        Default = false
    })
    FullBrightToggle:OnChanged(function(v) Visual.ToggleFullBright(v) end)

    local TimeChangerToggle = Tabs.Visual:AddToggle("TimeChanger", {
        Title = "Time Changer", 
        Description = "", 
        Default = false
    })

    local TimeSlider = Tabs.Visual:AddSlider("TimeValue", {
        Title = "Time of Day", 
        Description = "",
        Default = 14,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(value)
            if Options.TimeChanger and Options.TimeChanger.Value then
                Visual.SetTime(value)
            end
        end
    })

    TimeChangerToggle:OnChanged(function(v)
        Visual.ToggleTimeChanger(v)
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if Options.TimeChanger and Options.TimeChanger.Value then
                local currentTime = Options.TimeValue.Value
                Visual.SetTime(currentTime)
            end
        end
    end)

    Tabs.Visual:AddSection("ESP Settings")

    local ShowGeneratorPercentToggle = Tabs.Visual:AddToggle("ESPShowGenPercent", {
        Title = "Show Generator %", 
        Description = "Toggle display of generator percentages", 
        Default = true
    })
    ShowGeneratorPercentToggle:OnChanged(function(v)
        Visual.ESP.showGeneratorPercent = v
        Visual.UpdateESPDisplay()
    end)

    local ESPSurvivorsToggle = Tabs.Visual:AddToggle("ESPSurvivors", {
        Title = "Survivors ESP", 
        Description = "", 
        Default = false
    })
    ESPSurvivorsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Survivors", v)
    end)

    local SurvivorColorpicker = Tabs.Visual:AddColorpicker("SurvivorColorpicker", {
        Title = "Survivor Color",
        Default = Color3.fromRGB(100, 255, 100)
    })
    SurvivorColorpicker:OnChanged(function()
        Visual.ESP.settings.Survivors.Color = SurvivorColorpicker.Value
        Visual.UpdateESPColors()
    end)
    SurvivorColorpicker:SetValueRGB(Color3.fromRGB(100, 255, 100))

    local ESPKillersToggle = Tabs.Visual:AddToggle("ESPKillers", {
        Title = "Killers ESP", 
        Description = "", 
        Default = false
    })
    ESPKillersToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Killers", v)
    end)

    local KillerColorpicker = Tabs.Visual:AddColorpicker("KillerColorpicker", {
        Title = "Killer Color",
        Default = Color3.fromRGB(255, 100, 100)
    })
    KillerColorpicker:OnChanged(function()
        Visual.ESP.settings.Killers.Color = KillerColorpicker.Value
        Visual.UpdateESPColors()
    end)
    KillerColorpicker:SetValueRGB(Color3.fromRGB(255, 100, 100))

    local ESPHooksToggle = Tabs.Visual:AddToggle("ESPHooks", {
        Title = "Hooks ESP", 
        Description = "", 
        Default = false
    })
    ESPHooksToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Hooks", v)
    end)

    local HookColorpicker = Tabs.Visual:AddColorpicker("HookColorpicker", {
        Title = "Hook Color",
        Default = Color3.fromRGB(100, 50, 150)
    })
    HookColorpicker:OnChanged(function()
        Visual.ESP.settings.Hooks.Color = HookColorpicker.Value
        Visual.UpdateESPColors()
    end)
    HookColorpicker:SetValueRGB(Color3.fromRGB(100, 50, 150))

    local ESPGeneratorsToggle = Tabs.Visual:AddToggle("ESPGenerators", {
        Title = "Generators ESP", 
        Description = "", 
        Default = false
    })
    ESPGeneratorsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Generators", v)
    end)

    local ESPPalletsToggle = Tabs.Visual:AddToggle("ESPPallets", {
        Title = "Pallets ESP", 
        Description = "", 
        Default = false
    })
    ESPPalletsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Pallets", v)
    end)

    local PalletColorpicker = Tabs.Visual:AddColorpicker("PalletColorpicker", {
        Title = "Pallet Color",
        Default = Color3.fromRGB(120, 80, 40)
    })
    PalletColorpicker:OnChanged(function()
        Visual.ESP.settings.Pallets.Color = PalletColorpicker.Value
        Visual.UpdateESPColors()
    end)
    PalletColorpicker:SetValueRGB(Color3.fromRGB(120, 80, 40))

    local ESPGatesToggle = Tabs.Visual:AddToggle("ESPGates", {
        Title = "Exit Gates ESP", 
        Description = "", 
        Default = false
    })
    ESPGatesToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("ExitGates", v)
    end)

    local GateColorpicker = Tabs.Visual:AddColorpicker("GateColorpicker", {
        Title = "Gate Color",
        Default = Color3.fromRGB(200, 200, 100)
    })
    GateColorpicker:OnChanged(function()
        Visual.ESP.settings.ExitGates.Color = GateColorpicker.Value
        Visual.UpdateESPColors()
    end)
    GateColorpicker:SetValueRGB(Color3.fromRGB(200, 200, 100))

    local ESPWindowsToggle = Tabs.Visual:AddToggle("ESPWindows", {
        Title = "Windows ESP", 
        Description = "", 
        Default = false
    })
    ESPWindowsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Windows", v)
    end)

    local WindowColorpicker = Tabs.Visual:AddColorpicker("WindowColorpicker", {
        Title = "Window Color",
        Default = Color3.fromRGB(100, 200, 200)
    })
    WindowColorpicker:OnChanged(function()
        Visual.ESP.settings.Windows.Color = WindowColorpicker.Value
        Visual.UpdateESPColors()
    end)
    WindowColorpicker:SetValueRGB(Color3.fromRGB(100, 200, 200))

    Visual.ESP.settings.Survivors.Colorpicker = SurvivorColorpicker
    Visual.ESP.settings.Killers.Colorpicker = KillerColorpicker
    Visual.ESP.settings.Hooks.Colorpicker = HookColorpicker
    Visual.ESP.settings.Pallets.Colorpicker = PalletColorpicker
    Visual.ESP.settings.ExitGates.Colorpicker = GateColorpicker
    Visual.ESP.settings.Windows.Colorpicker = WindowColorpicker

    Tabs.Visual:AddSection("Player ESP Settings")

    local PlayerESPToggle = Tabs.Visual:AddToggle("PlayerESP", {
        Title = "Player ESP", 
        Description = "Enable player ESP with boxes, names and healthbar", 
        Default = false
    })
    PlayerESPToggle:OnChanged(function(v)
        Visual.TogglePlayerESP(v)
    end)

    local ShowNamesToggle = Tabs.Visual:AddToggle("ESPShowNames", {
        Title = "Show Player Names", 
        Description = "Show/hide player names above boxes", 
        Default = true
    })
    ShowNamesToggle:OnChanged(function(v)
        Visual.PlayerESP.settings.Show_Names = v
    end)

    local ShowHealthBarToggle = Tabs.Visual:AddToggle("ESPShowHealthBar", {
        Title = "Show Health Bar", 
        Description = "Show/hide health bar on the left side of boxes", 
        Default = true
    })
    ShowHealthBarToggle:OnChanged(function(v)
        Visual.PlayerESP.settings.Show_HealthBar = v
    end)

    local BoxColorpicker = Tabs.Visual:AddColorpicker("BoxColorpicker", {
        Title = "Box Color",
        Default = Color3.fromRGB(255, 0, 0)
    })
    BoxColorpicker:OnChanged(function()
        Visual.PlayerESP.settings.Box_Color = BoxColorpicker.Value
    end)
    BoxColorpicker:SetValueRGB(Color3.fromRGB(255, 0, 0))

    local BoxThicknessSlider = Tabs.Visual:AddSlider("BoxThickness", {
        Title = "Box Thickness", 
        Description = "Thickness of box lines",
        Default = 2,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Callback = function(value)
            Visual.PlayerESP.settings.Box_Thickness = value
        end
    })

    local TeamCheckToggle = Tabs.Visual:AddToggle("TeamCheck", {
        Title = "Team Check", 
        Description = "Green for teammates, red for enemies", 
        Default = false
    })
    TeamCheckToggle:OnChanged(function(v)
        Visual.PlayerESP.settings.Team_Check = v
    end)

    local TeamColorToggle = Tabs.Visual:AddToggle("TeamColor", {
        Title = "Team Color", 
        Description = "Use team color for boxes", 
        Default = false
    })
    TeamColorToggle:OnChanged(function(v)
        Visual.PlayerESP.settings.Team_Color = v
    end)

    local AutoThicknessToggle = Tabs.Visual:AddToggle("AutoThickness", {
        Title = "Auto Thickness", 
        Description = "Automatically adjust box thickness based on distance", 
        Default = true
    })
    AutoThicknessToggle:OnChanged(function(v)
        Visual.PlayerESP.settings.Autothickness = v
    end)

    task.spawn(function()
        task.wait(2)
        for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                Visual.AddObjectToTrack(obj)
            end
        end
        
        Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("Model") then
                Visual.AddObjectToTrack(obj)
            end
        end)
    end)
end

function Visual.Cleanup()
    Visual.StopESP()
    Visual.StopPlayerESP()
    
    Visual.ForceCleanupDrawings()
    
    Visual.ToggleNoShadow(false)
    Visual.ToggleNoFog(false)
    Visual.ToggleFullBright(false)
    Visual.ToggleTimeChanger(false)
    
    for _, connection in pairs(Visual.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.Connections = {}
    
    for _, connection in pairs(Visual.ESP.espConnections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.ESP.espConnections = {}
    
    for _, connection in pairs(Visual.PlayerESP.connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.PlayerESP.connections = {}
    
    task.wait(0.1)
    pcall(function() game:GetService("RunService"):RenderStepped():Wait() end)
    collectgarbage()
end

return Visual
