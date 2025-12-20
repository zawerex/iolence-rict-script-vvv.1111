-- Visual Module - Visual effects and ESP
local Nexus = _G.Nexus

local Visual = {
    Effects = {
        noShadowEnabled = false,
        noFogEnabled = false,
        fullbrightEnabled = false,
        timeChangerEnabled = false,
        originalFogEnd = nil,
        originalFogStart = nil,
        originalFogColor = nil,
        originalClockTime = nil
    },
    ESP = {
        settings = {
            Survivors  = {Enabled=false, Color=Color3.fromRGB(100,255,100)},
            Killers    = {Enabled=false, Color=Color3.fromRGB(255,100,100)},
            Generators = {Enabled=false, Color=Color3.fromRGB(100,170,255)},
            Pallets    = {Enabled=false, Color=Color3.fromRGB(120,80,40)},
            ExitGates  = {Enabled=false, Color=Color3.fromRGB(200,200,100)},
            Windows    = {Enabled=false, Color=Color3.fromRGB(100,200,200)},
            Hooks      = {Enabled=false, Color=Color3.fromRGB(100, 50, 150)}
        },
        trackedObjects = {},
        connections = {},
        loopRunning = false,
        showGeneratorPercent = true
    },
    AdvancedESP = {
        enabled = false,
        settings = {
            name = true,
            distance = true,
            healthbar = true,
            box = true,
            tracers = true,
            bones = true
        },
        connections = {},
        espObjects = {}
    }
}

function Visual.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== VISUAL EFFECTS ==========
    local NoShadowToggle = Tabs.Visual:AddToggle("NoShadow", {
        Title = "No Shadow", 
        Description = "", 
        Default = false
    })

    NoShadowToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleNoShadow(v)
        end)
    end)

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

    FullBrightToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleFullBright(v)
        end)
    end)

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
            Nexus.SafeCallback(function()
                if Options.TimeChanger.Value then
                    Visual.SetTime(value)
                end
            end)
        end
    })

    TimeChangerToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleTimeChanger(v)
        end)
    end)

    -- Автоматическое обновление времени
    task.spawn(function()
        while true do
            task.wait(1)
            if Options.TimeChanger and Options.TimeChanger.Value then
                local currentTime = Options.TimeValue.Value
                Visual.SetTime(currentTime)
            end
        end
    end)

    -- ========== ESP SETTINGS ==========
    Tabs.Visual:AddSection("ESP Settings")

    local ShowGeneratorPercentToggle = Tabs.Visual:AddToggle("ESPShowGenPercent", {
        Title = "Show Generator %", 
        Description = "Toggle display of generator percentages", 
        Default = true
    })

    ShowGeneratorPercentToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.SetShowGeneratorPercent(v)
        end)
    end)

    local ESPSurvivorsToggle = Tabs.Visual:AddToggle("ESPSurvivors", {
        Title = "Survivors ESP", 
        Description = "", 
        Default = false
    })

    ESPSurvivorsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Survivors", v)
        end)
    end)

    local SurvivorColorpicker = Tabs.Visual:AddColorpicker("SurvivorColorpicker", {
        Title = "Survivor Color",
        Default = Color3.fromRGB(100, 255, 100)
    })

    SurvivorColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("Survivors", SurvivorColorpicker.Value)
        end)
    end)

    SurvivorColorpicker:SetValueRGB(Color3.fromRGB(100, 255, 100))

    local ESPKillersToggle = Tabs.Visual:AddToggle("ESPKillers", {
        Title = "Killers ESP", 
        Description = "", 
        Default = false
    })

    ESPKillersToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Killers", v)
        end)
    end)

    local KillerColorpicker = Tabs.Visual:AddColorpicker("KillerColorpicker", {
        Title = "Killer Color",
        Default = Color3.fromRGB(255, 100, 100)
    })

    KillerColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("Killers", KillerColorpicker.Value)
        end)
    end)

    KillerColorpicker:SetValueRGB(Color3.fromRGB(255, 100, 100))

    local ESPHooksToggle = Tabs.Visual:AddToggle("ESPHooks", {
        Title = "Hooks ESP", 
        Description = "", 
        Default = false
    })

    ESPHooksToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Hooks", v)
        end)
    end)

    local HookColorpicker = Tabs.Visual:AddColorpicker("HookColorpicker", {
        Title = "Hook Color",
        Default = Color3.fromRGB(100, 50, 150)
    })

    HookColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("Hooks", HookColorpicker.Value)
        end)
    end)

    HookColorpicker:SetValueRGB(Color3.fromRGB(100, 50, 150))

    local ESPGeneratorsToggle = Tabs.Visual:AddToggle("ESPGenerators", {
        Title = "Generators ESP", 
        Description = "", 
        Default = false
    })

    ESPGeneratorsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Generators", v)
        end)
    end)

    local ESPPalletsToggle = Tabs.Visual:AddToggle("ESPPallets", {
        Title = "Pallets ESP", 
        Description = "", 
        Default = false
    })

    ESPPalletsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Pallets", v)
        end)
    end)

    local PalletColorpicker = Tabs.Visual:AddColorpicker("PalletColorpicker", {
        Title = "Pallet Color",
        Default = Color3.fromRGB(120, 80, 40)
    })

    PalletColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("Pallets", PalletColorpicker.Value)
        end)
    end)

    PalletColorpicker:SetValueRGB(Color3.fromRGB(120, 80, 40))

    local ESPGatesToggle = Tabs.Visual:AddToggle("ESPGates", {
        Title = "Exit Gates ESP", 
        Description = "", 
        Default = false
    })

    ESPGatesToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("ExitGates", v)
        end)
    end)

    local GateColorpicker = Tabs.Visual:AddColorpicker("GateColorpicker", {
        Title = "Gate Color",
        Default = Color3.fromRGB(200, 200, 100)
    })

    GateColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("ExitGates", GateColorpicker.Value)
        end)
    end)

    GateColorpicker:SetValueRGB(Color3.fromRGB(200, 200, 100))

    local ESPWindowsToggle = Tabs.Visual:AddToggle("ESPWindows", {
        Title = "Windows ESP", 
        Description = "", 
        Default = false
    })

    ESPWindowsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleESPSetting("Windows", v)
        end)
    end)

    local WindowColorpicker = Tabs.Visual:AddColorpicker("WindowColorpicker", {
        Title = "Window Color",
        Default = Color3.fromRGB(100, 200, 200)
    })

    WindowColorpicker:OnChanged(function()
        Nexus.SafeCallback(function()
            Visual.SetESPColor("Windows", WindowColorpicker.Value)
        end)
    end)

    WindowColorpicker:SetValueRGB(Color3.fromRGB(100, 200, 200))

    -- ========== ADVANCED ESP ==========
    Tabs.Visual:AddSection("Advanced ESP")

    local AdvancedESPToggle = Tabs.Visual:AddToggle("AdvancedESP", {
        Title = "Advanced ESP", 
        Description = "Enable advanced player ESP system", 
        Default = false
    })

    AdvancedESPToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Visual.ToggleAdvancedESP(v)
        end)
    end)

    print("✓ Visual module initialized")
