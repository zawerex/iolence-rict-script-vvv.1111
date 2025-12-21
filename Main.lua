local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/g"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Сервисы
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    TweenService = game:GetService("TweenService")
}

-- Платформа
local IS_MOBILE = (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
local IS_DESKTOP = (Services.UserInputService.KeyboardEnabled and not Services.UserInputService.TouchEnabled)

-- Основные переменные
local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- Глобальный Nexus
_G.Nexus = {
    Player = Player,
    Camera = Camera,
    Services = Services,
    IS_MOBILE = IS_MOBILE,
    IS_DESKTOP = IS_DESKTOP,
    Fluent = Fluent,
    Options = Fluent.Options,
    Modules = {},
    States = {
        InstantHealRunning = false,
        SilentHealRunning = false,
        autoHealEnabled = false,
        autoSkillEnabled = false,
        NoSlowdownEnabled = false,
        antiFailEnabled = false,
        noclipEnabled = false,
        fullbrightEnabled = false,
        AutoParryEnabled = false,
        AutoParryV2Enabled = false,
        KillerAntiBlindEnabled = false,
        GateToolEnabled = false,
        InfiniteLungeEnabled = false,
        FlyEnabled = false,
        FreeCameraEnabled = false,
        WalkSpeedEnabled = false,
        OneHitKillEnabled = false,
        DestroyPalletsEnabled = false,
        BreakGeneratorEnabled = false,
        NoFallEnabled = false,
        NoTurnLimitEnabled = false
    }
}

-- ========== ПОЛЕЗНЫЕ ФУНКЦИИ (из Helpers) ==========

-- Основные функции персонажа
_G.Nexus.getCharacter = function()
    return Player.Character
end

_G.Nexus.getHumanoid = function()
    local char = Player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

_G.Nexus.getRootPart = function()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Безопасные функции
_G.Nexus.SafeCallback = function(callback, ...)
    if type(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            warn("Callback error:", result)
        end
        return success
    end
    return false
end

_G.Nexus.safeDisconnect = function(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() 
            conn:Disconnect() 
        end)
    end
    return nil
end

-- Проверка ролей (нужны для модулей)
_G.Nexus.IsKiller = function(targetPlayer)
    targetPlayer = targetPlayer or Player
    if not targetPlayer.Team then return false end
    local teamName = targetPlayer.Team.Name:lower()
    return teamName:find("killer") or teamName == "killer"
end

_G.Nexus.IsSurvivor = function(targetPlayer)
    if not targetPlayer or not targetPlayer.Team then return false end
    local teamName = targetPlayer.Team.Name:lower()
    return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
end

_G.Nexus.GetRole = function(targetPlayer)
    targetPlayer = targetPlayer or Player
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

-- Утилиты (если используются)
_G.Nexus.Notify = function(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

_G.Nexus.FindRemote = function(path)
    local current = Services.ReplicatedStorage
    for _, part in ipairs(path:split("/")) do
        current = current:WaitForChild(part)
    end
    return current
end

_G.Nexus.GetDistance = function(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

_G.Nexus.Clamp = function(value, min, max)
    return math.max(min, math.min(max, value))
end

-- ========== ЗАГРУЗКА МОДУЛЕЙ ==========

local ModuleUrls = {
    UI = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/UI.lua",
    Survivor = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Survivor%20Module.lua",
    Killer = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Killer.lua",
    Movement = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Movement.lua",
    Fun = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Fun.lua",
    Visual = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Visual.lua"
}

if IS_DESKTOP then
    ModuleUrls.Binds = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Binds.lua"
end

local function loadModule(url)
    local success, module = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success then
        return module
    end
    return nil
end

-- Параллельная загрузка
local loaded = 0
local total = 0
for name, url in pairs(ModuleUrls) do
    total = total + 1
    task.spawn(function()
        local module = loadModule(url)
        if module then
            _G.Nexus.Modules[name] = module
            loaded = loaded + 1
        end
    end)
end

-- Ожидание загрузки
while loaded < total do
    Services.RunService.Heartbeat:Wait()
end

-- ========== ИНИЦИАЛИЗАЦИЯ ==========

local function initModule(name)
    local module = _G.Nexus.Modules[name]
    if module and module.Init then
        return pcall(module.Init, _G.Nexus)
    end
    return false
end

-- Порядок инициализации
local initOrder = {"UI", "Survivor", "Killer", "Movement", "Fun", "Visual", "Binds"}

for _, name in ipairs(initOrder) do
    if _G.Nexus.Modules[name] then
        initModule(name)
    end
end

-- Настройка сохранения
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/violence-district")

-- Вкладка Settings
if _G.Nexus.Window then
    local Tabs = _G.Nexus.Tabs
    Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    
    _G.Nexus.Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()
end

-- Уведомление
local notificationContent = IS_MOBILE and "Nexus loaded (Mobile)" or "Nexus loaded"
Fluent:Notify({
    Title = "Nexus",
    Content = notificationContent,
    Duration = 3
})

-- Очистка при выходе
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        for _, module in pairs(_G.Nexus.Modules) do
            if module.Cleanup then
                pcall(module.Cleanup)
            end
        end
    end
end)

return _G.Nexus
