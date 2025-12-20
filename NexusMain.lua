-- main.lua - Основной загрузчик Nexus (обновленный)
local UIS = game:GetService("UserInputService")
local IS_MOBILE = (UIS.TouchEnabled and not UIS.KeyboardEnabled)
local IS_DESKTOP = (UIS.KeyboardEnabled and not UIS.TouchEnabled)

-- Получение метатаблицы для хуков
local getrawmetatable = getrawmetatable
if not getrawmetatable then
    getrawmetatable = function() 
        return nil 
    end
end

-- Глобальные сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Глобальные переменные
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Таблица для хранения модулей и их состояния
local Nexus = {
    Modules = {},
    Functions = {},
    Tabs = {},
    Options = {},
    Settings = {},
    Connections = {},
    LoadedTabs = {},
    SaveManager = nil,
    InterfaceManager = nil
}

-- Функция безопасного выполнения
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

-- Функция безопасного отключения соединений
local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() 
            conn:Disconnect() 
        end)
    end
    return nil
end

-- Функции для работы с персонажем
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

-- Загрузка библиотек
local Fluent

local function LoadLibraries()
    local success, fluentResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/zawerex/Nex1/refs/heads/main/Library/Nexus"))()
    end)
    
    if not success then
        warn("Failed to load Fluent library:", fluentResult)
        return false
    end
    
    Fluent = fluentResult
    
    -- Загружаем SaveManager и InterfaceManager
    local success2, saveResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    end)
    
    if success2 then
        Nexus.SaveManager = saveResult
    else
        warn("Failed to load SaveManager:", saveResult)
    end
    
    local success3, interfaceResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
    
    if success3 then
        Nexus.InterfaceManager = interfaceResult
    else
        warn("Failed to load InterfaceManager:", interfaceResult)
    end
    
    return true
end

-- Загрузка модуля с GitHub
local function LoadModuleFromGitHub(url)
    local success, result = pcall(function()
        local content = game:HttpGet(url)
        local moduleFunction, errorMessage = loadstring(content)
        if moduleFunction then
            return moduleFunction()
        else
            error("Failed to load module: " .. (errorMessage or "Unknown error"))
        end
    end)
    
    if success then
        return result
    else
        warn("Failed to load module from", url, ":", result)
        return nil
    end
end

-- Загрузка модуля локально (резервный вариант)
local function LoadModuleLocally(moduleName)
    -- Резервные встроенные модули (можно добавить при необходимости)
    return nil
end

-- Основная функция загрузки модуля
local function LoadModule(tabName)
    if Nexus.LoadedTabs[tabName] then
        return Nexus.LoadedTabs[tabName]
    end
    
    -- URL для GitHub модулей (обновите на свои реальные ссылки)
    local githubUrls = {
        Survivor = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Survivor%20Module.lua",
        Killer = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Killer.lua",
        Movement = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Movement.lua",
        Visual = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Visual.lua",
        Fun = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Fun.lua",
        Binds = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Binds.lua",
        Settings = "https://raw.githubusercontent.com/zawerex/iolence-rict-script-vvv.1111/refs/heads/main/Settings.lua"
    }
    
    local moduleUrl = githubUrls[tabName]
    local module
    
    if moduleUrl then
        module = LoadModuleFromGitHub(moduleUrl)
    end
    
    -- Если загрузка с GitHub не удалась, пробуем локальную загрузку
    if not module then
        module = LoadModuleLocally(tabName)
    end
    
    if module then
        Nexus.LoadedTabs[tabName] = module
        return module
    end
    
    return nil
end

