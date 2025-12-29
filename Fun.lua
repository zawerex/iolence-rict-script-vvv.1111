-- Fun Module - Emotes, custom cursor and other fun functions for Violence District
local Nexus = _G.Nexus

local Fun = {
    CurrentEmoteTrack = nil,
    CurrentSound = nil,
    CurrentAnimation = nil,
    AvailableEmotes = {},
    EmotesFolder = nil,
    JerkTool = {
        active = false,
        tool = nil,
        track = nil
    },
    CustomCursor = {
        enabled = false,
        screenGui = nil,
        cursorFrame = nil,
        pulseTween = nil,
        mouseLocked = false,
        cameraRotation = Vector2.new(0, 0),
        connection = nil
    },
    SpinConnection = nil
}

-- ========== CUSTOM CURSOR SYSTEM ==========

local CustomCursor = (function()
    local function createCursorGUI()
        if Fun.CustomCursor.screenGui then
            Fun.CustomCursor.screenGui:Destroy()
            Fun.CustomCursor.screenGui = nil
        end
        
        local playerGui = Nexus.Player:WaitForChild("PlayerGui")
        
        Fun.CustomCursor.screenGui = Instance.new("ScreenGui")
        Fun.CustomCursor.screenGui.Name = "NexusCustomCursor"
        Fun.CustomCursor.screenGui.DisplayOrder = 9999
        Fun.CustomCursor.screenGui.ResetOnSpawn = false
        Fun.CustomCursor.screenGui.IgnoreGuiInset = true
        Fun.CustomCursor.screenGui.Parent = playerGui
        
        -- Создаем кастомный курсор в виде крестика
        Fun.CustomCursor.cursorFrame = Instance.new("Frame")
        Fun.CustomCursor.cursorFrame.Name = "Cursor"
        Fun.CustomCursor.cursorFrame.BackgroundTransparency = 1
        Fun.CustomCursor.cursorFrame.Size = UDim2.new(0, 40, 0, 40)
        Fun.CustomCursor.cursorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        Fun.CustomCursor.cursorFrame.ZIndex = 9999
        Fun.CustomCursor.cursorFrame.Parent = Fun.CustomCursor.screenGui
        
        -- Вертикальная линия крестика
        local verticalLine = Instance.new("Frame")
        verticalLine.Name = "VerticalLine"
        verticalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        verticalLine.BorderSizePixel = 0
        verticalLine.Size = UDim2.new(0, 2, 0, 20)
        verticalLine.Position = UDim2.new(0.5, -1, 0.5, -10)
        verticalLine.ZIndex = 9999
        verticalLine.Parent = Fun.CustomCursor.cursorFrame
        
        -- Горизонтальная линия крестика
        local horizontalLine = Instance.new("Frame")
        horizontalLine.Name = "HorizontalLine"
        horizontalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        horizontalLine.BorderSizePixel = 0
        horizontalLine.Size = UDim2.new(0, 20, 0, 2)
        horizontalLine.Position = UDim2.new(0.5, -10, 0.5, -1)
        horizontalLine.ZIndex = 9999
        horizontalLine.Parent = Fun.CustomCursor.cursorFrame
        
        -- Создаем эффект пульсации (кольцо)
        local pulseRing = Instance.new("Frame")
        pulseRing.Name = "PulseRing"
        pulseRing.BackgroundTransparency = 1
        pulseRing.Size = UDim2.new(0, 30, 0, 30)
        pulseRing.AnchorPoint = Vector2.new(0.5, 0.5)
        pulseRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        pulseRing.ZIndex = 9998
        pulseRing.Parent = Fun.CustomCursor.cursorFrame
        
        local ringCorner = Instance.new("UICorner")
        ringCorner.CornerRadius = UDim.new(1, 0)
        ringCorner.Parent = pulseRing
        
        local ringStroke = Instance.new("UIStroke")
        ringStroke.Color = Color3.fromRGB(255, 255, 255)
        ringStroke.Thickness = 2
        ringStroke.Transparency = 1
        ringStroke.Parent = pulseRing
        
        Fun.CustomCursor.pulseRing = pulseRing
        Fun.CustomCursor.ringStroke = ringStroke
        
        -- Скрываем оригинальный курсор
        Nexus.Services.UserInputService.MouseIconEnabled = false
    end
    
    local function destroyCursorGUI()
        if Fun.CustomCursor.screenGui then
            Fun.CustomCursor.screenGui:Destroy()
            Fun.CustomCursor.screenGui = nil
        end
        Fun.CustomCursor.cursorFrame = nil
        
        -- Восстанавливаем оригинальный курсор
        Nexus.Services.UserInputService.MouseIconEnabled = true
    end
    
    local function updateCursorPosition()
        if not Fun.CustomCursor.enabled or not Fun.CustomCursor.cursorFrame then return end
        
        local mouseLocation = Nexus.Services.UserInputService:GetMouseLocation()
        Fun.CustomCursor.cursorFrame.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
    end
    
    local function createPulseEffect()
        if not Fun.CustomCursor.pulseRing or not Fun.CustomCursor.ringStroke then return end
        
        -- Анимируем кольцо пульсации
        Fun.CustomCursor.ringStroke.Transparency = 0
        
        -- Увеличиваем и делаем прозрачным
        local tweenInfo = TweenInfo.new(
            0.3, -- Длительность
            Enum.EasingStyle.Quad, -- Стиль
            Enum.EasingDirection.Out, -- Направление
            0, -- Повторы
            false, -- Обратно
            0 -- Задержка
        )
        
        -- Создаем твины для увеличения и прозрачности
        local sizeTween = Nexus.Services.TweenService:Create(
            Fun.CustomCursor.pulseRing,
            tweenInfo,
            {Size = UDim2.new(0, 50, 0, 50)}
        )
        
        local transparencyTween = Nexus.Services.TweenService:Create(
            Fun.CustomCursor.ringStroke,
            tweenInfo,
            {Transparency = 1}
        )
        
        -- Запускаем твины
        sizeTween:Play()
        transparencyTween:Play()
        
        -- После завершения анимации возвращаем в исходное состояние
        transparencyTween.Completed:Connect(function()
            Fun.CustomCursor.pulseRing.Size = UDim2.new(0, 30, 0, 30)
        end)
    end
    
    local function lockMouse()
        if not Fun.CustomCursor.enabled then return end
        
        Fun.CustomCursor.mouseLocked = true
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        
        -- Запоминаем позицию курсора для корректировки
        local mouseLocation = Nexus.Services.UserInputService:GetMouseLocation()
        Fun.CustomCursor.lastMousePos = mouseLocation
    end
    
    local function unlockMouse()
        Fun.CustomCursor.mouseLocked = false
        Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        -- Восстанавливаем позицию курсора
        if Fun.CustomCursor.lastMousePos then
            local mouse = Nexus.Services.PlayerGui:GetMouse()
            mouse.X = Fun.CustomCursor.lastMousePos.X
            mouse.Y = Fun.CustomCursor.lastMousePos.Y
        end
    end
    
    local function handleCameraControl()
        if not Fun.CustomCursor.enabled then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        local originalCameraType = camera.CameraType
        
        -- Устанавливаем камеру в режим скрипта для полного контроля
        camera.CameraType = Enum.CameraType.Scriptable
        
        -- Переменные для управления камерой
        Fun.CustomCursor.cameraRotation = Vector2.new(0, 0)
        
        -- Основной цикл управления камерой
        Fun.CustomCursor.connection = Nexus.Services.RunService.RenderStepped:Connect(function(delta)
            if not Fun.CustomCursor.enabled then
                if Fun.CustomCursor.connection then
                    Fun.CustomCursor.connection:Disconnect()
                    Fun.CustomCursor.connection = nil
                end
                return
            end
            
            -- Обновляем позицию кастомного курсора
            updateCursorPosition()
            
            -- Управление камерой при заблокированной мыши
            if Fun.CustomCursor.mouseLocked then
                local mouseDelta = Nexus.Services.UserInputService:GetMouseDelta()
                Fun.CustomCursor.cameraRotation = Fun.CustomCursor.cameraRotation + Vector2.new(-mouseDelta.X * 0.003, -mouseDelta.Y * 0.003)
                Fun.CustomCursor.cameraRotation = Vector2.new(
                    Fun.CustomCursor.cameraRotation.X,
                    math.clamp(Fun.CustomCursor.cameraRotation.Y, -math.pi/2 + 0.1, math.pi/2 - 0.1)
                )
                
                local rotationCFrame = CFrame.Angles(0, Fun.CustomCursor.cameraRotation.X, 0) * 
                                      CFrame.Angles(Fun.CustomCursor.cameraRotation.Y, 0, 0)
                camera.CFrame = CFrame.new(camera.CFrame.Position) * rotationCFrame
            end
        end)
        
        -- Обработчик нажатий мыши
        local mouseButton1Connection
        mouseButton1Connection = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not Fun.CustomCursor.enabled then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- Создаем эффект пульсации при клике
                createPulseEffect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                -- Правая кнопка мыши блокирует/разблокирует камеру
                if Fun.CustomCursor.mouseLocked then
                    unlockMouse()
                else
                    lockMouse()
                end
            end
        end)
        
        -- Обработчик изменения камеры
        local cameraChangedConnection
        cameraChangedConnection = Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if Fun.CustomCursor.enabled then
                camera = Nexus.Services.Workspace.CurrentCamera
                camera.CameraType = Enum.CameraType.Scriptable
            end
        end)
        
        -- Сохраняем соединения для очистки
        Fun.CustomCursor.mouseButton1Connection = mouseButton1Connection
        Fun.CustomCursor.cameraChangedConnection = cameraChangedConnection
    end
    
    local function Enable()
        if Fun.CustomCursor.enabled then return end
        Fun.CustomCursor.enabled = true
        
        -- Создаем GUI для курсора
        createCursorGUI()
        
        -- Настраиваем управление камерой
        handleCameraControl()
        
        print("Custom Cursor: ON")
    end
    
    local function Disable()
        if not Fun.CustomCursor.enabled then return end
        Fun.CustomCursor.enabled = false
        
        -- Отключаем управление камерой
        if Fun.CustomCursor.connection then
            Fun.CustomCursor.connection:Disconnect()
            Fun.CustomCursor.connection = nil
        end
        
        if Fun.CustomCursor.mouseButton1Connection then
            Fun.CustomCursor.mouseButton1Connection:Disconnect()
            Fun.CustomCursor.mouseButton1Connection = nil
        end
        
        if Fun.CustomCursor.cameraChangedConnection then
            Fun.CustomCursor.cameraChangedConnection:Disconnect()
            Fun.CustomCursor.cameraChangedConnection = nil
        end
        
        -- Восстанавливаем оригинальную камеру
        local camera = Nexus.Services.Workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
        
        -- Разблокируем мышь
        unlockMouse()
        
        -- Удаляем GUI курсора
        destroyCursorGUI()
        
        print("Custom Cursor: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return Fun.CustomCursor.enabled end,
        CreatePulse = createPulseEffect
    }
