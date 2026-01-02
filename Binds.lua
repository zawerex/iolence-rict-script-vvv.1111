local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    ActiveKeybinds = {},
    KeyStates = {}, 
    CursorUnlock = {
        enabled = false,
        connection = nil,
        mouseLocked = false
    },
    DisplayGui = nil
}


function Binds.ExtractKeyName(keyCode)
    if not keyCode or keyCode == "" then
        return ""
    end
    
    local keyString = tostring(keyCode)
    
    if string.find(keyString, "Enum%.KeyCode%.") then
        local keyName = string.match(keyString, "Enum%.KeyCode%.(.+)")
        if keyName then
            return keyName
        end
    end
    
    return keyString
end

function Binds.ToggleOption(optionName)
    local option = Nexus.Options[optionName]
    if option then
        local currentState = option.Value
        option:SetValue(not currentState)
    end
end

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
    container.Size = UDim2.new(0, 250, 0, 0)
    container.Position = UDim2.new(1, -5, 0, 110)
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
    textLabel.TextTruncate = Enum.TextTruncate.None
    textLabel.TextWrapped = false
    textLabel.RichText = false
    textLabel.Parent = parent
    
    local option = Nexus.Options[funcName]
    if option then
        Binds.UpdateKeyColor(textLabel, option.Value)
    else
        Binds.UpdateKeyColor(textLabel, Binds.KeyStates[funcName] or false)
    end
end

function Binds.UpdateKeyColor(textLabel, isEnabled)
    if not textLabel or not textLabel.Parent then return end
    
    if isEnabled then
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

function Binds.UpdateKeyState(funcName)
    local option = Nexus.Options[funcName]
    if option then
        Binds.KeyStates[funcName] = option.Value
    else
        if Binds.KeyStates[funcName] == nil then
            Binds.KeyStates[funcName] = false
        else
            Binds.KeyStates[funcName] = not Binds.KeyStates[funcName]
        end
    end
    
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
    
    Binds.UpdateDisplay()
end

function Binds.HandleKeybindChange(funcName, displayName, newKey)
    local cleanKey = Binds.ExtractKeyName(newKey)
    print("Keybind changed for " .. displayName .. " to: " .. cleanKey)
    
    Binds.UpdateKeybindDisplay(funcName, displayName, newKey)
end

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
    Binds.CreateDisplayGUI()
    
   Tabs.Binds:AddSection("Binds", "Survivor")
    
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
    
    local AutoSkillKeybind = Tabs.Binds:AddKeybind("AutoSkillKeybind", {
        Title = "Auto Perfect Skill",
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
    
    local NoFallKeybind = Tabs.Binds:AddKeybind("NoFallKeybind", {
        Title = "No Fall",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoFall")
                Binds.UpdateKeyState("NoFall")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoFall", "No Fall", newKey)
        end
    })
    
    local FakeParryKeybind = Tabs.Binds:AddKeybind("FakeParryKeybind", {
        Title = "Fake Parry",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("FakeParry")
                Binds.UpdateKeyState("FakeParry")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("FakeParry", "Fake Parry", newKey)
        end
    })
    
    local HealKeybind = Tabs.Binds:AddKeybind("HealKeybind", {
        Title = "Gamemode",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Heal")
                Binds.UpdateKeyState("Heal")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Heal", "Gamemode", newKey)
        end
    })
    
    local CrosshairKeybind = Tabs.Binds:AddKeybind("CrosshairKeybind", {
        Title = "Crosshair",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Crosshair")
                Binds.UpdateKeyState("Crosshair")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Crosshair", "Crosshair", newKey)
        end
    })
    
    local RainbowCrosshairKeybind = Tabs.Binds:AddKeybind("RainbowCrosshairKeybind", {
        Title = "Rainbow Crosshair",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("RainbowCrosshair")
                Binds.UpdateKeyState("RainbowCrosshair")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("RainbowCrosshair", "Rainbow Xhair", newKey)
        end
    })
    
    local AutoVictoryKeybind = Tabs.Binds:AddKeybind("AutoVictoryKeybind", {
        Title = "Auto Victory",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("AutoVictory")
                Binds.UpdateKeyState("AutoVictory")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("AutoVictory", "Auto Victory", newKey)
        end
    })
    
    Tabs.Binds:AddSection("Killer Binds")
    
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
    
    local KillerNoSlowdownKeybind = Tabs.Binds:AddKeybind("KillerNoSlowdownKeybind", {
        Title = "Killer No Slowdown",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoSlowdownKiller")
                Binds.UpdateKeyState("NoSlowdownKiller")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoSlowdownKiller", "Killer No Slow", newKey)
        end
    })
    
    local HitboxKeybind = Tabs.Binds:AddKeybind("HitboxKeybind", {
        Title = "Hitbox Expand",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("Hitbox")
                Binds.UpdateKeyState("Hitbox")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("Hitbox", "Hitbox Expand", newKey)
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
    
    local ThirdPersonKeybind = Tabs.Binds:AddKeybind("ThirdPersonKeybind", {
        Title = "Third Person",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("ThirdPerson")
                Binds.UpdateKeyState("ThirdPerson")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("ThirdPerson", "Third Person", newKey)
        end
    })
    
    local NoPalletStunKeybind = Tabs.Binds:AddKeybind("NoPalletStunKeybind", {
        Title = "No Pallet Stun",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("NoPalletStun")
                Binds.UpdateKeyState("NoPalletStun")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("NoPalletStun", "No Pallet Stun", newKey)
        end
    })
    
    local DoubleTapKeybind = Tabs.Binds:AddKeybind("DoubleTapKeybind", {
        Title = "Double Tap",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("DoubleTap")
                Binds.UpdateKeyState("DoubleTap")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("DoubleTap", "Double Tap", newKey)
        end
    })
    
    local SpamHookKeybind = Tabs.Binds:AddKeybind("SpamHookKeybind", {
        Title = "Spam Hook",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("SpamHook")
                Binds.UpdateKeyState("SpamHook")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("SpamHook", "Spam Hook", newKey)
        end
    })
    
    local BeatGameKeybind = Tabs.Binds:AddKeybind("BeatGameKeybind", {
        Title = "Beat Game (Killer)",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("BeatGame")
                Binds.UpdateKeyState("BeatGame")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("BeatGame", "Beat Game", newKey)
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
    
    local SpearCrosshairKeybind = Tabs.Binds:AddKeybind("SpearCrosshairKeybind", {
        Title = "Spear Crosshair",
        Mode = "Toggle",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                Binds.ToggleOption("SpearCrosshair")
                Binds.UpdateKeyState("SpearCrosshair")
            end)
        end,
        ChangedCallback = function(newKey)
            Binds.HandleKeybindChange("SpearCrosshair", "Spear Xhair", newKey)
        end
    })
    
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
    
end

function Binds.Cleanup()
    Binds.DisableCursorUnlock()
    Binds.ResetCursorState()
    
    if Binds.DisplayGui then
        Binds.DisplayGui:Destroy()
        Binds.DisplayGui = nil
    end
    
    Binds.ActiveKeybinds = {}
    Binds.KeyStates = {}
    Binds.Keybinds = {}

end

return Binds
