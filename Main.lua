-- ========== ПРЕДВАРИТЕЛЬНЫЙ ЭКРАН ЗАГРУЗКИ ==========
do
    -- Создаем GUI для предзагрузки
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusPreload"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")

    -- Главный контейнер для текста и снежинок
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 500, 0, 150)
    mainContainer.Position = UDim2.new(0.5, -250, 0.5, -75)
    mainContainer.BackgroundTransparency = 1
    mainContainer.BorderSizePixel = 0
    mainContainer.ClipsDescendants = true
    mainContainer.Parent = screenGui

    -- Контейнер для снежинок (внутри основного контейнера)
    local snowContainer = Instance.new("Frame")
    snowContainer.Name = "SnowContainer"
    snowContainer.Size = UDim2.new(1, 0, 1, 0)
    snowContainer.Position = UDim2.new(0, 0, 0, 0)
    snowContainer.BackgroundTransparency = 1
    snowContainer.BorderSizePixel = 0
    snowContainer.ZIndex = 1
    snowContainer.Parent = mainContainer

    -- Текст NEXUS
    local nexusText = Instance.new("TextLabel")
    nexusText.Name = "NexusText"
    nexusText.Size = UDim2.new(1, 0, 1, 0)
    nexusText.Position = UDim2.new(0, 0, 0, 0)
    nexusText.BackgroundTransparency = 1
    nexusText.Text = "NEXUS SCRIPT"
    nexusText.Font = Enum.Font.GothamBlack
    nexusText.TextSize = 25
    nexusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    nexusText.TextTransparency = 1
    nexusText.ZIndex = 10
    nexusText.Parent = mainContainer

    -- Текст Violence District (скрыт сначала)
    local violenceText = Instance.new("TextLabel")
    violenceText.Name = "ViolenceText"
    violenceText.Size = UDim2.new(1, 0, 1, 0)
    violenceText.Position = UDim2.new(0, 0, 0, 0)
    violenceText.BackgroundTransparency = 1
    violenceText.Text = "Violence District"
    violenceText.Font = Enum.Font.GothamMedium
    violenceText.TextSize = 24
    violenceText.TextColor3 = Color3.fromRGB(255, 255, 255)
    violenceText.TextTransparency = 1
    violenceText.ZIndex = 10
    violenceText.Parent = mainContainer

    -- Функция создания маленькой снежинки
    local function createSnowflake()
        local snowflake = Instance.new("Frame")
        local size = math.random(3, 8)  -- Очень маленькие снежинки
        snowflake.Size = UDim2.new(0, size, 0, size)
        snowflake.Position = UDim2.new(
            math.random(),  -- X позиция (0-1)
            math.random(-20, 20),  -- Случайное смещение
            0,  -- Начинаем сверху
            -size  -- Начальная позиция Y
        )
        snowflake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        snowflake.BackgroundTransparency = math.random(5, 8) / 10  -- Прозрачные снежинки
        snowflake.BorderSizePixel = 0
        snowflake.ZIndex = 1
        snowflake.Parent = snowContainer
        
        -- Делаем круглую снежинку
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = snowflake
        
        return snowflake
    end

    -- Анимация появления
    local tweenService = game:GetService("TweenService")
    
    local function showAnimation()
        -- Запускаем снегопад внутри контейнера
        task.spawn(function()
            while snowContainer and snowContainer.Parent do
                -- Создаем несколько снежинок за раз
                for i = 1, math.random(1, 3) do
                    local snowflake = createSnowflake()
                    
                    if snowflake then
                        -- Анимация падения снежинки (медленное падение)
                        local fallTime = math.random(4, 7)
                        local tween = tweenService:Create(snowflake, TweenInfo.new(
                            fallTime,
                            Enum.EasingStyle.Linear
                        ), {
                            Position = UDim2.new(
                                snowflake.Position.X.Scale,
                                snowflake.Position.X.Offset + math.random(-30, 30),
                                1.2,  -- Ниже контейнера
                                math.random(0, 20)
                            ),
                            BackgroundTransparency = 1,
                            Rotation = math.random(-90, 90)
                        })
                        
                        tween:Play()
                        game:GetService("Debris"):AddItem(snowflake, fallTime + 0.3)
                    end
                end
                task.wait(math.random(3, 7) / 10)  -- Интервал между созданием снежинок
            end
        end)
        
        -- Ждем немного
        task.wait(0.3)
        
        -- Появление текста NEXUS
        local nexusAppear = tweenService:Create(nexusText, TweenInfo.new(
            1,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), {
            TextTransparency = 0
        })
        
        nexusAppear:Play()
        
        -- Ждем 1.5 секунды
        task.wait(1.5)
        
        -- Растворение NEXUS
        local nexusDisappear = tweenService:Create(nexusText, TweenInfo.new(
            0.5,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ), {
            TextTransparency = 1
        })
        
        nexusDisappear:Play()
        
        -- Ждем завершения растворения
        task.wait(0.5)
        
        -- Появление Violence District на том же месте
        local violenceAppear = tweenService:Create(violenceText, TweenInfo.new(
            0.8,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ), {
            TextTransparency = 0
        })
        
        violenceAppear:Play()
        
        -- Ждем 1.5 секунды
        task.wait(1.5)
        
        -- Исчезновение Violence District
        local violenceDisappear = tweenService:Create(violenceText, TweenInfo.new(
            0.7,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.In
        ), {
            TextTransparency = 1
        })
        
        violenceDisappear:Play()
        
        -- Удаляем GUI после анимации
        task.wait(1)
        screenGui:Destroy()
    end
    
    -- Запускаем анимацию
    task.spawn(showAnimation)
    
    -- Ждем завершения анимации перед загрузкой библиотек
    task.wait(4)
