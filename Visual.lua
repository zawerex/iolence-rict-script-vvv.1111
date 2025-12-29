local Nexus = _G.Nexus

local Visual = {
    Connections = {},
    ESP = {
        lastUpdate = 0,
        UPDATE_INTERVAL = 0.1,
        settings = {
            Survivors = {Enabled = false, Color = Color3.fromRGB(100, 255, 100), Colorpicker = nil},
            Killers = {Enabled = false, Color = Color3.fromRGB(255, 100, 100), Colorpicker = nil},
            Generators = {Enabled = false, Color = Color3.fromRGB(100, 170, 255)},
            Pallets = {Enabled = false, Color = Color3.fromRGB(120, 80, 40), Colorpicker = nil},
            ExitGates = {Enabled = false, Color = Color3.fromRGB(200, 200, 100), Colorpicker = nil},
            Windows = {Enabled = false, Color = Color3.fromRGB(100, 200, 200), Colorpicker = nil},
            Hooks = {Enabled = false, Color = Color3.fromRGB(100, 50, 150), Colorpicker = nil},
            Gifts = {Enabled = false, Color = Color3.fromRGB(255, 182, 193), Colorpicker = nil}
        },
        trackedObjects = {},
        espConnections = {},
        espLoopRunning = false,
        showGeneratorPercent = true,
        boxESPEnabled = false,
        namesESPEnabled = false,
        teamCheckEnabled = false,
        healthBarEnabled = false,
        boxColor = Color3.fromRGB(255, 255, 255),
        namesColor = Color3.fromRGB(255, 255, 255),
        boxESPObjects = {},
        autoFarmGiftEnabled = false,
        autoFarmRunning = false,
        autoFarmConnection = nil,
        currentGiftIndex = 1
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
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
    else
        hl.FillColor = color
        if isObject then
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        else
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
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
            lbl.Size = UDim2.new(0, 100, 0, 25)
            lbl.StudsOffset = Vector3.new(0, 2.5, 0)
        else
            lbl.Size = UDim2.new(0, 120, 0, 20)
            lbl.StudsOffset = Vector3.new(0, 3, 0)
        end
        lbl.AlwaysOnTop = true
        lbl.MaxDistance = 1000
        lbl.Parent = model
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
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
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
        textLabel.Text = text
        textLabel.Parent = lbl
    else
        local textLabel = lbl:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.RichText = true
            textLabel.Text = text
            if isGenerator then
                textLabel.TextSize = 14
                lbl.StudsOffset = Vector3.new(0, 2.5, 0)
            else
                textLabel.TextSize = 12
                lbl.StudsOffset = Vector3.new(0, 3, 0)
            end
            textLabel.TextStrokeTransparency = 0.1
            textLabel.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
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
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = generator
    else
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
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
    elseif nameLower:find("gift") then
        if Visual.IsValidGift(obj) then
            Visual.ESP.trackedObjects[obj] = "Gifts"
        end
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

function Visual.IsValidGift(obj)
    if obj.Name:lower():find("gift") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("SurfaceAppearance") then
                return true
            end
        end
    end
    return false
end

function Visual.GetAllGifts()
    local gifts = {}
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent and typeName == "Gifts" and Visual.IsValidGift(obj) then
            table.insert(gifts, obj)
        end
    end
    return gifts
end

function Visual.FindChristmasTree()
    local map = Nexus.Services.Workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local christmasTree = map:FindFirstChild("chris")
    if christmasTree then
        christmasTree = christmasTree:FindFirstChild("chrismta tute")
        if christmasTree then
            christmasTree = christmasTree:FindFirstChild("Model")
            if christmasTree then
                christmasTree = christmasTree:FindFirstChild("ChristmasTree")
                if christmasTree then
                    local treePine = christmasTree:FindFirstChild("TreePine")
                    if treePine then
                        return treePine
                    end
                end
            end
        end
    end
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name == "TreePine" then
            return obj
        end
    end
    
    return nil
end

function Visual.TeleportToObject(obj)
    local localPlayer = Nexus.Player
    if not localPlayer or not localPlayer.Character then
        return false
    end
    
    local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then
        return false
    end
    
    if obj then
        local targetPosition
        if obj:IsA("BasePart") then
            targetPosition = obj.Position + Vector3.new(0, 3, 0)
        elseif obj:IsA("Model") and obj.PrimaryPart then
            targetPosition = obj.PrimaryPart.Position + Vector3.new(0, 3, 0)
        else
            targetPosition = obj.Position + Vector3.new(0, 3, 0)
        end
        
        local success = pcall(function()
            rootPart.CFrame = CFrame.new(targetPosition)
        end)
        
        return success
    end
    
    return false
end

function Visual.SimulateMouseClick()
    local virtualInputManager = game:GetService("VirtualInputManager")
    if virtualInputManager then
        pcall(function()
            virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.1)
            virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end

function Visual.AutoFarmGiftLoop()
    if Visual.ESP.autoFarmRunning then
        return
    end
    
    Visual.ESP.autoFarmRunning = true
    Visual.ESP.currentGiftIndex = 1
    
    task.spawn(function()
        while Visual.ESP.autoFarmGiftEnabled do
            local gifts = Visual.GetAllGifts()
            
            if #gifts > 0 then
                if Visual.ESP.currentGiftIndex > #gifts then
                    Visual.ESP.currentGiftIndex = 1
                end
                
                local currentGift = gifts[Visual.ESP.currentGiftIndex]
                
                if currentGift and currentGift.Parent and Visual.IsValidGift(currentGift) then
                    Visual.TeleportToObject(currentGift)
                    task.wait(0.5)
                    
                    Visual.SimulateMouseClick()
                    task.wait(3)
                    
                    local christmasTree = Visual.FindChristmasTree()
                    if christmasTree then
                        Visual.TeleportToObject(christmasTree)
                        task.wait(3)
                    else
                        task.wait(3)
                    end
                    
                    Visual.ESP.currentGiftIndex = Visual.ESP.currentGiftIndex + 1
                else
                    Visual.ESP.currentGiftIndex = Visual.ESP.currentGiftIndex + 1
                end
            else
                task.wait(2)
            end
            
            task.wait(0.5)
        end
        
        Visual.ESP.autoFarmRunning = false
    end)
end

function Visual.ToggleAutoFarmGift(enabled)
    Visual.ESP.autoFarmGiftEnabled = enabled
    
    if enabled then
        Visual.AutoFarmGiftLoop()
    else
        Visual.ESP.autoFarmRunning = false
    end
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
                    Visual.ClearLabel(targetPlayer.Character)
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

function Visual.GetTeamCheckColor(player)
    if Visual.ESP.teamCheckEnabled then
        local localTeam = Visual.GetRole(Nexus.Player)
        local playerTeam = Visual.GetRole(player)
        
        if localTeam == playerTeam then
            return Color3.fromRGB(0, 0, 255)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    else
        return Visual.ESP.boxColor
    end
end

function Visual.CreateBoxESP(player)
    local espData = {}
    espData.Box = Drawing.new("Square")
    espData.BoxOutline = Drawing.new("Square")
    espData.Name = Drawing.new("Text")
    espData.HealthBar = Drawing.new("Square")
    espData.HealthBarOutline = Drawing.new("Square")
    espData.Updater = nil
    
    Visual.ESP.boxESPObjects[player] = espData
    
    local function UpdateBoxESP()
        if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("Head") ~= nil then
            local Target2dPosition, IsVisible = workspace.CurrentCamera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            local scale_factor = 1 / (Target2dPosition.Z * math.tan(math.rad(workspace.CurrentCamera.FieldOfView * 0.5)) * 2) * 100
            local width, height = math.floor(40 * scale_factor), math.floor(60 * scale_factor)
            
            espData.Box.Visible = Visual.ESP.boxESPEnabled and IsVisible
            espData.BoxOutline.Visible = Visual.ESP.boxESPEnabled and IsVisible
            espData.Name.Visible = Visual.ESP.namesESPEnabled and IsVisible
            espData.HealthBar.Visible = Visual.ESP.healthBarEnabled and IsVisible
            espData.HealthBarOutline.Visible = Visual.ESP.healthBarEnabled and IsVisible
            
            if Visual.ESP.boxESPEnabled and IsVisible then
                espData.Box.Color = Visual.GetTeamCheckColor(player)
                espData.Box.Size = Vector2.new(width, height)
                espData.Box.Position = Vector2.new(Target2dPosition.X - espData.Box.Size.X / 2, Target2dPosition.Y - espData.Box.Size.Y / 2)
                espData.Box.Thickness = 1
                espData.Box.ZIndex = 69
                
                espData.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
                espData.BoxOutline.Size = Vector2.new(width, height)
                espData.BoxOutline.Position = Vector2.new(Target2dPosition.X - espData.Box.Size.X / 2, Target2dPosition.Y - espData.Box.Size.Y / 2)
                espData.BoxOutline.Thickness = 3
                espData.BoxOutline.ZIndex = 1
            end
            
            if Visual.ESP.namesESPEnabled and IsVisible then
                espData.Name.Color = Visual.ESP.namesColor
                espData.Name.Text = player.Name .. " " .. math.floor((workspace.CurrentCamera.CFrame.p - player.Character.HumanoidRootPart.Position).magnitude) .. "m"
                espData.Name.Center = true
                espData.Name.Outline = true
                espData.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
                espData.Name.Position = Vector2.new(Target2dPosition.X, Target2dPosition.Y - height * 0.5 + -15)
                espData.Name.Font = 2
                espData.Name.Size = 13
            else
                espData.Name.Visible = false
            end
            
            if Visual.ESP.healthBarEnabled and IsVisible then
                espData.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
                espData.HealthBarOutline.Filled = true
                espData.HealthBarOutline.ZIndex = 1

                espData.HealthBar.Color = Color3.fromRGB(255, 0, 0):lerp(Color3.fromRGB(0, 255, 0), player.Character:FindFirstChild("Humanoid").Health / player.Character:FindFirstChild("Humanoid").MaxHealth)
                espData.HealthBar.Thickness = 1
                espData.HealthBar.Filled = true
                espData.HealthBar.ZIndex = 69
                
                local boxPosition = Vector2.new(Target2dPosition.X - width / 2, Target2dPosition.Y - height / 2)
                
                espData.HealthBarOutline.Size = Vector2.new(2, height)
                espData.HealthBarOutline.Position = boxPosition + Vector2.new(-7, 0)
                
                espData.HealthBar.Size = Vector2.new(1, -(espData.HealthBarOutline.Size.Y - 2) * (player.Character:FindFirstChild("Humanoid").Health / player.Character:FindFirstChild("Humanoid").MaxHealth))
                espData.HealthBar.Position = espData.HealthBarOutline.Position + Vector2.new(1, -1 + espData.HealthBarOutline.Size.Y)
            else
                espData.HealthBar.Visible = false
                espData.HealthBarOutline.Visible = false
            end
        else
            espData.Box.Visible = false
            espData.BoxOutline.Visible = false
            espData.Name.Visible = false
            espData.HealthBar.Visible = false
            espData.HealthBarOutline.Visible = false
        end
    end
    
    espData.Updater = game:GetService("RunService").RenderStepped:Connect(UpdateBoxESP)
    
    local function CleanupBoxESP()
        if espData.Updater then
            espData.Updater:Disconnect()
            espData.Updater = nil
        end
        
        espData.Box.Visible = false
        espData.BoxOutline.Visible = false
        espData.Name.Visible = false
        espData.HealthBar.Visible = false
        espData.HealthBarOutline.Visible = false
        
        Visual.ESP.boxESPObjects[player] = nil
    end
    
    player.CharacterRemoving:Connect(function()
        espData.Box.Visible = false
        espData.BoxOutline.Visible = false
        espData.Name.Visible = false
        espData.HealthBar.Visible = false
        espData.HealthBarOutline.Visible = false
    end)
    
    player.AncestryChanged:Connect(function()
        if not player.Parent then
            CleanupBoxESP()
        end
    end)
end

function Visual.InitializeBoxESP()
    for _, player in ipairs(Nexus.Services.Players:GetPlayers()) do
        if player ~= Nexus.Player then
            if not Visual.ESP.boxESPObjects[player] then
                Visual.CreateBoxESP(player)
            end
        end
    end
end

function Visual.UpdateAllBoxESP()
    for player, espData in pairs(Visual.ESP.boxESPObjects) do
        if player and player.Parent then
            if espData.Updater then
                espData.Updater:Disconnect()
                espData.Updater = nil
            end
            
            local function UpdateBoxESP()
                if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("Head") ~= nil then
                    local Target2dPosition, IsVisible = workspace.CurrentCamera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                    local scale_factor = 1 / (Target2dPosition.Z * math.tan(math.rad(workspace.CurrentCamera.FieldOfView * 0.5)) * 2) * 100
                    local width, height = math.floor(40 * scale_factor), math.floor(60 * scale_factor)
                    
                    espData.Box.Visible = Visual.ESP.boxESPEnabled and IsVisible
                    espData.BoxOutline.Visible = Visual.ESP.boxESPEnabled and IsVisible
                    espData.Name.Visible = Visual.ESP.namesESPEnabled and IsVisible
                    espData.HealthBar.Visible = Visual.ESP.healthBarEnabled and IsVisible
                    espData.HealthBarOutline.Visible = Visual.ESP.healthBarEnabled and IsVisible
                    
                    if Visual.ESP.boxESPEnabled and IsVisible then
                        espData.Box.Color = Visual.GetTeamCheckColor(player)
                        espData.Box.Size = Vector2.new(width, height)
                        espData.Box.Position = Vector2.new(Target2dPosition.X - espData.Box.Size.X / 2, Target2dPosition.Y - espData.Box.Size.Y / 2)
                        espData.Box.Thickness = 1
                        espData.Box.ZIndex = 69
                        
                        espData.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
                        espData.BoxOutline.Size = Vector2.new(width, height)
                        espData.BoxOutline.Position = Vector2.new(Target2dPosition.X - espData.Box.Size.X / 2, Target2dPosition.Y - espData.Box.Size.Y / 2)
                        espData.BoxOutline.Thickness = 3
                        espData.BoxOutline.ZIndex = 1
                    end
                    
                    if Visual.ESP.namesESPEnabled and IsVisible then
                        espData.Name.Color = Visual.ESP.namesColor
                        espData.Name.Text = player.Name .. " " .. math.floor((workspace.CurrentCamera.CFrame.p - player.Character.HumanoidRootPart.Position).magnitude) .. "m"
                        espData.Name.Center = true
                        espData.Name.Outline = true
                        espData.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
                        espData.Name.Position = Vector2.new(Target2dPosition.X, Target2dPosition.Y - height * 0.5 + -15)
                        espData.Name.Font = 2
                        espData.Name.Size = 13
                    else
                        espData.Name.Visible = false
                    end
                    
                    if Visual.ESP.healthBarEnabled and IsVisible then
                        espData.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
                        espData.HealthBarOutline.Filled = true
                        espData.HealthBarOutline.ZIndex = 1

                        espData.HealthBar.Color = Color3.fromRGB(255, 0, 0):lerp(Color3.fromRGB(0, 255, 0), player.Character:FindFirstChild("Humanoid").Health / player.Character:FindFirstChild("Humanoid").MaxHealth)
                        espData.HealthBar.Thickness = 1
                        espData.HealthBar.Filled = true
                        espData.HealthBar.ZIndex = 69
                        
                        local boxPosition = Vector2.new(Target2dPosition.X - width / 2, Target2dPosition.Y - height / 2)
                        
                        espData.HealthBarOutline.Size = Vector2.new(2, height)
                        espData.HealthBarOutline.Position = boxPosition + Vector2.new(-7, 0)
                        
                        espData.HealthBar.Size = Vector2.new(1, -(espData.HealthBarOutline.Size.Y - 2) * (player.Character:FindFirstChild("Humanoid").Health / player.Character:FindFirstChild("Humanoid").MaxHealth))
                        espData.HealthBar.Position = espData.HealthBarOutline.Position + Vector2.new(1, -1 + espData.HealthBarOutline.Size.Y)
                    else
                        espData.HealthBar.Visible = false
                        espData.HealthBarOutline.Visible = false
                    end
                else
                    espData.Box.Visible = false
                    espData.BoxOutline.Visible = false
                    espData.Name.Visible = false
                    espData.HealthBar.Visible = false
                    espData.HealthBarOutline.Visible = false
                end
            end
            
            espData.Updater = game:GetService("RunService").RenderStepped:Connect(UpdateBoxESP)
        end
    end
end

function Visual.ToggleBoxESP(enabled)
    Visual.ESP.boxESPEnabled = enabled
    
    if enabled then
        Visual.InitializeBoxESP()
        if not Visual.ESP.espConnections.boxESPPlayerAdded then
            Visual.ESP.espConnections.boxESPPlayerAdded = Nexus.Services.Players.PlayerAdded:Connect(function(player)
                if player ~= Nexus.Player then
                    Visual.CreateBoxESP(player)
                end
            end)
        end
        
        if not Visual.ESP.espConnections.boxESPPlayerRemoving then
            Visual.ESP.espConnections.boxESPPlayerRemoving = Nexus.Services.Players.PlayerRemoving:Connect(function(player)
                if Visual.ESP.boxESPObjects[player] then
                    local espData = Visual.ESP.boxESPObjects[player]
                    if espData.Updater then
                        espData.Updater:Disconnect()
                        espData.Updater = nil
                    end
                    
                    espData.Box.Visible = false
                    espData.BoxOutline.Visible = false
                    espData.Name.Visible = false
                    espData.HealthBar.Visible = false
                    espData.HealthBarOutline.Visible = false
                    
                    Visual.ESP.boxESPObjects[player] = nil
                end
            end)
        end
    else
        for _, espData in pairs(Visual.ESP.boxESPObjects) do
            espData.Box.Visible = false
            espData.BoxOutline.Visible = false
            espData.Name.Visible = false
            espData.HealthBar.Visible = false
            espData.HealthBarOutline.Visible = false
        end
    end
end

function Visual.ToggleNamesESP(enabled)
    Visual.ESP.namesESPEnabled = enabled
    
    for _, espData in pairs(Visual.ESP.boxESPObjects) do
        espData.Name.Visible = enabled
    end
end

function Visual.ToggleTeamCheck(enabled)
    Visual.ESP.teamCheckEnabled = enabled
    Visual.UpdateAllBoxESP()
end

function Visual.ToggleHealthBar(enabled)
    Visual.ESP.healthBarEnabled = enabled
    
    for _, espData in pairs(Visual.ESP.boxESPObjects) do
        espData.HealthBar.Visible = enabled
        espData.HealthBarOutline.Visible = enabled
    end
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
            
            if not Visual.Effects.fogCache then
                Visual.Effects.fogCache = {}
                
                Visual.Effects.fogCache.FogEnd = lighting.FogEnd
                Visual.Effects.fogCache.FogStart = lighting.FogStart
                Visual.Effects.fogCache.FogColor = lighting.FogColor
                Visual.Effects.fogCache.FogDensity = lighting.FogDensity
                Visual.Effects.fogCache.GlobalShadows = lighting.GlobalShadows
                Visual.Effects.fogCache.Brightness = lighting.Brightness
                Visual.Effects.fogCache.ExposureCompensation = lighting.ExposureCompensation
                
                for _, effect in ipairs(lighting:GetChildren()) do
                    if effect:IsA("Atmosphere") or 
                       effect:IsA("BloomEffect") or 
                       effect:IsA("BlurEffect") or 
                       effect:IsA("ColorCorrectionEffect") or
                       effect:IsA("SunRaysEffect") or
                       effect.Name:lower():find("fog") or
                       effect.Name:lower():find("bloom") or
                       effect.Name:lower():find("blur") or
                       effect.Name:lower():find("color") then
                        Visual.Effects.fogCache[effect.Name] = effect:Clone()
                    end
                end
                
                local map = Nexus.Services.Workspace:FindFirstChild("Map")
                if map then
                    Visual.Effects.fogCache.mapEffects = {}
                    for _, effect in ipairs(map:GetDescendants()) do
                        if effect:IsA("Atmosphere") or 
                           effect:IsA("BloomEffect") or 
                           effect:IsA("BlurEffect") or 
                           effect:IsA("ColorCorrectionEffect") or
                           effect:IsA("SunRaysEffect") then
                            Visual.Effects.fogCache.mapEffects[effect] = true
                        end
                    end
                end
            end
            
            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("Atmosphere") or 
                   effect:IsA("BloomEffect") or 
                   effect:IsA("BlurEffect") or 
                   effect:IsA("ColorCorrectionEffect") or
                   effect:IsA("SunRaysEffect") or
                   effect.Name:lower():find("fog") then
                    effect:Destroy()
                end
            end
            
            local map = Nexus.Services.Workspace:FindFirstChild("Map")
            if map then
                for _, effect in ipairs(map:GetDescendants()) do
                    if effect:IsA("Atmosphere") or 
                       effect:IsA("BloomEffect") or 
                       effect:IsA("BlurEffect") or 
                       effect:IsA("ColorCorrectionEffect") or
                       effect:IsA("SunRaysEffect") then
                        effect:Destroy()
                    end
                end
            end
            
            lighting.FogEnd = 10000000
            lighting.FogStart = 0
            lighting.FogDensity = 0
            lighting.FogColor = Color3.fromRGB(255, 255, 255)
            lighting.Brightness = 2
            lighting.ExposureCompensation = 1
            
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
        
        if Visual.Effects.fogCache then
            local lighting = Nexus.Services.Lighting
            lighting.FogEnd = Visual.Effects.fogCache.FogEnd
            lighting.FogStart = Visual.Effects.fogCache.FogStart
            lighting.FogColor = Visual.Effects.fogCache.FogColor
            lighting.FogDensity = Visual.Effects.fogCache.FogDensity
            lighting.GlobalShadows = Visual.Effects.fogCache.GlobalShadows
            lighting.Brightness = Visual.Effects.fogCache.Brightness
            lighting.ExposureCompensation = Visual.Effects.fogCache.ExposureCompensation
            
            for name, cachedEffect in pairs(Visual.Effects.fogCache) do
                if typeof(cachedEffect) == "Instance" then
                    local existing = lighting:FindFirstChild(name)
                    if not existing then
                        cachedEffect:Clone().Parent = lighting
                    end
                end
            end
            
            if Visual.Effects.fogCache.mapEffects then
                local map = Nexus.Services.Workspace:FindFirstChild("Map")
                if map then
                    for effect, _ in pairs(Visual.Effects.fogCache.mapEffects) do
                        if not effect.Parent then
                            local parent = map
                            local path = {}
                            local current = effect
                            while current and current ~= map do
                                table.insert(path, 1, current.Name)
                                current = current.Parent
                            end
                            
                            for i, name in ipairs(path) do
                                local child = parent:FindFirstChild(name)
                                if not child then
                                    break
                                end
                                parent = child
                            end
                        end
                    end
                end
            end
            
            Visual.Effects.fogCache = nil
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
        Description = "Disables all shadows in the game", 
        Default = false
    })
    NoShadowToggle:OnChanged(function(v) Visual.ToggleNoShadow(v) end)

    local NoFogToggle = Tabs.Visual:AddToggle("NoFog", {
        Title = "No Fog", 
        Description = "Removes all fog and atmospheric effects", 
        Default = false
    })
    
    NoFogToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            Visual.ToggleNoFog(v)
        end)
    end)

    local FullBrightToggle = Tabs.Visual:AddToggle("FullBright", {
        Title = "FullBright", 
        Description = "Makes the game brighter", 
        Default = false
    })
    FullBrightToggle:OnChanged(function(v) Visual.ToggleFullBright(v) end)

    local TimeChangerToggle = Tabs.Visual:AddToggle("TimeChanger", {
        Title = "Time Changer", 
        Description = "Changes the time of day", 
        Default = false
    })

    local TimeSlider = Tabs.Visual:AddSlider("TimeValue", {
        Title = "Time of Day", 
        Description = "Set the time (0-24 hours)",
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

    Tabs.Visual:AddParagraph({
        Title = "ESP Colors information",
        Content = "You can only change the ESP color in the lobby. You won't be able to change the ESP color in-game due to certain game mechanics. This is a temporary issue."
    })
    
    local ShowGeneratorPercentToggle = Tabs.Visual:AddToggle("ESPShowGenPercent", {
        Title = "Show Generator %", 
        Description = "Shows generator repair percentage", 
        Default = true
    })
    ShowGeneratorPercentToggle:OnChanged(function(v)
        Visual.ESP.showGeneratorPercent = v
        Visual.UpdateESPDisplay()
    end)

    Tabs.Visual:AddSection("Player ESP Settings")

    local ESPSurvivorsToggle = Tabs.Visual:AddToggle("ESPSurvivors", {
        Title = "Survivors ESP", 
        Description = "Highlights survivors", 
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
        Description = "Highlights killers", 
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

    Tabs.Visual:AddSection("Object ESP Settings")

    local ESPHooksToggle = Tabs.Visual:AddToggle("ESPHooks", {
        Title = "Hooks ESP", 
        Description = "Highlights hooks", 
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
        Description = "Highlights generators", 
        Default = false
    })
    ESPGeneratorsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Generators", v)
    end)

    local ESPPalletsToggle = Tabs.Visual:AddToggle("ESPPallets", {
        Title = "Pallets ESP", 
        Description = "Highlights pallets", 
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
        Description = "Highlights exit gates", 
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
        Description = "Highlights windows", 
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

    local ESPGiftsToggle = Tabs.Visual:AddToggle("ESPGifts", {
        Title = "Gift ESP", 
        Description = "Highlights Christmas gifts", 
        Default = false
    })
    ESPGiftsToggle:OnChanged(function(v)
        Visual.ToggleESPSetting("Gifts", v)
    end)

    local GiftColorpicker = Tabs.Visual:AddColorpicker("GiftColorpicker", {
        Title = "Gift Color",
        Default = Color3.fromRGB(255, 182, 193)
    })
    GiftColorpicker:OnChanged(function()
        Visual.ESP.settings.Gifts.Color = GiftColorpicker.Value
        Visual.UpdateESPColors()
    end)
    GiftColorpicker:SetValueRGB(Color3.fromRGB(255, 182, 193))

    Visual.ESP.settings.Survivors.Colorpicker = SurvivorColorpicker
    Visual.ESP.settings.Killers.Colorpicker = KillerColorpicker
    Visual.ESP.settings.Hooks.Colorpicker = HookColorpicker
    Visual.ESP.settings.Pallets.Colorpicker = PalletColorpicker
    Visual.ESP.settings.ExitGates.Colorpicker = GateColorpicker
    Visual.ESP.settings.Windows.Colorpicker = WindowColorpicker
    Visual.ESP.settings.Gifts.Colorpicker = GiftColorpicker

    Tabs.Visual:AddSection("Box ESP Settings")

    local BoxESPToggle = Tabs.Visual:AddToggle("BoxESP", {
        Title = "Box ESP",
        Description = "Draws boxes around players",
        Default = false
    })
    BoxESPToggle:OnChanged(function(v)
        Visual.ToggleBoxESP(v)
    end)

    local BoxColorpicker = Tabs.Visual:AddColorpicker("BoxColorpicker", {
        Title = "Box Color",
        Default = Color3.fromRGB(255, 255, 255)
    })
    BoxColorpicker:OnChanged(function()
        Visual.ESP.boxColor = BoxColorpicker.Value
        Visual.UpdateAllBoxESP()
    end)
    BoxColorpicker:SetValueRGB(Color3.fromRGB(255, 255, 255))

    local NamesESPToggle = Tabs.Visual:AddToggle("NamesESP", {
        Title = "Names ESP",
        Description = "Shows player names and distance",
        Default = false
    })
    NamesESPToggle:OnChanged(function(v)
        Visual.ToggleNamesESP(v)
    end)

    local NamesColorpicker = Tabs.Visual:AddColorpicker("NamesColorpicker", {
        Title = "Names Color",
        Default = Color3.fromRGB(255, 255, 255)
    })
    NamesColorpicker:OnChanged(function()
        Visual.ESP.namesColor = NamesColorpicker.Value
        Visual.UpdateAllBoxESP()
    end)
    NamesColorpicker:SetValueRGB(Color3.fromRGB(255, 255, 255))

    local TeamCheckToggle = Tabs.Visual:AddToggle("TeamCheck", {
        Title = "Team Check",
        Description = "Shows enemies in red, teammates in blue",
        Default = false
    })
    TeamCheckToggle:OnChanged(function(v)
        Visual.ToggleTeamCheck(v)
    end)

    local HealthBarToggle = Tabs.Visual:AddToggle("HealthBar", {
        Title = "Health Bar",
        Description = "Shows player health bars",
        Default = false
    })
    HealthBarToggle:OnChanged(function(v)
        Visual.ToggleHealthBar(v)
    end)

    Tabs.Visual:AddSection("Auto Farm Settings")

    local AutoFarmGiftToggle = Tabs.Visual:AddToggle("AutoFarmGift", {
        Title = "AutoFarm Gift",
        Description = "Automatically collects Christmas gifts",
        Default = false
    })
    AutoFarmGiftToggle:OnChanged(function(v)
        Visual.ToggleAutoFarmGift(v)
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
    
    Visual.ToggleAutoFarmGift(false)
    
    for _, espData in pairs(Visual.ESP.boxESPObjects) do
        if espData.Updater then
            espData.Updater:Disconnect()
            espData.Updater = nil
        end
        
        espData.Box.Visible = false
        espData.BoxOutline.Visible = false
        espData.Name.Visible = false
        espData.HealthBar.Visible = false
        espData.HealthBarOutline.Visible = false
    end
    Visual.ESP.boxESPObjects = {}
    
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
end

return Visual
