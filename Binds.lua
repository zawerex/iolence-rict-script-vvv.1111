-- Binds Module - Keybinds for all functions
local Nexus = _G.Nexus

local Binds = {
    Keybinds = {},
    CursorUnlock = {
        enabled = false,
        connection = nil
    }
}

function Binds.Init(nxs)
    Nexus = nxs
    
    if not Nexus.IS_DESKTOP then return end
    
    local Tabs = Nexus.Tabs
    if not Tabs.Binds then return end
    
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
            Binds.HandleKeybindChange("AntiFailGenerator", newKey)
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
            Binds.HandleKeybindChange("NoShadow", newKey)
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
            Binds.HandleKeybindChange("NoFog", newKey)
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
            Binds.HandleKeybindChange("FullBright", newKey)
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
            Binds.HandleKeybindChange("TimeChanger", newKey)
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
            Binds.HandleKeybindChange("ESPSurvivors", newKey)
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
            Binds.HandleKeybindChange("ESPKillers", newKey)
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
            Binds.HandleKeybindChange("ESPHooks", newKey)
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
            Binds.HandleKeybindChange("ESPGenerators", newKey)
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
            Binds.HandleKeybindChange("ESPPallets", newKey)
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
            Binds.HandleKeybindChange("ESPGates", newKey)
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
            Binds.HandleKeybindChange("ESPWindows", newKey)
        end
    })
    
    print("✓ Binds module initialized")
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
    print("Keybind changed for " .. optionName .. " to: " .. tostring(newKey))
    
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
    
    print("Binds module cleaned up")
end

return Binds