end
-- ========== ЗАГРУЗКА БИБЛИОТЕК ==========
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

-- ========== СОЗДАНИЕ UI ==========

local function createUI()
    local windowSize = _G.Nexus.IS_MOBILE and UDim2.fromOffset(350, 200) or UDim2.fromOffset(580,550)
    
    -- Создаем главное окно
    _G.Nexus.Window = Fluent:CreateWindow({
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
        UserInfoTitle = _G.Nexus.Player.DisplayName,
        UserInfoSubtitle = "user",
        UserInfoSubtitleColor = Color3.fromRGB(255, 250, 250)
    })
    
    -- Создаем вкладки
    _G.Nexus.Tabs = {}
    _G.Nexus.Tabs.Main = _G.Nexus.Window:AddTab({ Title = "Survivor", Icon = "snowflake" })
    _G.Nexus.Tabs.Killer = _G.Nexus.Window:AddTab({ Title = "Killer", Icon = "snowflake" })
    _G.Nexus.Tabs.Movement = _G.Nexus.Window:AddTab({ Title = "Movement", Icon = "snowflake" })
    _G.Nexus.Tabs.Fun = _G.Nexus.Window:AddTab({ Title = "Other", Icon = "snowflake" })
    _G.Nexus.Tabs.Visual = _G.Nexus.Window:AddTab({ Title = "Visual & ESP", Icon = "snowflake" })
    
    if _G.Nexus.IS_DESKTOP then
        _G.Nexus.Tabs.Binds = _G.Nexus.Window:AddTab({ Title = "Binds", Icon = "snowflake" })
    end
    
    return true
end

-- ========== ЗАГРУЗКА МОДУЛЕЙ ==========

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

-- Сначала создаем UI
createUI()

local function initModule(name)
    local module = _G.Nexus.Modules[name]
    if module and module.Init then
        return pcall(module.Init, _G.Nexus)
    end
    return false
end

-- Порядок инициализации (UI уже создан, остальные модули)
local initOrder = {"Survivor", "Killer", "Movement", "Fun", "Visual", "Binds"}

for _, name in ipairs(initOrder) do
    if _G.Nexus.Modules[name] then
        initModule(name)
    end
end

-- ========== НАСТРОЙКА СОХРАНЕНИЯ ==========

-- Настройка сохранения
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/violence-district")

-- Вкладка Settings
if _G.Nexus.Window then
    _G.Nexus.Tabs.Settings = _G.Nexus.Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    InterfaceManager:BuildInterfaceSection(_G.Nexus.Tabs.Settings)
    SaveManager:BuildConfigSection(_G.Nexus.Tabs.Settings)
    
    _G.Nexus.Window:SelectTab(1)
    SaveManager:LoadAutoloadConfig()
end

-- ========== ЗАВЕРШЕНИЕ ==========

-- Уведомление
local notificationContent = IS_MOBILE and "Nexus loaded (Mobile)" or "Nexus loaded"
Fluent:Notify({
    Title = "Nexus",
    Content = notificationContent,
    Duration = 3
})

-- Функция очистки
local function cleanup()
    for _, module in pairs(_G.Nexus.Modules) do
        if module and type(module.Cleanup) == "function" then
            pcall(module.Cleanup)
        end
    end
end

-- Очистка при выходе
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player then
        cleanup()
    end
end)

-- Для отладки можно добавить в глобальный объект
_G.Nexus.Cleanup = cleanup

return _G.Nexus