end

-- ========== VISUAL EFFECTS FUNCTIONS ==========

function Visual.ToggleNoShadow(enabled)
    Visual.Effects.noShadowEnabled = enabled
    if enabled then
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = false 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = false
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Shadows disabled",
            Duration = 2
        })
    else
        for _, light in ipairs(Nexus.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = true 
            end 
        end
        Nexus.Services.Lighting.GlobalShadows = true
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Shadows enabled",
            Duration = 2
        })
    end
end

function Visual.ToggleNoFog(enabled)
    Visual.Effects.noFogEnabled = enabled
    
    if enabled then
        if not Visual.Effects.originalFogEnd then
            Visual.Effects.originalFogEnd = Nexus.Services.Lighting.FogEnd
            Visual.Effects.originalFogStart = Nexus.Services.Lighting.FogStart
            Visual.Effects.originalFogColor = Nexus.Services.Lighting.FogColor
        end
        
        Nexus.Services.Lighting.FogEnd = 1000000
        Nexus.Services.Lighting.FogStart = 1000000
        Nexus.Services.Lighting.FogDensity = 0
        
        if Nexus.Services.Lighting:FindFirstChild("Atmosphere") then
            Nexus.Services.Lighting.Atmosphere.Density = 0
        end
        
        Visual.ESP.connections.noFog = Nexus.Services.RunService.Heartbeat:Connect(function()
            if Visual.Effects.noFogEnabled then
                Nexus.Services.Lighting.FogEnd = 1000000
                Nexus.Services.Lighting.FogStart = 1000000
                Nexus.Services.Lighting.FogDensity = 0
                
                if Nexus.Services.Lighting:FindFirstChild("Atmosphere") then
                    Nexus.Services.Lighting.Atmosphere.Density = 0
                end
            else
                if Visual.ESP.connections.noFog then
                    Visual.ESP.connections.noFog:Disconnect()
                    Visual.ESP.connections.noFog = nil
                end
            end
        end)
        
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Fog disabled",
            Duration = 2
        })
    else
        if Visual.Effects.originalFogEnd then
            Nexus.Services.Lighting.FogEnd = Visual.Effects.originalFogEnd
            Nexus.Services.Lighting.FogStart = Visual.Effects.originalFogStart
            Nexus.Services.Lighting.FogColor = Visual.Effects.originalFogColor
            Nexus.Services.Lighting.FogDensity = 0.01
        end
        
        if Nexus.Services.Lighting:FindFirstChild("Atmosphere") then
            Nexus.Services.Lighting.Atmosphere.Density = 0.3
        end
        
        if Visual.ESP.connections.noFog then
            Visual.ESP.connections.noFog:Disconnect()
            Visual.ESP.connections.noFog = nil
        end
        
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Fog enabled",
            Duration = 2
        })
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
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Fullbright enabled",
            Duration = 2
        })
    else
        Nexus.Services.Lighting.GlobalShadows = true
        Nexus.Services.Lighting.FogEnd = 1000
        Nexus.Services.Lighting.Brightness = 1
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Fullbright disabled",
            Duration = 2
        })
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
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Time changer enabled: " .. currentTime,
            Duration = 2
        })
    else
        if Visual.Effects.originalClockTime then
            Nexus.Services.Lighting.ClockTime = Visual.Effects.originalClockTime
        end
        Nexus.Fluent:Notify({
            Title = "Visual",
            Content = "Time changer disabled",
            Duration = 2
        })
    end
