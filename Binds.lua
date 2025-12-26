-- Binds Module - Keybinds for all functions
local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    CursorUnlock = {
        enabled = false,
        connection = nil
    },
    KeyDisplay = {
        gui = nil,
        container = nil,
        activeBinds = {}, -- Хранит активные бинды: {["AutoParry"] = "F1", ["WalkSpeed"] = "F2", ...}
    }
}

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    -- ========== CREATE KEY DISPLAY GUI ==========
    Binds.CreateKeyDisplay()
    
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
                -- Добавляем/обновляем бинд на экране
                Binds.UpdateKeyDisplay("Cursor Toggle", newKey)
                print("[BINDS] Cursor Toggle назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("AutoParry", newKey)
            -- Добавляем/обновляем бинд на экране
            Binds.UpdateKeyDisplay("AutoParry", newKey)
            print("[BINDS] AutoParry назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("AutoParryV2", newKey)
            Binds.UpdateKeyDisplay("AutoParryV2", newKey)
            print("[BINDS] AutoParryV2 назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("Heal", newKey)
            Binds.UpdateKeyDisplay("Heal", newKey)
            print("[BINDS] Heal назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("InstantHeal", newKey)
            Binds.UpdateKeyDisplay("InstantHeal", newKey)
            print("[BINDS] InstantHeal назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("SilentHeal", newKey)
            Binds.UpdateKeyDisplay("SilentHeal", newKey)
            print("[BINDS] SilentHeal назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("GateTool", newKey)
            Binds.UpdateKeyDisplay("GateTool", newKey)
            print("[BINDS] GateTool назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("NoHitbox", newKey)
            Binds.UpdateKeyDisplay("NoHitbox", newKey)
            print("[BINDS] NoHitbox назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("AutoPerfectSkill", newKey)
            Binds.UpdateKeyDisplay("AutoPerfectSkill", newKey)
            print("[BINDS] AutoPerfectSkill назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("OneHitKill", newKey)
            Binds.UpdateKeyDisplay("OneHitKill", newKey)
            print("[BINDS] OneHitKill назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("AntiBlind", newKey)
            Binds.UpdateKeyDisplay("AntiBlind", newKey)
            print("[BINDS] AntiBlind назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("NoSlowdown", newKey)
            Binds.UpdateKeyDisplay("NoSlowdown", newKey)
            print("[BINDS] NoSlowdown назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("DestroyPallets", newKey)
            Binds.UpdateKeyDisplay("DestroyPallets", newKey)
            print("[BINDS] DestroyPallets назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("BreakGenerator", newKey)
            Binds.UpdateKeyDisplay("BreakGenerator", newKey)
            print("[BINDS] BreakGenerator назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("InfiniteLunge", newKey)
            Binds.UpdateKeyDisplay("InfiniteLunge", newKey)
            print("[BINDS] InfiniteLunge назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("WalkSpeed", newKey)
            Binds.UpdateKeyDisplay("WalkSpeed", newKey)
            print("[BINDS] WalkSpeed назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("Noclip", newKey)
            Binds.UpdateKeyDisplay("Noclip", newKey)
            print("[BINDS] Noclip назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("FOVChanger", newKey)
            Binds.UpdateKeyDisplay("FOVChanger", newKey)
            print("[BINDS] FOVChanger назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("Fly", newKey)
            Binds.UpdateKeyDisplay("Fly", newKey)
            print("[BINDS] Fly назначен на клавишу: " .. tostring(newKey))
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
            Binds.HandleKeybindChange("FreeCamera", newKey)
            Binds.UpdateKeyDisplay("FreeCamera", newKey)
            print("[BINDS] FreeCamera назначен на клавишу: " .. tostring(newKey))
        end
    })
end

-- ========== KEY DISPLAY FUNCTIONS ==========

function Binds.CreateKeyDisplay()
    -- Создаем GUI для отображения клавиш
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeybindDisplay"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Контейнер для горизонтального расположения биндов
    local container = Instance.new("Frame")
    container.Name = "KeybindContainer"
    container.Size = UDim2.new(1, 0, 0, 40) -- Растягиваем на всю ширину, высота 40px
    container.Position = UDim2.new(0, 0, 0, 5) -- Вверху экрана
    container.BackgroundTransparency = 1 -- Полностью прозрачный фон
    container.Visible = true
    
    -- Layout для горизонтального расположения
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 15) -- Расстояние между элементами
    layout.Parent = container
    
    container.Parent = screenGui
    
    -- Сохраняем ссылки
    Binds.KeyDisplay.gui = screenGui
    Binds.KeyDisplay.container = container
    Binds.KeyDisplay.bindFrames = {} -- Хранит созданные фреймы для биндов
    
    -- Встраиваем GUI в игровое окно
    if Nexus and Nexus.Player then
        screenGui.Parent = Nexus.Player:WaitForChild("PlayerGui")
    else
        screenGui.Parent = game:GetService("CoreGui")
    end
    
    print("[BINDS] Key display created")
end

function Binds.FormatKeyName(key)
    if not key or key == "" then
        return "None"
    end
    
    -- Форматируем клавиши для лучшего отображения
    local keyMap = {
        ["LeftControl"] = "L-Ctrl",
        ["RightControl"] = "R-Ctrl",
        ["LeftShift"] = "L-Shift",
        ["RightShift"] = "R-Shift",
        ["LeftAlt"] = "L-Alt",
        ["RightAlt"] = "R-Alt",
        ["Return"] = "Enter",
        ["Escape"] = "Esc",
        ["Backspace"] = "Back",
        ["Space"] = "Space",
        ["Tab"] = "Tab",
        ["CapsLock"] = "Caps",
        ["Insert"] = "Ins",
        ["Delete"] = "Del",
        ["Home"] = "Home",
        ["End"] = "End",
        ["PageUp"] = "PgUp",
        ["PageDown"] = "PgDn",
        ["Up"] = "↑",
        ["Down"] = "↓",
        ["Left"] = "←",
        ["Right"] = "→",
    }
    
    return keyMap[key] or key
end

function Binds.UpdateKeyDisplay(bindName, key)
    -- Если клавиша пустая, удаляем бинд
    if not key or key == "" then
        Binds.RemoveBindDisplay(bindName)
        return
    end
    
    -- Обновляем список активных биндов
    Binds.KeyDisplay.activeBinds[bindName] = key
    
    -- Обновляем отображение
    Binds.RefreshDisplay()
    
    print("[BINDS] Updated display: " .. bindName .. " = " .. key)
end

function Binds.RemoveBindDisplay(bindName)
    -- Удаляем из списка активных биндов
    Binds.KeyDisplay.activeBinds[bindName] = nil
    
    -- Обновляем отображение
    Binds.RefreshDisplay()
    
    print("[BINDS] Removed from display: " .. bindName)
end

function Binds.RefreshDisplay()
    -- Удаляем старые фреймы
    if Binds.KeyDisplay.bindFrames then
        for _, frame in pairs(Binds.KeyDisplay.bindFrames) do
            frame:Destroy()
        end
        Binds.KeyDisplay.bindFrames = {}
    end
    
    -- Создаем новые фреймы для каждого активного бинда
    local container = Binds.KeyDisplay.container
    if not container then return end
    
    local sortedBinds = {}
    for bindName, key in pairs(Binds.KeyDisplay.activeBinds) do
        table.insert(sortedBinds, {name = bindName, key = key})
    end
    
    -- Сортируем по алфавиту для красивого отображения
    table.sort(sortedBinds, function(a, b)
        return a.name < b.name
    end)
    
    for _, bind in ipairs(sortedBinds) do
        if bind.key and bind.key ~= "" then
            -- Создаем фрейм для одного бинда
            local frame = Instance.new("Frame")
            frame.Name = "BindFrame_" .. bind.name
            frame.Size = UDim2.new(0, 0, 0, 30) -- Автоматическая ширина
            frame.BackgroundTransparency = 1 -- Прозрачный фон
            frame.BorderSizePixel = 0
            
            -- Текст бинда
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "BindText"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый цвет
            textLabel.Text = bind.name .. ": [" .. Binds.FormatKeyName(bind.key) .. "]"
            textLabel.Font = Enum.Font.GothamMedium
            textLabel.TextSize = 16
            textLabel.TextWrapped = false
            textLabel.TextXAlignment = Enum.TextXAlignment.Center
            textLabel.TextYAlignment = Enum.TextYAlignment.Center
            
            -- Тень текста для лучшей читаемости
            local textShadow = Instance.new("UIStroke")
            textShadow.Color = Color3.fromRGB(0, 0, 0)
            textShadow.Thickness = 1.5
            textShadow.Transparency = 0.2
            textShadow.Parent = textLabel
            
            textLabel.Parent = frame
            frame.Parent = container
            
            -- Сохраняем ссылку
            table.insert(Binds.KeyDisplay.bindFrames, frame)
            
            -- Автоматически подстраиваем ширину под текст
            local textSize = game:GetService("TextService"):GetTextSize(
                textLabel.Text,
                textLabel.TextSize,
                textLabel.Font,
                Vector2.new(1000, 30)
            )
            frame.Size = UDim2.new(0, textSize.X + 20, 0, 30)
        end
    end
    
    -- Показываем или скрываем контейнер в зависимости от наличия биндов
    if #sortedBinds > 0 then
        container.Visible = true
    else
        container.Visible = false
    end
end

function Binds.ShowAllBinds()
    -- Показывает все назначенные бинды в консоли
    print("=== НАЗНАЧЕННЫЕ БИНДЫ ===")
    for bindName, key in pairs(Binds.KeyDisplay.activeBinds) do
        if key and key ~= "" then
            print(bindName .. ": [" .. Binds.FormatKeyName(key) .. "]")
        end
    end
    print("=========================")
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

function Binds.HandleKeybindChange(optionName, newKey)
    print("[BINDS] Keybind changed for " .. optionName .. " to: " .. tostring(newKey))
    
    Nexus.Fluent:Notify({
        Title = "Keybind Updated",
        Content = optionName .. " key set to: " .. tostring(newKey),
        Duration = 2
    })
end

-- ========== CLEANUP ==========

function Binds.Cleanup()
    Binds.DisableCursorUnlock()
    Binds.ResetCursorState()
    
    -- Удаляем GUI
    if Binds.KeyDisplay.gui then
        Binds.KeyDisplay.gui:Destroy()
        Binds.KeyDisplay.gui = nil
    end
    
    -- Очищаем данные
    Binds.KeyDisplay.activeBinds = {}
    Binds.KeyDisplay.bindFrames = {}
    
    print("[BINDS] Binds module cleaned up")
end

return Binds