end)()

-- ========== EMOTES FUNCTIONS ==========

function Fun.InitializeEmotesSystem()
    if not Nexus.Services.ReplicatedStorage:FindFirstChild("Emotes") then 
        return false 
    end
    
    Fun.EmotesFolder = Nexus.Services.ReplicatedStorage:WaitForChild("Emotes")
    Fun.AvailableEmotes = {}
    
    for _, folder in pairs(Fun.EmotesFolder:GetChildren()) do
        if folder:IsA("Folder") then 
            table.insert(Fun.AvailableEmotes, folder.Name) 
        end
    end
    
    if #Fun.AvailableEmotes == 0 then
        return false
    end
    
    table.sort(Fun.AvailableEmotes)
    return true
end

function Fun.PlayEmote(emoteName)
    Fun.StopEmote()
    
    local emoteFolder = Fun.EmotesFolder:FindFirstChild(emoteName)
    if not emoteFolder then 
        return false 
    end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    
    if not animationId then 
        return false 
    end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if not character or not humanoid then 
        return false 
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    Fun.CurrentAnimation = animation
    
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play(0.1, 1, 1)
    Fun.CurrentEmoteTrack = animationTrack
    
    if soundId and soundId ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Parent = head
            sound:Play()
            Fun.CurrentSound = sound
            
            sound.Ended:Connect(function()
                if sound == Fun.CurrentSound then 
                    sound:Destroy()
                    Fun.CurrentSound = nil 
                end
            end)
        end
    end
    
    humanoid.Died:Connect(function()
        Fun.StopEmote()
    end)
    
    return true
