local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    ActiveKeybinds = {},
    CursorUnlock = {
        enabled = false,
        connection = nil
    },
    DisplayGui = nil
}

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    -- Создаем GUI для отображения биндов
    Binds.CreateDisplayGUI()
    
    -- ========== CURSOR UNLOCK ==========
    Tabs.Binds:AddSection("Cursor Unlock")
    
    local CursorToggleKeybind = Tabs.Binds:AddKeybind("CursorToggleKeybind", {
        Title = "Cursor Toggle Keybind",
        Description = "Press to toggle cursor lock/unlock",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleCursorUnlock()
            end)
        end,
        ChangedCallback = function(newKey)
            Nexus.SafeCallback(function()
                Nexus.Fluent:Notify({
                    Title = "Keybind Updated",
                    Content = "Cursor toggle key set to: " .. tostring(newKey),
                    Duration = 2
                })
                Binds.UpdateKeybindDisplay("CursorToggle", "Cursor Toggle", newKey)
            end)
        end
    })
    
    Binds.Keybinds.CursorToggle = CursorToggleKeybind
    
    -- ========== SURVIVOR BINDS ==========
    Tabs.Binds:AddSection("Survivor Binds")
    
    local AutoParryKeybind = Tabs.Binds:AddKeybind("AutoParryKeybind", {
        Title = "AutoParry",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoParry")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParry", "Auto Parry", newKey)
        end
    })
    
    local AutoParryV2Keybind = Tabs.Binds:AddKeybind("AutoParryV2Keybind", {
        Title = "AutoParry (Anti-Stun)",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoParryV2")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParryV2", "Auto Parry V2", newKey)
        end
    })
    
    local HealKeybindBinds = Tabs.Binds:AddKeybind("HealKeybindBinds", {
        Title = "Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Heal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Heal", "Heal", newKey)
        end
    })
    
    local InstantHealKeybind = Tabs.Binds:AddKeybind("InstantHealKeybind", {
        Title = "Instant Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("InstantHeal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("InstantHeal", "Instant Heal", newKey)
        end
    })
    
    local SilentHealKeybind = Tabs.Binds:AddKeybind("SilentHealKeybind", {
        Title = "Silent Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("SilentHeal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("SilentHeal", "Silent Heal", newKey)
        end
    })
    
    local GateToolKeybind = Tabs.Binds:AddKeybind("GateToolKeybind", {
        Title = "Gate Tool",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("GateTool")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("GateTool", "Gate Tool", newKey)
        end
    })
    
    local NoHitboxKeybind = Tabs.Binds:AddKeybind("NoHitboxKeybind", {
        Title = "No Hitbox",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoHitbox")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoHitbox", "No Hitbox", newKey)
        end
    })
    
    local AntiFailKeybind = Tabs.Binds:AddKeybind("AntiFailKeybind", {
        Title = "Anti-Fail Generator",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AntiFailGenerator")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AntiFailGenerator", "Anti-Fail Gen", newKey)
        end
    })
    
    local AutoSkillKeybind = Tabs.Binds:AddKeybind("AutoSkillKeybind", {
        Title = "Auto Perfect Skill Check",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoPerfectSkill")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoPerfectSkill", "Auto Skill", newKey)
        end
    })
    
    -- ========== KILLER BINDS ==========
    Tabs.Binds:AddSection("Killer Binds")
    
    local OneHitKillKeybind = Tabs.Binds:AddKeybind("OneHitKillKeybind", {
        Title = "OneHitKill",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("OneHitKill")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("OneHitKill", "OneHit Kill", newKey)
        end
    })
    
    local AntiBlindKeybind = Tabs.Binds:AddKeybind("AntiBlindKeybind", {
        Title = "Anti Blind",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AntiBlind")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AntiBlind", "Anti Blind", newKey)
        end
    })
    
    local NoSlowdownKeybind = Tabs.Binds:AddKeybind("NoSlowdownKeybind", {
        Title = "No Slowdown",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoSlowdown")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoSlowdown", "No Slowdown", newKey)
        end
    })
    
    local DestroyPalletsKeybind = Tabs.Binds:AddKeybind("DestroyPalletsKeybind", {
        Title = "Destroy Pallets",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("DestroyPallets")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("DestroyPallets", "Destroy Pallets", newKey)
        end
    })
    
    local BreakGeneratorKeybind = Tabs.Binds:AddKeybind("BreakGeneratorKeybind", {
        Title = "Break Generator",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("BreakGenerator")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("BreakGenerator", "Break Generator", newKey)
        end
    })
    
    -- ========== MOVEMENT BINDS ==========
    Tabs.Binds:AddSection("Movement Binds")
    
    local InfiniteLungeKeybind = Tabs.Binds:AddKeybind("InfiniteLungeKeybind", {
        Title = "Infinite Lunge",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("InfiniteLunge")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("InfiniteLunge", "Infinite Lunge", newKey)
        end
    })
    
    local WalkSpeedKeybind = Tabs.Binds:AddKeybind("WalkSpeedKeybind", {
        Title = "Walk Speed",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("WalkSpeed")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("WalkSpeed", "Walk Speed", newKey)
        end
    })
    
    local NoclipKeybind = Tabs.Binds:AddKeybind("NoclipKeybind", {
        Title = "Noclip",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Noclip")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Noclip", "Noclip", newKey)
        end
    })
    
    local FOVKeybind = Tabs.Binds:AddKeybind("FOVKeybind", {
        Title = "FOV Changer",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FOVChanger")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FOVChanger", "FOV Changer", newKey)
        end
    })
    
    local FlyKeybind = Tabs.Binds:AddKeybind("FlyKeybind", {
        Title = "Fly",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Fly")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Fly", "Fly", newKey)
        end
    })
    
    local FreeCameraKeybind = Tabs.Binds:AddKeybind("FreeCameraKeybind", {
        Title = "Free Camera",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FreeCamera")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FreeCamera", "Free Camera", newKey)
        end
    })
    
    -- ========== VISUAL BINDS ==========
    Tabs.Binds:AddSection("Visual Binds")
    
    local NoShadowKeybind = Tabs.Binds:AddKeybind("NoShadowKeybind", {
        Title = "No Shadow",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoShadow")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoShadow", "No Shadow", newKey)
        end
    })
    
    local NoFogKeybind = Tabs.Binds:AddKeybind("NoFogKeybind", {
        Title = "No Fog",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoFog")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoFog", "No Fog", newKey)
        end
    })
    
    local FullBrightKeybind = Tabs.Binds:AddKeybind("FullBrightKeybind", {
        Title = "FullBright",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FullBright")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FullBright", "FullBright", newKey)
        end
    })
    
    local TimeChangerKeybind = Tabs.Binds:AddKeybind("TimeChangerKeybind", {
        Title = "Time Changer",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("TimeChanger")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("TimeChanger", "Time Changer", newKey)
        end
    })
    
    local ESPSurvivorsKeybind = Tabs.Binds:AddKeybind("ESPSurvivorsKeybind", {
        Title = "Survivors ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPSurvivors")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPSurvivors", "ESP Survivors", newKey)
        end
    })
    
    local ESPKillersKeybind = Tabs.Binds:AddKeybind("ESPKillersKeybind", {
        Title = "Killers ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPKillers")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPKillers", "ESP Killers", newKey)
        end
    })
    
    local ESPHooksKeybind = Tabs.Binds:AddKeybind("ESPHooksKeybind", {
        Title = "Hooks ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPHooks")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPHooks", "ESP Hooks", newKey)
        end
    })
    
    local ESPGeneratorsKeybind = Tabs.Binds:AddKeybind("ESPGeneratorsKeybind", {
        Title = "Generators ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPGenerators")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPGenerators", "ESP Generators", newKey)
        end
    })
    
    local ESPPalletsKeybind = Tabs.Binds:AddKeybind("ESPPalletsKeybind", {
        Title = "Pallets ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPPallets")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPPallets", "ESP Pallets", newKey)
        end
    })
    
    local ESPGatesKeybind = Tabs.Binds:AddKeybind("ESPGatesKeybind", {
        Title = "Exit Gates ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPGates")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPGates", "ESP Gates", newKey)
        end
    })
    
    local ESPWindowsKeybind = Tabs.Binds:AddKeybind("ESPWindowsKeybind", {
        Title = "Windows ESP",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ESPWindows")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ESPWindows", "ESP Windows", newKey)
        end
    })
    
    print("✓ Binds module initialized")
