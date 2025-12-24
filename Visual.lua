local Nexus = _G.Nexus

local Visual = {
    Connections = {},
    ESP = {
        lastUpdate = 0,
        UPDATE_INTERVAL = 0.10,
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
    AdvancedESP = {
        settings = {
            enabled = false,
            name = true,
            distance = true,
            healthbar = true,
            box = true,
            boxType = "full",
            bones = true,
            boneColorName = "White",
            tracers = true,
            tracerColorName = "White",
            scale = 1.5,
            healthBarTopColorName = "DarkGreen",
            healthBarMidColorName = "DarkOrange",
            healthBarBottomColorName = "DarkRed",
            stateColorName = "Orange",
            boxOutline = true,
            boxOutlineColorName = "Black",
            boxOutlineThickness = 0.4,
            boxColorName = "White",
            boxFill = true,
            boxFillColorName = "White",
            boxFillTransparency = 0.9,
            healthBarLeftOffset = 10
        },
        colorMap = {
            Red = Color3.fromRGB(255,0,0),
            DarkRed = Color3.fromRGB(100,0,0),
            Green = Color3.fromRGB(0,255,0),
            DarkGreen = Color3.fromRGB(0,80,0),
            Blue = Color3.fromRGB(0,0,255),
            LightBlue = Color3.fromRGB(200,200,255),
            Yellow = Color3.fromRGB(255,255,0),
            Orange = Color3.fromRGB(255,165,0),
            DarkOrange = Color3.fromRGB(140,70,0),
            Purple = Color3.fromRGB(128,0,128),
            White = Color3.fromRGB(255,255,255),
            Black = Color3.fromRGB(0,0,0)
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

function Visual.ToggleAdvancedESP(enabled)
    Visual.AdvancedESP.settings.enabled = enabled
    
    if enabled then
        Visual.StartAdvancedESP()
    else
        Visual.StopAdvancedESP()
    end
end

function Visual.ClearAdvancedESP(plr)
    local d = Visual.AdvancedESP.espObjects[plr]
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
        
        safeRemove(d.BoxFill)
        safeRemove(d.Name)
        safeRemove(d.Distance)
        safeRemove(d.Tracer)
        safeRemove(d.HealthBg)
        safeRemove(d.HealthBar)
        safeRemove(d.HealthMask)
        safeRemove(d.HealthText)
        safeRemove(d.Box)
        safeRemove(d.BoxOutline)
        
        for i = 1, 24 do
            safeRemove(d["HealthStripe"..i])
        end
        
        if d.Bones then
            for _, bone in ipairs(d.Bones) do
                safeRemove(bone)
            end
        end
        
        for k, v in pairs(d) do
            if typeof(v) == "userdata" then
                d[k] = nil
            end
        end
        
        Visual.AdvancedESP.espObjects[plr] = nil
    end
    
    if Visual.AdvancedESP.playerConnections[plr] then
        for connName, connection in pairs(Visual.AdvancedESP.playerConnections[plr]) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                pcall(function() connection:Disconnect() end)
            end
            Visual.AdvancedESP.playerConnections[plr][connName] = nil
        end
        Visual.AdvancedESP.playerConnections[plr] = nil
    end
end

function Visual.ForceCleanupDrawings()
    for plr, d in pairs(Visual.AdvancedESP.espObjects) do
        if d then
            local drawingObjects = {
                d.BoxFill, d.Name, d.Distance, d.Tracer, d.HealthBg, 
                d.HealthBar, d.HealthMask, d.HealthText, d.Box, d.BoxOutline
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
            
            if d.Bones then
                for _, bone in ipairs(d.Bones) do
                    if bone and typeof(bone) == "userdata" then
                        pcall(function() 
                            bone.Visible = false
                            if bone.Remove then
                                bone:Remove()
                            end
                        end)
                    end
                end
            end
        end
    end
    
    Visual.AdvancedESP.espObjects = {}
end

function Visual.CreateAdvancedESP(plr)
    if Visual.AdvancedESP.espObjects[plr] then
        Visual.ClearAdvancedESP(plr)
        task.wait(0.05)
    end
    
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local boneColor = colorMap[settings.boneColorName] or colorMap.White
    local tracerColor = colorMap[settings.tracerColorName] or colorMap.White
    local boxColor = colorMap[settings.boxColorName] or colorMap.White
    local boxOutlineColor = colorMap[settings.boxOutlineColorName] or colorMap.Black
    local boxFillColor = colorMap[settings.boxFillColorName] or colorMap.White
    
    local function create(tp, props)
        local o = Drawing.new(tp)
        for i,v in pairs(props) do o[i]=v end
        return o
    end
    
    local d = {
        Bones = {},
        BoxFill = nil,
        Name = nil,
        Distance = nil,
        Tracer = nil,
        HealthBg = nil,
        HealthBar = nil,
        HealthMask = nil,
        HealthText = nil,
        Box = nil,
        BoxOutline = nil
    }
    
    d.BoxFill = create("Square",{
        Thickness = 0,
        Color = boxFillColor,
        Visible = false,
        Filled = true,
        Transparency = 1 - (settings.boxFillTransparency or 0.9)
    })
    
    d.Name = create("Text",{
        Size = 20,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    d.Distance = create("Text",{
        Size = 16,
        Center = true,
        Outline = true,
        Color = Color3.new(0.8,0.8,0.8),
        Visible = false
    })
    
    d.Tracer = create("Line",{
        Thickness = 1.5,
        Color = tracerColor,
        Visible = false
    })
    
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
    
    d.Box = create("Square", {
        Thickness = 1.7,
        Color = boxColor,
        Visible = false,
        Filled = false
    })
    
    d.BoxOutline = create("Square", {
        Thickness = 1.7 + (settings.boxOutlineThickness or 0.4) * 2,
        Color = boxOutlineColor,
        Visible = false,
        Filled = false
    })
    
    for i=1,14 do
        d.Bones[i] = create("Line", {
            Thickness = 1.5,
            Color = boneColor,
            Visible = false
        })
    end
    
    Visual.AdvancedESP.espObjects[plr] = d
    
    if not Visual.AdvancedESP.playerConnections[plr] then
        Visual.AdvancedESP.playerConnections[plr] = {}
    end
    
    return d
end

function Visual.SetupPlayerAdvancedESP(plr)
    if plr == Nexus.Player then return end
    
    Visual.CreateAdvancedESP(plr)
    
    local charAddedConnection = plr.CharacterAdded:Connect(function(char)
        wait(0.5)
        
        if not Visual.AdvancedESP.espObjects[plr] then
            Visual.CreateAdvancedESP(plr)
        end
        
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            if Visual.AdvancedESP.playerConnections[plr] then
                if Visual.AdvancedESP.playerConnections[plr].died then
                    Visual.AdvancedESP.playerConnections[plr].died:Disconnect()
                end
                
                Visual.AdvancedESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                    Visual.ClearAdvancedESP(plr)
                end)
            end
        end
    end)
    
    local charRemovingConnection = plr.CharacterRemoving:Connect(function()
        Visual.ClearAdvancedESP(plr)
    end)
    
    if Visual.AdvancedESP.playerConnections[plr] then
        Visual.AdvancedESP.playerConnections[plr].charAdded = charAddedConnection
        Visual.AdvancedESP.playerConnections[plr].charRemoving = charRemovingConnection
    end
    
    if plr.Character then
        task.spawn(function()
            local char = plr.Character
            wait(0.5)
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if Visual.AdvancedESP.playerConnections[plr] then
                    Visual.AdvancedESP.playerConnections[plr].died = humanoid.Died:Connect(function()
                        Visual.ClearAdvancedESP(plr)
                    end)
                end
            end
        end)
    end
end

function Visual.CleanupPlayerAdvancedESP(plr)
    Visual.ClearAdvancedESP(plr)
end

function Visual.GetHealthGradientColor(y, h)
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local t = 1 - (y / math.max(h, 1))
    if t >= 0.5 then
        local s = (t - 0.5) * 2
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        local topColor = colorMap[settings.healthBarTopColorName] or colorMap.DarkGreen
        return midColor:Lerp(topColor, s)
    else
        local s = t * 2
        local bottomColor = colorMap[settings.healthBarBottomColorName] or colorMap.DarkRed
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        return bottomColor:Lerp(midColor, s)
    end
end

function Visual.IsR6(char)
    return char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso")
end

function Visual.UpdateAdvancedESP()
    local settings = Visual.AdvancedESP.settings
    if not settings.enabled then return end
    
    local Camera = Nexus.Camera
    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    for plr, d in pairs(Visual.AdvancedESP.espObjects) do
        if not plr or not plr.Parent then
            Visual.ClearAdvancedESP(plr)
            continue
        end
        
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health <= 0 then
                if d.BoxFill then d.BoxFill.Visible = false end
                if d.Box then d.Box.Visible = false end
                if d.BoxOutline then d.BoxOutline.Visible = false end
                if d.Name then d.Name.Visible = false end
                if d.Distance then d.Distance.Visible = false end
                if d.HealthBg then d.HealthBg.Visible = false end
                if d.HealthText then d.HealthText.Visible = false end
                for i=1,24 do
                    if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                end
                if d.Bones then for _,line in ipairs(d.Bones) do line.Visible = false end end
                if d.Tracer then d.Tracer.Visible = false end
                continue
            end
            
            local root = char.HumanoidRootPart
            local head = char.Head

            local function screenPosOrNil(part)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then 
                        return Vector2.new(pos.X, pos.Y) 
                    end
                end
                return nil
            end

            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

            if onScreen then
                local rawHeight = footPos.Y - headPos.Y
                local height = rawHeight * settings.scale
                local width = (height / 2) * settings.scale
                local x = headPos.X - width / 2
                local y = headPos.Y - (height - rawHeight) / 2

                if d.BoxFill then
                    d.BoxFill.Position = Vector2.new(x, y)
                    d.BoxFill.Size = Vector2.new(width, height)
                    d.BoxFill.Color = Visual.AdvancedESP.colorMap[settings.boxFillColorName] or Visual.AdvancedESP.colorMap.White
                    d.BoxFill.Filled = true
                    d.BoxFill.Transparency = 1 - (settings.boxFillTransparency or 0.9)
                    d.BoxFill.Visible = settings.boxFill
                end

                if d.Box then
                    d.Box.Position = Vector2.new(x, y)
                    d.Box.Size = Vector2.new(width, height)
                    d.Box.Color = Visual.AdvancedESP.colorMap[settings.boxColorName] or Visual.AdvancedESP.colorMap.White
                    d.Box.Thickness = 1.7
                    d.Box.Visible = settings.box
                end
                
                if d.BoxOutline then
                    local thickness = settings.boxOutlineThickness or 0.4
                    d.BoxOutline.Position = Vector2.new(x - thickness, y - thickness)
                    d.BoxOutline.Size = Vector2.new(width + thickness * 2, height + thickness * 2)
                    d.BoxOutline.Color = Visual.AdvancedESP.colorMap[settings.boxOutlineColorName] or Visual.AdvancedESP.colorMap.Black
                    d.BoxOutline.Thickness = thickness
                    d.BoxOutline.Visible = settings.box and settings.boxOutline
                end

                if d.Name then
                    d.Name.Text = plr.Name
                    d.Name.Size = 20
                    d.Name.Position = Vector2.new(headPos.X, y - 22)
                    d.Name.Visible = settings.name
                end

                if d.Distance then
                    local dist = math.floor((root.Position - camPos).Magnitude)
                    d.Distance.Text = dist .. "m"
                    d.Distance.Size = 16
                    d.Distance.Position = Vector2.new(headPos.X, y + height + 6)
                    d.Distance.Visible = settings.distance
                end

                if d.HealthBg and d.HealthBar and d.HealthText then
                    local barX = x - (settings.healthBarLeftOffset or 10)
                    local barY = y
                    local barWidth = 6
                    local barHeight = height
                    
                    d.HealthBg.Position = Vector2.new(barX, barY)
                    d.HealthBg.Size = Vector2.new(barWidth, barHeight)
                    d.HealthBg.Visible = settings.healthbar
                    
                    if settings.healthbar then
                        local HEALTH_STRIPES = 24
                        local hpPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
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
                            stripe.Position = Vector2.new(barX, stripeY)
                            stripe.Size = Vector2.new(barWidth, stripeH)
                            stripe.Visible = (i - 1) / HEALTH_STRIPES < hpPerc
                            stripe.Transparency = 1
                        end
                        
                        d.HealthText.Text = tostring(math.floor(hum.Health))
                        d.HealthText.Size = 14
                        d.HealthText.Position = Vector2.new(x - (settings.healthBarLeftOffset or 10) - 14, y + height / 2)
                        d.HealthText.Visible = true
                    else
                        for i = 1, 24 do
                            if d["HealthStripe"..i] then
                                d["HealthStripe"..i].Visible = false
                            end
                        end
                        d.HealthText.Visible = false
                    end
                end

                if d.Bones then
                    local bonesVisible = settings.bones
                    local bones
                    
                    if Visual.IsR6(char) then
                        bones = {
                            {char:FindFirstChild("Head"), char:FindFirstChild("Torso")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Arm")},
                            {char:FindFirstChild("Left Arm"), char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Arm")},
                            {char:FindFirstChild("Right Arm"), char:FindFirstChild("Right Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Leg")}
                        }
                    else
                        bones = {
                            {char:FindFirstChild("Head"), char:FindFirstChild("Neck")},
                            {char:FindFirstChild("Neck"), char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")},
                            {char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"), char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm")},
                            {char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm"), char:FindFirstChild("LeftHand") or char:FindFirstChild("Left hand")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")},
                            {char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"), char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm")},
                            {char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm"), char:FindFirstChild("RightHand") or char:FindFirstChild("Right hand")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"), char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin")},
                            {char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin"), char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left foot")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")},
                            {char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"), char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin")},
                            {char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin"), char:FindFirstChild("RightFoot") or char:FindFirstChild("Right foot")}
                        }
                    end
                    
                    for i = 1, 14 do
                        local line = d.Bones[i]
                        if bones[i] and bones[i][1] and bones[i][2] then
                            local p1 = screenPosOrNil(bones[i][1])
                            local p2 = screenPosOrNil(bones[i][2])
                            if p1 and p2 then
                                line.From = p1
                                line.To = p2
                                line.Color = Visual.AdvancedESP.colorMap[settings.boneColorName] or Visual.AdvancedESP.colorMap.White
                                line.Visible = bonesVisible
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end

                if d.Tracer then
                    local rootPos2D = Vector2.new(headPos.X, headPos.Y)
                    d.Tracer.From = screenCenter
                    d.Tracer.To = rootPos2D
                    d.Tracer.Color = Visual.AdvancedESP.colorMap[settings.tracerColorName] or Visual.AdvancedESP.colorMap.White
                    d.Tracer.Visible = settings.tracers
                end
            else
                if d.BoxFill then d.BoxFill.Visible = false end
                if d.Box then d.Box.Visible = false end
                if d.BoxOutline then d.BoxOutline.Visible = false end
                if d.Name then d.Name.Visible = false end
                if d.Distance then d.Distance.Visible = false end
                if d.HealthBg then d.HealthBg.Visible = false end
                if d.HealthText then d.HealthText.Visible = false end
                for i = 1, 24 do
                    if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                end
                if d.Bones then for _, line in ipairs(d.Bones) do line.Visible = false end end
                if d.Tracer then d.Tracer.Visible = false end
            end
        else
            Visual.ClearAdvancedESP(plr)
        end
    end
end

function Visual.StartAdvancedESP()
    Nexus.Services.Players.PlayerAdded:Connect(function(plr)
        Visual.SetupPlayerAdvancedESP(plr)
    end)
    
    Nexus.Services.Players.PlayerRemoving:Connect(function(plr)
        Visual.CleanupPlayerAdvancedESP(plr)
    end)
    
    for _, plr in pairs(Nexus.Services.Players:GetPlayers()) do
        if plr ~= Nexus.Player then
            Visual.SetupPlayerAdvancedESP(plr)
        end
    end
    
    Visual.AdvancedESP.connections.renderStepped = Nexus.Services.RunService.RenderStepped:Connect(function()
        Visual.UpdateAdvancedESP()
    end)
end

function Visual.StopAdvancedESP()
    if Visual.AdvancedESP.connections.renderStepped then
        pcall(function() 
            Visual.AdvancedESP.connections.renderStepped:Disconnect() 
        end)
        Visual.AdvancedESP.connections.renderStepped = nil
    end
    
    local playersToClear = {}
    for plr, _ in pairs(Visual.AdvancedESP.espObjects) do
        table.insert(playersToClear, plr)
    end
    
    for _, plr in ipairs(playersToClear) do
        Visual.ClearAdvancedESP(plr)
    end
    
    table.clear(Visual.AdvancedESP.espObjects)
    table.clear(Visual.AdvancedESP.playerConnections)
    table.clear(Visual.AdvancedESP.connections)
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

    Tabs.Visual:AddSection("Advanced ESP Settings")

    local AdvancedESPToggle = Tabs.Visual:AddToggle("AdvancedESP", {
        Title = "Advanced ESP", 
        Description = "Enable advanced player ESP system", 
        Default = false
    })
    AdvancedESPToggle:OnChanged(function(v)
        Visual.ToggleAdvancedESP(v)
    end)

    Tabs.Visual:AddSection("ESP Components")

    local ESPBoxToggle = Tabs.Visual:AddToggle("ESPBox", {
        Title = "Player Boxes", 
        Description = "Show/hide player boxes", 
        Default = true
    })
    ESPBoxToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.box = v
    end)

    local ESPNamesToggle = Tabs.Visual:AddToggle("ESPNames", {
        Title = "Player Names", 
        Description = "Show/hide player names", 
        Default = true
    })
    ESPNamesToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.name = v
    end)

    local ESPHealthBarToggle = Tabs.Visual:AddToggle("ESPHealthBar", {
        Title = "Health Bar", 
        Description = "Show/hide health bar", 
        Default = true
    })
    ESPHealthBarToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.healthbar = v
    end)

    local ESPDistanceToggle = Tabs.Visual:AddToggle("ESPDistance", {
        Title = "Distance", 
        Description = "Show/hide distance to players", 
        Default = true
    })
    ESPDistanceToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.distance = v
    end)

    local ESPBoxFillToggle = Tabs.Visual:AddToggle("ESPBoxFill", {
        Title = "Filled Box", 
        Description = "Show/hide filled boxes", 
        Default = true
    })
    ESPBoxFillToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.boxFill = v
    end)

    local ESPTracersToggle = Tabs.Visual:AddToggle("ESPTracers", {
        Title = "Tracers", 
        Description = "Show/hide tracers to players", 
        Default = true
    })
    ESPTracersToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.tracers = v
    end)

    local ESPBonesToggle = Tabs.Visual:AddToggle("ESPBones", {
        Title = "Player Bones", 
        Description = "Show/hide player bones", 
        Default = true
    })
    ESPBonesToggle:OnChanged(function(v)
        Visual.AdvancedESP.settings.bones = v
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
    Visual.StopAdvancedESP()
    
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
    
    for _, connection in pairs(Visual.AdvancedESP.connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.AdvancedESP.connections = {}
    
    task.wait(0.1)
    pcall(function() game:GetService("RunService"):RenderStepped():Wait() end)
    collectgarbage()
end

return Visual