end

function Visual.SetTime(time)
    Nexus.Services.Lighting.ClockTime = time
end

-- ========== ESP FUNCTIONS ==========

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
        
        if anyEnabled and not Visual.ESP.loopRunning then
            Visual.StartESP()
        elseif not anyEnabled and Visual.ESP.loopRunning then
            Visual.StopESP()
        end
        
        Nexus.Fluent:Notify({
            Title = "ESP",
            Content = settingName .. " ESP " .. (enabled and "enabled" or "disabled"),
            Duration = 2
        })
    end
end

function Visual.SetESPColor(settingName, color)
    if Visual.ESP.settings[settingName] then
        Visual.ESP.settings[settingName].Color = color
        
        if Visual.ESP.settings[settingName].Enabled then
            -- Обновляем цвет для всех объектов этого типа
            Visual.UpdateESPColors()
        end
    end
end

function Visual.SetShowGeneratorPercent(enabled)
    Visual.ESP.showGeneratorPercent = enabled
    Visual.UpdateESPDisplay()
end

function Visual.StartESP()
    if Visual.ESP.loopRunning then return end
    Visual.ESP.loopRunning = true
    
    -- Начинаем отслеживание объектов
    Visual.TrackObjects()
    
    -- Запускаем ESP цикл
    Visual.ESP.connections.mainLoop = task.spawn(function()
        while Visual.ESP.loopRunning do
            Visual.UpdateESP()
            task.wait(0.1) -- UPDATE_INTERVAL
        end
    end)
    
    Nexus.Fluent:Notify({
        Title = "ESP",
        Content = "ESP system started",
        Duration = 2
    })
end

function Visual.StopESP()
    Visual.ESP.loopRunning = false
    
    -- Очищаем все ESP объекты
    Visual.ClearAllESP()
    
    -- Отключаем соединения
    for _, connection in pairs(Visual.ESP.connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.ESP.connections = {}
    
    Nexus.Fluent:Notify({
        Title = "ESP",
        Content = "ESP system stopped",
        Duration = 2
    })
end

function Visual.TrackObjects()
    Visual.ESP.trackedObjects = {}
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end
    
    Visual.ESP.connections.descendantAdded = Nexus.Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end)
end

