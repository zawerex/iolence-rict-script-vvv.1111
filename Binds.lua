local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    ActiveKeybinds = {},
    KeyStates = {}, -- Для отслеживания состояния каждой клавиши
    CursorUnlock = {
        enabled = false,
        connection = nil
    },
    DisplayGui = nil
}

-- Функция для извлечения чистой буквы клавиши из Enum.KeyCode
function Binds.ExtractKeyName(keyCode)
    if not keyCode or keyCode == "" then
        return ""
    end
    
    local keyString = tostring(keyCode)
    
    -- Если это Enum.KeyCode
    if string.find(keyString, "Enum%.KeyCode%.") then
        -- Извлекаем только часть после точки
        local keyName = string.match(keyString, "Enum%.KeyCode%.(.+)")
        if keyName then
            return keyName
        end
    end
    
    -- Если это уже строка с буквой
    return keyString
end

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
            Binds.UpdateKeybindDisplay("CursorToggle", "Cursor Toggle", newKey)
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
                Binds.UpdateKeyState("AutoParry")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParry", "AutoParry", newKey)
        end
    })
    
    local AutoParryV2Keybind = Tabs.Binds:AddKeybind("AutoParryV2Keybind", {
        Title = "AutoParry (Anti-Stun)",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoParryV2")
                Binds.UpdateKeyState("AutoParryV2")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoParryV2", "AutoParry V2", newKey)
        end
    })
    
    local HealKeybindBinds = Tabs.Binds:AddKeybind("HealKeybindBinds", {
        Title = "Heal",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Heal")
                Binds.UpdateKeyState("Heal")
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
                Binds.UpdateKeyState("InstantHeal")
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
                Binds.UpdateKeyState("SilentHeal")
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
                Binds.UpdateKeyState("GateTool")
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
                Binds.UpdateKeyState("NoHitbox")
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
                Binds.UpdateKeyState("AntiFailGenerator")
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
                Binds.UpdateKeyState("AutoPerfectSkill")
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
                Binds.UpdateKeyState("OneHitKill")
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
                Binds.UpdateKeyState("AntiBlind")
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
                Binds.UpdateKeyState("NoSlowdown")
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
                Binds.UpdateKeyState("DestroyPallets")
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
                Binds.UpdateKeyState("BreakGenerator")
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
                Binds.UpdateKeyState("InfiniteLunge")
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
                Binds.UpdateKeyState("WalkSpeed")
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
                Binds.UpdateKeyState("Noclip")
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
                Binds.UpdateKeyState("FOVChanger")
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
                Binds.UpdateKeyState("Fly")
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
                Binds.UpdateKeyState("FreeCamera")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FreeCamera", "Free Camera", newKey)
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
    container.Size = UDim2.new(0, 250, 0, 0) -- Увеличена ширина для длинного текста
    container.Position = UDim2.new(1, -5, 0, 110) -- Правее, почти вплотную к краю
    container.AnchorPoint = Vector2.new(1, 0)
    container.Parent = Binds.DisplayGui
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ScrollBarThickness = 0
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
    
    -- Полностью очищаем старые элементы
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local sortedKeys = {}
    for funcName, _ in pairs(Binds.ActiveKeybinds) do
        table.insert(sortedKeys, funcName)
    end
    
    table.sort(sortedKeys)
    
    for _, funcName in ipairs(sortedKeys) do
        local data = Binds.ActiveKeybinds[funcName]
        if data and data.key ~= "" then
            local cleanKey = Binds.ExtractKeyName(data.key)
            Binds.CreateKeybindDisplay(scrollFrame, data.displayName, cleanKey, funcName)
        end
    end
    
    -- Обновляем размер контейнера на основе количества элементов
    local itemCount = #sortedKeys
    local itemHeight = 20
    local padding = 4
    local maxHeight = 400
    
    local totalHeight = (itemHeight + padding) * itemCount - padding
    if totalHeight > maxHeight then
        totalHeight = maxHeight
    elseif totalHeight < 0 then
        totalHeight = 0
    end
    
    Binds.DisplayGui.Container.Size = UDim2.new(0, 250, 0, totalHeight)
end

function Binds.CreateKeybindDisplay(parent, displayName, key, funcName)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Keybind_" .. funcName
    textLabel.Text = displayName .. " - " .. key
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 0, 20)
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.TextTruncate = Enum.TextTruncate.None -- Убираем обрезку текста
    textLabel.TextWrapped = false -- Не переносить текст
    textLabel.RichText = false
    textLabel.Parent = parent
    
    -- Получаем текущее состояние для этой функции
    local option = Nexus.Options[funcName]
    if option then
        Binds.UpdateKeyColor(textLabel, option.Value)
    else
        -- Для CursorToggle и других без опций
        Binds.UpdateKeyColor(textLabel, Binds.KeyStates[funcName] or false)
    end
end

function Binds.UpdateKeyColor(textLabel, isEnabled)
    if not textLabel or not textLabel.Parent then return end
    
    -- Меняем цвет всего текста (и названия и клавиши) в зависимости от состояния
    if isEnabled then
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Зеленый при включении
    else
        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Красный при выключении
    end
end

function Binds.UpdateKeyState(funcName)
    -- Обновляем состояние в таблице
    local option = Nexus.Options[funcName]
    if option then
        Binds.KeyStates[funcName] = option.Value
    else
        -- Для функций без опций (например, CursorToggle)
        if Binds.KeyStates[funcName] == nil then
            Binds.KeyStates[funcName] = false
        else
            Binds.KeyStates[funcName] = not Binds.KeyStates[funcName]
        end
    end
    
    -- Обновляем цвет текста в отображении
    if Binds.DisplayGui then
        local scrollFrame = Binds.DisplayGui.Container.ScrollFrame
        local textLabel = scrollFrame:FindFirstChild("Keybind_" .. funcName)
        if textLabel then
            Binds.UpdateKeyColor(textLabel, Binds.KeyStates[funcName])
        end
    end
end

function Binds.UpdateKeybindDisplay(funcName, displayName, key)
    if displayName and key then
        local cleanKey = Binds.ExtractKeyName(key)
        if cleanKey ~= "" then
            Binds.ActiveKeybinds[funcName] = {
                displayName = displayName,
                key = cleanKey
            }
            print("[Keybinds] " .. displayName .. " -> " .. cleanKey)
        else
            Binds.ActiveKeybinds[funcName] = nil
            Binds.KeyStates[funcName] = nil
        end
    end
    
    -- Обновляем отображение
    Binds.UpdateDisplay()
end

-- ========== CURSOR UNLOCK FUNCTIONS ==========

function Binds.ToggleCursorUnlock()
    if Binds.CursorUnlock.enabled then
        Binds.DisableCursorUnlock()
        Binds.KeyStates["CursorToggle"] = false
    else
        Binds.EnableCursorUnlock()
        Binds.KeyStates["CursorToggle"] = true
    end
    
    -- Обновляем цвет для CursorToggle
    Binds.UpdateKeyState("CursorToggle")
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
    end
end

function Binds.HandleKeybindChange(funcName, displayName, newKey)
    local cleanKey = Binds.ExtractKeyName(newKey)
    print("Keybind changed for " .. displayName .. " to: " .. cleanKey)
    
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
    Binds.KeyStates = {}
    
    print("Binds module cleaned up")
end

return Binds