-- Инициализация главного окна
local function InitializeWindow()
    local windowSize = IS_MOBILE and UDim2.fromOffset(350, 200) or UDim2.fromOffset(570, 550)
    
    local Window = Fluent:CreateWindow({
        Title = "NEXUS",
        SubTitle = "Violence District",
        Search = false,
        Icon = "",
        TabWidth = 120,
        Size = windowSize,  
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl,
        UserInfo = true,
        UserInfoTop = false,
        UserInfoTitle = player.DisplayName,
        UserInfoSubtitle = "user",
        UserInfoSubtitleColor = Color3.fromRGB(255, 250, 250)
    })
    
    Nexus.Window = Window
    Nexus.Options = Fluent.Options
    
    -- Создание вкладок
    Nexus.Tabs = {
        Main = Window:AddTab({ Title = "Survivor", Icon = "snowflake" }),
        Killer = Window:AddTab({ Title = "Killer", Icon = "snowflake" }),
        Movement = Window:AddTab({ Title = "Movement", Icon = "snowflake" }), 
        Fun = Window:AddTab({ Title = "Other", Icon = "snowflake" }),
        Visual = Window:AddTab({ Title = "Visual & ESP", Icon = "snowflake" }),
    }
    
    if IS_DESKTOP then
        Nexus.Tabs.Binds = Window:AddTab({ Title = "Binds", Icon = "snowflake" })
    end
    
    -- Settings всегда последняя
    Nexus.Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "snowflake" })
    
    -- Минимайзер для мобильных устройств
    if IS_MOBILE then
        Nexus.Minimizer = Fluent:CreateMinimizer({
            Icon = "snowflake",
            Size = UDim2.fromOffset(21, 21),
            Position = UDim2.new(0, 320, 0, 24),
            Acrylic = true,
            Corner = 8,
            Transparency = 0.9,
            Draggable = true,
            Visible = true
        })
    end
    
    return Window
end

-- Основная функция инициализации
local function InitializeNexus()
    -- Загружаем библиотеки
    if not LoadLibraries() then
        warn("Failed to load required libraries")
        return false
    end
    
    -- Инициализируем окно
    InitializeWindow()
    
    -- Начинаем загрузку модулей
    task.spawn(function()
        -- Загружаем основные модули
        local coreModules = {"Survivor", "Killer", "Movement", "Visual", "Fun"}
        
        for _, moduleName in ipairs(coreModules) do
            task.spawn(function()
                local module = LoadModule(moduleName)
                if module and module.Initialize then
                    module.Initialize(Nexus)
                end
            end)
            task.wait(0.5) -- Задержка между загрузкой модулей
        end
        
        -- Загружаем Binds только для десктопа
        if IS_DESKTOP then
            task.wait(1)
            local bindsModule = LoadModule("Binds")
            if bindsModule and bindsModule.Initialize then
                bindsModule.Initialize(Nexus)
            end
        end
        
        -- Загружаем Settings (последним)
        task.wait(1)
        local settingsModule = LoadModule("Settings")
        if settingsModule and settingsModule.Initialize then
            settingsModule.Initialize(Nexus)
        end
    end)
    
    -- Выбираем первую вкладку
    Nexus.Window:SelectTab(1)
    
    -- Уведомление об успешной загрузке
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
    
    return true
end

-- Экспорт глобальных функций и сервисов
Nexus.SafeCallback = SafeCallback
Nexus.safeDisconnect = safeDisconnect
Nexus.getCharacter = getCharacter
Nexus.getHumanoid = getHumanoid
Nexus.getRootPart = getRootPart
Nexus.Services = {
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    Lighting = Lighting,
    Workspace = Workspace,
    ReplicatedStorage = ReplicatedStorage,
    VirtualInputManager = VirtualInputManager,
    TweenService = TweenService
}
Nexus.Player = player
Nexus.Camera = camera
Nexus.IS_MOBILE = IS_MOBILE
Nexus.IS_DESKTOP = IS_DESKTOP

-- Глобальное состояние функций
Nexus.FunctionStates = {
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

-- Таблица соединений
Nexus.Connections = {}

-- Запуск инициализации
local success = InitializeNexus()

if not success then
    warn("Nexus initialization failed")
end

-- Возвращаем Nexus для использования другими модулями
return Nexus