end

function Fun.StopEmote()
    if Fun.CurrentEmoteTrack then 
        Fun.CurrentEmoteTrack:Stop()
        Fun.CurrentEmoteTrack = nil 
    end
    
    if Fun.CurrentSound then 
        Fun.CurrentSound:Stop()
        Fun.CurrentSound:Destroy()
        Fun.CurrentSound = nil 
    end
    
    Fun.CurrentAnimation = nil
end

-- ========== JERK FUNCTION ==========

function Fun.StartJerk()
    Nexus.SafeCallback(function()
        local humanoid = Nexus.getHumanoid()
        local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        if not humanoid or not backpack then 
            return 
        end

        if Fun.JerkTool.tool then
            Fun.StopJerk()
        end

        local tool = Instance.new("Tool")
        tool.Name = "Jerk Off"
        tool.ToolTip = "Use tool to jerk off"
        tool.RequiresHandle = false
        tool.Parent = backpack

        Fun.JerkTool.tool = tool
        Fun.JerkTool.active = true

        local function stopTomfoolery()
            Fun.JerkTool.active = false
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
                Fun.JerkTool.track = nil
            end
        end

        tool.Equipped:Connect(function() 
            Fun.JerkTool.active = true 
        end)
        
        tool.Unequipped:Connect(stopTomfoolery)
        
        humanoid.Died:Connect(stopTomfoolery)

        local function isR15()
            local character = Nexus.getCharacter()
            if not character then return false end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum then return false end
            return hum.RigType == Enum.HumanoidRigType.R15
        end
        
        task.spawn(function()
            while task.wait() do
                if not Fun.JerkTool.active then continue end
                
                local r15 = isR15()
                
                if not Fun.JerkTool.track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = not r15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                    Fun.JerkTool.track = humanoid:LoadAnimation(anim)
                end

                Fun.JerkTool.track:Play()
                Fun.JerkTool.track:AdjustSpeed(r15 and 0.7 or 0.65)
                Fun.JerkTool.track.TimePosition = 0.6
                
                task.wait(0.1)
                
                while Fun.JerkTool.track and Fun.JerkTool.track.TimePosition < (not r15 and 0.65 or 0.7) do 
                    task.wait(0.1) 
                end
                
                if Fun.JerkTool.track then
                    Fun.JerkTool.track:Stop()
                    Fun.JerkTool.track = nil
                end
            end
        end)
    end)