function Visual.AddObjectToTrack(obj)
    local nameLower = obj.Name:lower()
    
    if nameLower:find("generator") then 
        Visual.ESP.trackedObjects[obj] = "Generators"
    elseif nameLower:find("pallet") then 
        Visual.ESP.trackedObjects[obj] = "Pallets"
    elseif nameLower:find("gate") then 
        Visual.ESP.trackedObjects[obj] = "ExitGates"
    elseif nameLower:find("window") then 
        Visual.ESP.trackedObjects[obj] = "Windows"
    elseif nameLower:find("hook") then 
        Visual.ESP.trackedObjects[obj] = "Hooks"
    end
end

function Visual.UpdateESP()
    -- Обновляем игроков
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer ~= Nexus.Player and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local function getRole(player)
                    if player.Team and player.Team.Name then
                        local n = player.Team.Name:lower()
                        if n:find("killer") then return "Killer" end
                        if n:find("survivor") then return "Survivor" end
                    end
                    return "Survivor"
                end
                
                local role = getRole(targetPlayer)
                local setting = (role == "Killer") and Visual.ESP.settings.Killers or Visual.ESP.settings.Survivors
                
                if setting and setting.Enabled then
                    Visual.EnsureHighlight(targetPlayer.Character, setting.Color, false)
                else
                    Visual.ClearHighlight(targetPlayer.Character)
                end
            end
        end
    end
    
    -- Обновляем объекты
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            local setting = Visual.ESP.settings[typeName]
            if setting and setting.Enabled then
                if typeName == "Generators" then
                    local progress = Visual.GetGeneratorProgress(obj)
                    Visual.EnsureGeneratorESP(obj, progress)
                else
                    Visual.EnsureHighlight(obj, setting.Color, true)
                end
            else
                Visual.ClearHighlight(obj)
            end
        end
    end
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
end

function Visual.UpdateESPDisplay()
    -- Обновляем отображение всех объектов ESP
    if Visual.ESP.loopRunning then
        Visual.UpdateESP()
    end
end

function Visual.UpdateESPColors()
    -- Обновляем цвета для всех объектов ESP
    if Visual.ESP.loopRunning then
        Visual.UpdateESP()
    end
end

function Visual.ClearAllESP()
    -- Очищаем всех игроков
    for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            Visual.ClearHighlight(targetPlayer.Character)
        end
    end
    
    -- Очищаем все объекты
    for obj, _ in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            Visual.ClearHighlight(obj)
        end
    end
end

-- ========== ADVANCED ESP FUNCTIONS ==========

function Visual.ToggleAdvancedESP(enabled)
    Visual.AdvancedESP.enabled = enabled
    
    if enabled then
        Visual.StartAdvancedESP()
        Nexus.Fluent:Notify({
            Title = "Advanced ESP",
            Content = "Advanced ESP enabled",
            Duration = 2
        })
    else
        Visual.StopAdvancedESP()
        Nexus.Fluent:Notify({
            Title = "Advanced ESP",
            Content = "Advanced ESP disabled",
            Duration = 2
        })
    end
end

function Visual.StartAdvancedESP()
    -- Простая реализация Advanced ESP
    Visual.AdvancedESP.connections.renderStepped = Nexus.Services.RunService.RenderStepped:Connect(function()
        if not Visual.AdvancedESP.enabled then return end
        
        for _, player in ipairs(Nexus.Services.Players:GetPlayers()) do
            if player ~= Nexus.Player and player.Character then
                Visual.DrawAdvancedESP(player)
            end
        end
    end)
end

function Visual.StopAdvancedESP()
    for _, connection in pairs(Visual.AdvancedESP.connections) do
        Nexus.safeDisconnect(connection)
    end
    Visual.AdvancedESP.connections = {}
    
    -- Очищаем все Drawing объекты
    for _, drawing in pairs(Visual.AdvancedESP.espObjects) do
        if drawing and drawing.Remove then
            pcall(function() drawing:Remove() end)
        end
    end
    Visual.AdvancedESP.espObjects = {}
end

function Visual.DrawAdvancedESP(player)
    -- Упрощенная реализация рисования ESP
    -- Здесь можно добавить Drawing библиотеку
end

-- ========== CLEANUP ==========

function Visual.Cleanup()
    Visual.StopESP()
    Visual.StopAdvancedESP()
    
    -- Восстанавливаем визуальные эффекты
    Visual.ToggleNoShadow(false)
    Visual.ToggleNoFog(false)
    Visual.ToggleFullBright(false)
    Visual.ToggleTimeChanger(false)
    
    print("Visual module cleaned up")
end

return Visual