end

-- ========== DISPLAY GUI FUNCTIONS ==========

function Binds.CreateDisplayGUI()
    if Binds.DisplayGui then
        Binds.DisplayGui:Destroy()
    end
    
    local playerGui = Nexus.Player:WaitForChild("PlayerGui")
    
    Binds.DisplayGui = Instance.new("ScreenGui")
    Binds.DisplayGui.Name = "KeybindsDisplay"
    Binds.DisplayGui.DisplayOrder = 100
    Binds.DisplayGui.ResetOnSpawn = false
    Binds.DisplayGui.IgnoreGuiInset = true
    Binds.DisplayGui.Parent = playerGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 180, 0, 0)
    container.Position = UDim2.new(1, -185, 0, 10)
    container.AnchorPoint = Vector2.new(1, 0)
    container.Parent = Binds.DisplayGui
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.Parent = container
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 4)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    uiListLayout.Parent = scrollFrame
    
    Binds.UpdateDisplay()
end

function Binds.UpdateDisplay()
    if not Binds.DisplayGui then return end
    
    local scrollFrame = Binds.DisplayGui.Container.ScrollFrame
    scrollFrame:ClearAllChildren()
    
    local sortedKeys = {}
    for funcName, _ in pairs(Binds.ActiveKeybinds) do
        table.insert(sortedKeys, funcName)
    end
    
    table.sort(sortedKeys)
    
    for _, funcName in ipairs(sortedKeys) do
        local data = Binds.ActiveKeybinds[funcName]
        if data and data.key ~= "" then
            Binds.CreateKeybindDisplay(scrollFrame, data.displayName, data.key)
        end
    end
    
    -- Обновляем размер контейнера на основе количества элементов
    local itemCount = #sortedKeys
    local itemHeight = 28
    local padding = 4
    local maxHeight = 400 -- Максимальная высота перед появлением скролла
    
    local totalHeight = (itemHeight + padding) * itemCount - padding
    if totalHeight > maxHeight then
        totalHeight = maxHeight
    end
    
    Binds.DisplayGui.Container.Size = UDim2.new(0, 180, 0, totalHeight)