end

function Fun.StopJerk()
    if Fun.JerkTool.track then
        Fun.JerkTool.track:Stop()
        Fun.JerkTool.track = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.JerkTool.tool:Destroy()
        Fun.JerkTool.tool = nil
    end
    
    Fun.JerkTool.active = false
end

-- ========== GAME UTILITY FUNCTIONS ==========

function Fun.ResetCharacter()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if placeId and jobId then
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Nexus.Player)
    end
end

function Fun.ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    
    pcall(function()
        TeleportService:Teleport(placeId, Nexus.Player)
    end)
end

function Fun.Suicide()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
end

-- ========== SPIN FUNCTION ==========

function Fun.ToggleSpin(enabled)
    if enabled then
        Fun.StartSpin()
    else
        Fun.StopSpin()
    end
end

function Fun.StartSpin()
    local character = Nexus.getCharacter()
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
    end
    
    Fun.SpinConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
        else
            Fun.StopSpin()
        end
    end)
end

function Fun.StopSpin()
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
end

-- ========== MODULE INITIALIZATION ==========

function Fun.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    
    -- ========== CUSTOM CURSOR ==========
    Tabs.Fun:AddSection("Custom Cursor")
    
    local CustomCursorToggle = Tabs.Fun:AddToggle("CustomCursor", {
        Title = "Custom Cursor", 
        Description = "Replaces mouse cursor with custom crosshair and gives camera control", 
        Default = false
    })
    
    CustomCursorToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                CustomCursor.Enable() 
            else 
                CustomCursor.Disable() 
            end 
        end)
    end)
    
    Tabs.Fun:AddParagraph({
        Title = "Custom Cursor Controls",
        Content = "Right Click: Lock/Unlock camera\nLeft Click: Pulse effect"
    })
    
    -- ========== EMOTES SYSTEM ==========
    local emotesInitialized = Fun.InitializeEmotesSystem()
    
    if emotesInitialized then
        Tabs.Fun:AddSection("Emotes System")
        
        Tabs.Fun:AddParagraph({
            Title = "Emotes System",
            Content = "Select an emote to play"
        })
        
        local emotesList = {}
        for _, emote in ipairs(Fun.AvailableEmotes) do
            table.insert(emotesList, emote)
        end
        table.insert(emotesList, "Jerk")
        
        local SelectedEmote = Tabs.Fun:AddDropdown("SelectedEmote", {
            Title = "Select Emote", 
            Description = "Choose an emote to play", 
            Values = emotesList, 
            Multi = false, 
            Default = ""
        })
        
        SelectedEmote:OnChanged(function(value) 
            Nexus.SafeCallback(function()
                if value and value ~= "" then 
                    if value == "Jerk" then
                        Fun.StartJerk()
                    else
                        Fun.PlayEmote(value) 
                    end
                end 
            end)
        end)

        Tabs.Fun:AddButton({
            Title = "Stop Current Emote", 
            Description = "Stops the currently playing emote", 
            Callback = function()
                Nexus.SafeCallback(Fun.StopEmote)
            end
        })
    else
        Tabs.Fun:AddSection("Fun Tools")
        
        Tabs.Fun:AddParagraph({
            Title = "Fun Tools",
            Content = "Additional fun tools for the game"
        })
        
        Tabs.Fun:AddButton({
            Title = "Jerk Tool", 
            Description = "Adds Jerk Off tool to your backpack", 
            Callback = function()
                Nexus.SafeCallback(Fun.StartJerk)
            end
        })
    end
    
    -- ========== GAME UTILITIES ==========
    Tabs.Fun:AddSection("Game Utilities")
    
    Tabs.Fun:AddButton({
        Title = "Reset Character", 
        Description = "Kills your character to respawn", 
        Callback = function()
            Nexus.SafeCallback(Fun.ResetCharacter)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Rejoin Game", 
        Description = "Rejoins the current game server", 
        Callback = function()
            Nexus.SafeCallback(Fun.RejoinGame)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Server Hop", 
        Description = "Joins a new random server", 
        Callback = function()
            Nexus.SafeCallback(Fun.ServerHop)
        end
    })
    
    -- ========== QUICK ACTIONS ==========
    Tabs.Fun:AddSection("Quick Actions")
    
    Tabs.Fun:AddButton({
        Title = "Suicide", 
        Description = "Instantly kills your character", 
        Callback = function()
            Nexus.SafeCallback(Fun.Suicide)
        end
    })
    
    -- ========== MISC FUNCTIONS ==========
    Tabs.Fun:AddSection("Miscellaneous")
    
    local SpinToggle = Tabs.Fun:AddToggle("SpinCharacter", {
        Title = "Spin Character", 
        Description = "Makes your character spin continuously", 
        Default = false
    })
    
    SpinToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleSpin(v)
        end)
    end)
end

-- ========== CLEANUP ==========

function Fun.Cleanup()
    -- Отключаем кастомный курсор
    CustomCursor.Disable()
    
    -- Отключаем все остальные функции
    Fun.StopEmote()
    Fun.StopJerk()
    Fun.StopSpin()
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
end

return Fun
