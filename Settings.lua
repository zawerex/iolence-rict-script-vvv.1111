-- Settings.lua - Модуль настроек (только Save Manager и Interface Manager)
local Nexus = require(script.Parent.NexusMain)

local SettingsModule = {}

function SettingsModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local SaveManager = nexus.SaveManager
    local InterfaceManager = nexus.InterfaceManager
    local Fluent = nexus.Fluent
    
    -- ========== SAVE MANAGER И INTERFACE MANAGER ==========
    if SaveManager and InterfaceManager then
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("FluentScriptHub")
        SaveManager:SetFolder("FluentScriptHub/violence-district")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end
    
    -- Только Save Manager и Interface Manager, без дополнительных кнопок или настроек
    
    return SettingsModule
end

return SettingsModule
