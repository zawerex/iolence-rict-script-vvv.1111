if not _G.NEXUS_LOADER_AUTH then
    error("Access denied: Script must be loaded through Nexus loader")
end
_G.NEXUS_LOADER_AUTH = nil

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/gffff"))() 
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/InterfaceManager/refs/heads/main/InterfaceManager.lua"))()

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

local IS_MOBILE = (Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled)
local IS_DESKTOP = (Services.UserInputService.KeyboardEnabled and not Services.UserInputService.TouchEnabled)

local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

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

local function createUI()
    local windowSize = _G.Nexus.IS_MOBILE and UDim2.fromOffset(350, 200) or UDim2.fromOffset(595, 435)
    
    _G.Nexus.Window = Fluent:CreateWindow({
        Title = "NEXUS",
        SubTitle = "Violence District",
        Search = false,
        Icon = "",
        TabWidth = 120,
        Size = windowSize,  
        Acrylic = false,
        Theme = "AMOLED",
        MinimizeKey = Enum.KeyCode.LeftAlt,
        UserInfo = true,
        UserInfoTop = false,
        UserInfoTitle = _G.Nexus.Player.DisplayName,
        UserInfoSubtitle = "Free Plan",
        UserInfoSubtitleColor = Color3.fromRGB(255, 255, 255)
    })

    _G.Nexus.Tabs = {}
    _G.Nexus.Tabs.Main = _G.Nexus.Window:AddTab({ Title = "Survivor", Icon = "user" })
    _G.Nexus.Tabs.Killer = _G.Nexus.Window:AddTab({ Title = "Killer", Icon = "sword" })
    _G.Nexus.Tabs.Movement = _G.Nexus.Window:AddTab({ Title = "Movement", Icon = "pipette" })
    _G.Nexus.Tabs.Fun = _G.Nexus.Window:AddTab({ Title = "Other", Icon = "list" })
    _G.Nexus.Tabs.Visual = _G.Nexus.Window:AddTab({ Title = "Visual & ESP", Icon = "eye" })
    
    if _G.Nexus.IS_DESKTOP then
        _G.Nexus.Tabs.Binds = _G.Nexus.Window:AddTab({ Title = "Binds", Icon = "toggle-right" })
    end
    
    return true
end

local ModuleUrls = {
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


while loaded < total do
    Services.RunService.Heartbeat:Wait()
end

createUI()

local function initModule(name)
    local module = _G.Nexus.Modules[name]
    if module and module.Init then
        return pcall(module.Init, _G.Nexus)
    end
    return false
end

local initOrder = {"Survivor", "Killer", "Movement", "Fun", "Visual", "Binds"}

for _, name in ipairs(initOrder) do
    if _G.Nexus.Modules[name] then
        initModule(name)
    end
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("NexusHUB")
SaveManager:SetFolder("NexusHUBHub/violence-district")

if _G.Nexus.Window then
    _G.Nexus.Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings-2" })
    
    InterfaceManager:BuildInterfaceSection(_G.Nexus.Tabs.Settings)
    SaveManager:BuildConfigSection(_G.Nexus.Tabs.Settings)
    
    _G.Nexus.Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()
end

local notificationContent = IS_MOBILE and "Nexus loaded (Mobile)" or "Nexus loaded"
Fluent:Notify({
    Title = "Nexus",
    Content = notificationContent,
    Duration = 4.5
})

local function cleanup()
    for _, module in pairs(_G.Nexus.Modules) do
        if module and type(module.Cleanup) == "function" then
            pcall(module.Cleanup)
        end
    end
end

Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        cleanup()
    end
end)

_G.Nexus.Cleanup = cleanup

return _G.Nexus

