-- ==============================================
-- NEXUS - Violence District (Modular Structure)
-- ==============================================

-- Загрузка основных библиотек
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/govno435345/refs/heads/main/g"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Инициализация сервисов
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Определение платформы
local UIS = UserInputService
local IS_MOBILE = (UIS.TouchEnabled and not UIS.KeyboardEnabled)
local IS_DESKTOP = (UIS.KeyboardEnabled and not UIS.TouchEnabled)

-- Глобальные переменные
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Глобальный объект для хранения всех данных
_G.Nexus = {
    Player = player,
    Camera = camera,
    Services = {
        Players = Players,
        RunService = RunService,
        UserInputService = UserInputService,
        Lighting = Lighting,
        Workspace = Workspace,
        ReplicatedStorage = ReplicatedStorage,
        VirtualInputManager = VirtualInputManager,
        TweenService = TweenService
    },
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
    },
    Connections = {}
}

-- Функция для безопасного выполнения callback
local function SafeCallback(callback, ...)
    if type(callback) == "function" then
        local success, result = pcall(callback, ...)
        if not success then
            warn("Callback error:", result)
        end
        return success
    end
    return false
end

_G.Nexus.SafeCallback = SafeCallback

-- Функция для безопасного отключения соединений
local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() 
            conn:Disconnect() 
        end)
    end
    return nil
end

_G.Nexus.safeDisconnect = safeDisconnect

-- Вспомогательные функции
local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

_G.Nexus.getCharacter = getCharacter
_G.Nexus.getHumanoid = getHumanoid
_G.Nexus.getRootPart = getRootPart

-- Функция загрузки модулей с GitHub
local function loadModule(url)
    local success, module = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success then
        return module
    else
        warn("Failed to load module from: " .. url)
        return nil
    end
end

-- Загрузка модулей
local modulesToLoad = {
    ["Helpers"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/helpers.lua",
    ["UI"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/UI.lua",
    ["Survivor"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Survivor%20Module.lua",
    ["Killer"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Killer.lua",
    ["Movement"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Movement.lua",
    ["Fun"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Fun.lua",
    ["Visual"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Visual.lua",
    ["Binds"] = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Binds.lua"
}

-- Загрузка каждого модуля
for moduleName, url in pairs(modulesToLoad) do
    local module = loadModule(url)
    if module then
        _G.Nexus.Modules[moduleName] = module
        print("✓ Loaded module:", moduleName)
    end
end

-- Проверяем, загрузились ли все модули
if not _G.Nexus.Modules.UI then
    -- Создаем простой UI модуль если не загрузился
    warn("UI module failed to load, creating basic UI...")
    _G.Nexus.Modules.UI = require(script.UI)
end

-- Инициализация
local function initializeNexus()
    print("Initializing Nexus...")
    
    -- Инициализация UI
    if _G.Nexus.Modules.UI and _G.Nexus.Modules.UI.Init then
        _G.Nexus.Modules.UI.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Survivor
    if _G.Nexus.Modules.Survivor and _G.Nexus.Modules.Survivor.Init then
        _G.Nexus.Modules.Survivor.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Killer
    if _G.Nexus.Modules.Killer and _G.Nexus.Modules.Killer.Init then
        _G.Nexus.Modules.Killer.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Movement
    if _G.Nexus.Modules.Movement and _G.Nexus.Modules.Movement.Init then
        _G.Nexus.Modules.Movement.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Fun
    if _G.Nexus.Modules.Fun and _G.Nexus.Modules.Fun.Init then
        _G.Nexus.Modules.Fun.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Visual
    if _G.Nexus.Modules.Visual and _G.Nexus.Modules.Visual.Init then
        _G.Nexus.Modules.Visual.Init(_G.Nexus)
    end
    
    -- Инициализация вкладки Binds
    if _G.Nexus.Modules.Binds and _G.Nexus.Modules.Binds.Init then
        _G.Nexus.Modules.Binds.Init(_G.Nexus)
    end
    
    -- Настройка сохранения
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/violence-district")
    
    -- Добавляем вкладку Settings
    if _G.Nexus.Window then
        local Tabs = _G.Nexus.Tabs
        Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
        
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        
        _G.Nexus.Window:SelectTab(1)
    end
    
    -- Загружаем сохраненную конфигурацию
    SaveManager:LoadAutoloadConfig()
    
    -- Уведомление о загрузке
    if IS_MOBILE then
        Fluent:Notify({
            Title = "Nexus",
            Content = "Nexus script loaded (Mobile Version)",
            Duration = 5.5
        })
    else
        Fluent:Notify({
            Title = "Nexus",
            Content = "The script has been loaded",
            Duration = 5
        })
    end
    
    print("✅ Nexus initialized successfully!")
end

-- Запуск инициализации
pcall(initializeNexus)

-- Обработка выхода игрока
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        -- Очистка всех соединений
        for _, connection in pairs(_G.Nexus.Connections) do
            safeDisconnect(connection)
        end
        _G.Nexus.Connections = {}
        
        -- Вызов функции очистки из всех модулей
        for moduleName, module in pairs(_G.Nexus.Modules) do
            if module.Cleanup then
                SafeCallback(module.Cleanup)
            end
        end
    end
end)

return _G.Nexus