end

function Binds.CreateKeybindDisplay(parent, displayName, key)
    local frame = Instance.new("Frame")
    frame.Name = "Keybind_" .. displayName
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.2
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.Parent = parent
    frame.LayoutOrder = #parent:GetChildren()
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 4)
    uiCorner.Parent = frame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(50, 50, 50)
    uiStroke.Thickness = 1
    uiStroke.Transparency = 0.5
    uiStroke.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = displayName
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.7, -5, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "Key"
    keyLabel.Text = tostring(key)
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextSize = 12
    keyLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Size = UDim2.new(0.3, -8, 1, 0)
    keyLabel.Position = UDim2.new(0.7, 0, 0, 0)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Right
    keyLabel.Parent = frame
end

function Binds.UpdateKeybindDisplay(funcName, displayName, key)
    if key and key ~= "" then
        Binds.ActiveKeybinds[funcName] = {
            displayName = displayName,
            key = key
        }
        print("[Keybinds] " .. displayName .. " -> " .. tostring(key))
    else
        Binds.ActiveKeybinds[funcName] = nil
    end
    
    Binds.UpdateDisplay()
end

-- ========== CURSOR UNLOCK FUNCTIONS ==========

function Binds.ToggleCursorUnlock()
    if Binds.CursorUnlock.enabled then
        Binds.DisableCursorUnlock()
    else
        Binds.EnableCursorUnlock()
    end
end

function Binds.EnableCursorUnlock()
    if Binds.CursorUnlock.enabled then return end
    Binds.CursorUnlock.enabled = true
    
    if not Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection = Nexus.Services.RunService.Heartbeat:Connect(function()
            pcall(function()
                if Nexus.Services.UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default or
                   Nexus.Services.UserInputService.MouseIconEnabled ~= true then
                    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    Nexus.Services.UserInputService.MouseIconEnabled = true
                end
            end)
        end)
    end
    
    Nexus.Fluent:Notify({
        Title = "Cursor Unlock",
        Content = "Cursor unlocked and visible",
        Duration = 2
    })
    print("Cursor unlocked - cursor visible")
end

function Binds.DisableCursorUnlock()
    if not Binds.CursorUnlock.enabled then return end
    Binds.CursorUnlock.enabled = false
    
    if Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection:Disconnect()
        Binds.CursorUnlock.connection = nil
    end
    
    pcall(function()
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Nexus.Services.UserInputService.MouseIconEnabled = false
    end)
    
    Nexus.Fluent:Notify({
        Title = "Cursor Unlock", 
        Content = "Cursor locked and hidden",
        Duration = 2
    })
    print("Cursor locked - cursor hidden")
end

function Binds.ResetCursorState()
    if Binds.CursorUnlock.connection then
        Binds.CursorUnlock.connection:Disconnect()
        Binds.CursorUnlock.connection = nil
    end
    Binds.CursorUnlock.enabled = false
    
    pcall(function()
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Nexus.Services.UserInputService.MouseIconEnabled = true
    end)
    print("Cursor state reset to default")
end

-- ========== KEYBIND FUNCTIONS ==========

function Binds.ToggleOption(optionName)
    local option = Nexus.Options[optionName]
    if option then
        local currentState = option.Value
        option:SetValue(not currentState)
        
        Nexus.Fluent:Notify({
            Title = "Keybind",
            Content = optionName .. " " .. (not currentState and "enabled" or "disabled"),
            Duration = 2
        })
    end
end

function Binds.HandleKeybindChange(funcName, displayName, newKey)
    print("Keybind changed for " .. displayName .. " to: " .. tostring(newKey))
    
    Nexus.Fluent:Notify({
        Title = "Keybind Updated",
        Content = displayName .. " key set to: " .. tostring(newKey),
        Duration = 2
    })
    
    Binds.UpdateKeybindDisplay(funcName, displayName, newKey)
end

-- ========== CLEANUP ==========

function Binds.Cleanup()
    Binds.DisableCursorUnlock()
    Binds.ResetCursorState()
    
    if Binds.DisplayGui then
        Binds.DisplayGui:Destroy()
        Binds.DisplayGui = nil
    end
    
    Binds.ActiveKeybinds = {}
    
    print("Binds module cleaned up")
end

return Binds
