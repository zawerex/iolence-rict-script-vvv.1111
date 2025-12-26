local Nexus = _G.Nexus

local Survivor = {
    Connections = {},
    States = {}
}

-- ========== CROSSHAIR SYSTEM ==========

local Crosshair = (function()
    local enabled = false
    local rainbowEnabled = false
    local currentType = "crosshair"
    local screenGui = nil
    local frame = nil
    local rainbowConnection = nil
    
    -- Настройки прицелов
    local crosshairTypes = {
        crosshair = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 20, 0, 20)
                container.Position = UDim2.new(0.5, -10, 0.5, -10)
                container.ZIndex = 999
                
                -- Вертикальная линия
                local line1 = Instance.new("Frame")
                line1.Name = "Line1"
                line1.BackgroundColor3 = Color3.new(1, 1, 1)
                line1.BorderSizePixel = 0
                line1.Size = UDim2.new(0, 2, 0, 12)
                line1.Position = UDim2.new(0.5, -1, 0.5, -6)
                line1.Parent = container
                
                -- Горизонтальная линия
                local line2 = Instance.new("Frame")
                line2.Name = "Line2"
                line2.BackgroundColor3 = Color3.new(1, 1, 1)
                line2.BorderSizePixel = 0
                line2.Size = UDim2.new(0, 12, 0, 2)
                line2.Position = UDim2.new(0.5, -6, 0.5, -1)
                line2.Parent = container
                
                return container
            end
        },
        
        dot = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 10, 0, 10)
                container.Position = UDim2.new(0.5, -5, 0.5, -5)
                container.ZIndex = 999
                
                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.BackgroundColor3 = Color3.new(1, 1, 1)
                dot.BorderSizePixel = 0
                dot.Size = UDim2.new(1, 0, 1, 0)
                dot.Position = UDim2.new(0, 0, 0, 0)
                dot.Parent = container
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = dot
                
                return container
            end
        },
        
        circle = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 16, 0, 16)
                container.Position = UDim2.new(0.5, -8, 0.5, -8)
                container.ZIndex = 999
                
                local outerCircle = Instance.new("Frame")
                outerCircle.Name = "OuterCircle"
                outerCircle.BackgroundColor3 = Color3.new(1, 1, 1)
                outerCircle.BackgroundTransparency = 0.5
                outerCircle.BorderSizePixel = 0
                outerCircle.Size = UDim2.new(1, 0, 1, 0)
                outerCircle.Position = UDim2.new(0, 0, 0, 0)
                outerCircle.Parent = container
                
                local outerCorner = Instance.new("UICorner")
                outerCorner.CornerRadius = UDim.new(1, 0)
                outerCorner.Parent = outerCircle
                
                local innerCircle = Instance.new("Frame")
                innerCircle.Name = "InnerCircle"
                innerCircle.BackgroundColor3 = Color3.new(0, 0, 0)
                innerCircle.BorderSizePixel = 0
                innerCircle.Size = UDim2.new(0, 6, 0, 6)
                innerCircle.Position = UDim2.new(0.5, -3, 0.5, -3)
                innerCircle.Parent = container
                
                local innerCorner = Instance.new("UICorner")
                innerCorner.CornerRadius = UDim.new(1, 0)
                innerCorner.Parent = innerCircle
                
                return container
            end
        }
    }
    
    local function destroyCrosshair()
        if frame then
            frame:Destroy()
            frame = nil
        end
        
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
    end
    
    local function createCrosshair()
        destroyCrosshair()
        
        if not enabled then return end
        
        -- Создаем ScreenGui если его нет
        if not screenGui or not screenGui.Parent then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "NexusCrosshair"
            screenGui.DisplayOrder = 999
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true
            screenGui.Parent = Nexus.Player:WaitForChild("PlayerGui")
        end
        
        -- Создаем выбранный тип прицела
        local crosshairConfig = crosshairTypes[currentType]
        if crosshairConfig then
            frame = crosshairConfig.create(screenGui)
            frame.Parent = screenGui
        end
    end
    
    local function updateRainbowEffect()
        if not rainbowEnabled or not frame then
            if rainbowConnection then
                rainbowConnection:Disconnect()
                rainbowConnection = nil
            end
            return
        end
        
        if rainbowConnection then
            rainbowConnection:Disconnect()
        end
        
        rainbowConnection = Nexus.Services.RunService.RenderStepped:Connect(function()
            if not frame or not rainbowEnabled then return end
            
            local time = tick()
            local hue = (time % 5) / 5  -- 5 секундный цикл
            local color = Color3.fromHSV(hue, 1, 1)
            
            -- Обновляем цвет в зависимости от типа прицела
            if currentType == "crosshair" then
                local line1 = frame:FindFirstChild("Line1")
                local line2 = frame:FindFirstChild("Line2")
                if line1 then line1.BackgroundColor3 = color end
                if line2 then line2.BackgroundColor3 = color end
            elseif currentType == "dot" then
                local dot = frame:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = color end
            elseif currentType == "circle" then
                local outerCircle = frame:FindFirstChild("OuterCircle")
                if outerCircle then outerCircle.BackgroundColor3 = color end
            end
        end)
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.CrosshairEnabled = true
        print("Crosshair: ON")
        
        createCrosshair()
        updateRainbowEffect()
    end
    
    local function Disable()
    if not enabled then return end
    enabled = false
    Nexus.States.CrosshairEnabled = false
    Nexus.States.RainbowCrosshairEnabled = false
    print("Crosshair: OFF")
    
    -- Останавливаем радужный эффект
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end
    
    -- Восстанавливаем белый цвет прицела
    if frame then
        if currentType == "crosshair" then
            local line1 = frame:FindFirstChild("Line1")
            local line2 = frame:FindFirstChild("Line2")
            if line1 then line1.BackgroundColor3 = Color3.new(1, 1, 1) end
            if line2 then line2.BackgroundColor3 = Color3.new(1, 1, 1) end
        elseif currentType == "dot" then
            local dot = frame:FindFirstChild("Dot")
            if dot then dot.BackgroundColor3 = Color3.new(1, 1, 1) end
        elseif currentType == "circle" then
            local outerCircle = frame:FindFirstChild("OuterCircle")
            if outerCircle then outerCircle.BackgroundColor3 = Color3.new(1, 1, 1) end
        end
    end
    
    destroyCrosshair()
    
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end
    
    local function setType(typeName)
        if not crosshairTypes[typeName] then
            typeName = "crosshair"
        end
        
        currentType = typeName
        print("Crosshair type set to: " .. typeName)
        
        if enabled then
            createCrosshair()
            updateRainbowEffect()
        end
    end
    
   local function toggleRainbow(value)
    rainbowEnabled = value
    Nexus.States.RainbowCrosshairEnabled = value
    print("Rainbow Crosshair: " .. (value and "ON" or "OFF"))
    
    if not value and frame then
        -- При выключении радуги восстанавливаем белый цвет
        if currentType == "crosshair" then
            local line1 = frame:FindFirstChild("Line1")
            local line2 = frame:FindFirstChild("Line2")
            if line1 then line1.BackgroundColor3 = Color3.new(1, 1, 1) end
            if line2 then line2.BackgroundColor3 = Color3.new(1, 1, 1) end
        elseif currentType == "dot" then
            local dot = frame:FindFirstChild("Dot")
            if dot then dot.BackgroundColor3 = Color3.new(1, 1, 1) end
        elseif currentType == "circle" then
            local outerCircle = frame:FindFirstChild("OuterCircle")
            if outerCircle then outerCircle.BackgroundColor3 = Color3.new(1, 1, 1) end
        end
    end
    
    updateRainbowEffect()
end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetType = setType,
        GetCurrentType = function() return currentType end,
        ToggleRainbow = toggleRainbow,
        IsRainbowEnabled = function() return rainbowEnabled end
    }
end)()

-- ========== AUTO VICTORY (SURVIVOR) ==========

local AutoVictory = (function()
    local enabled = false
    local lastFinishPos = nil
    local beatSurvivorDone = false
    local connection = nil
    
    local function findExitPosition()
        local map = Nexus.Services.Workspace:FindFirstChild("Map")
        if not map then return nil end
        
        local exitPos = nil
        
        -- Проверка стандартных карт
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            exitPos = Vector3.new(3098.16, 454.04, -4918.74)
            return exitPos
        end
        
        if map:FindFirstChild("HooksMeat") then
            exitPos = Vector3.new(1546.12, 152.21, -796.72)
            return exitPos
        end
        
        if map:FindFirstChild("churchbell") then
            exitPos = Vector3.new(760.98, -20.14, -78.48)
            return exitPos
        end
        
        -- Поиск по названию
        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            if finish:IsA("BasePart") then
                exitPos = finish.Position
            elseif finish:IsA("Model") then
                local part = finish:FindFirstChildWhichIsA("BasePart")
                if part then exitPos = part.Position end
            end
            return exitPos
        end
        
        -- Поиск по имени с "finish"
        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name:lower():find("finish") then
                if obj:IsA("BasePart") then
                    exitPos = obj.Position
                    break
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then 
                        exitPos = part.Position
                        break
                    end
                end
            end
        end
        
        -- Fallback позиции
        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Limestone then
                    exitPos = Vector3.new(-947.90, 152.12, -7579.52)
                    break
                end
            end
        end
        
        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Leather then
                    exitPos = Vector3.new(1546.12, 152.21, -796.72)
                    break
                end
            end
        end
        
        return exitPos
    end
    
    local function isSurvivor()
        -- Проверяем роль выжившего (нужно адаптировать под вашу игру)
        local character = Nexus.getCharacter()
        if not character then return false end
        
        -- Здесь должна быть логика определения роли
        -- Временно возвращаем true, предполагая что мы всегда выживший
        return true
    end
    
    local function teleportToExit()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Проверяем роль
        if not isSurvivor() then return end
        
        -- Поиск позиции выхода
        local exitPos = findExitPosition()
        if not exitPos then 
            print("Auto Victory: Exit not found")
            return 
        end
        
        -- Проверка изменения позиции финиша
        if lastFinishPos then
            local dist = (exitPos - lastFinishPos).Magnitude
            if dist > 50 then
                beatSurvivorDone = false
            end
        end
        
        -- Если уже телепортировались, не делать снова
        if beatSurvivorDone then return end
        
        -- Телепортация к финишу
        root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))
        
        -- Отметить выполнение
        beatSurvivorDone = true
        lastFinishPos = exitPos
        
        print("Auto Victory: Teleported to exit")
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.AutoVictoryEnabled = true
        print("Auto Victory: ON")
        
        -- Сбрасываем состояние при включении
        beatSurvivorDone = false
        lastFinishPos = nil
        
        -- Создаем соединение для периодической проверки
        if connection then
            connection:Disconnect()
        end
        
        connection = Nexus.Services.RunService.Heartbeat:Connect(function()
            if enabled then
                teleportToExit()
            end
        end)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.AutoVictoryEnabled = false
        print("Auto Victory: OFF")
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        beatSurvivorDone = false
        lastFinishPos = nil
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        ResetState = function()
            beatSurvivorDone = false
            lastFinishPos = nil
        end
    }
end)()

-- ========== NO SLOWDOWN ==========

local NoSlowdown = (function()
    local enabled = false
    local connection = nil

    local function IsCrawling(humanoid)
        if not humanoid then return false end
        
        -- Проверка состояния ползания
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.FallingDown or 
           state == Enum.HumanoidStateType.GettingUp or
           state == Enum.HumanoidStateType.Freefall then
            return true
        end
        
        -- Проверка по скорости
        if humanoid.WalkSpeed < 8 then
            return true
        end
        
        -- Проверка по анимациям
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track.Animation then
                local animName = track.Animation.AnimationId:lower()
                if animName:find("crawl") or animName:find("downed") or animName:find("injured") then
                    return true
                end
            end
        end
        
        -- Проверка по атрибутам
        local character = humanoid.Parent
        if character and (character:GetAttribute("Downed") or character:GetAttribute("Crawling")) then
            return true
        end
        
        return false
    end

    local function UpdateWalkSpeed()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        -- Проверяем, не лежит ли персонаж
        if IsCrawling(humanoid) then
            return -- Не работаем, если персонаж ползет
        end
        
        if humanoid.WalkSpeed ~= 16 then
            humanoid:SetAttribute("NoSlowdown", true)
            humanoid.WalkSpeed = 16
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoSlowdownEnabled = true
        print("No Slowdown: ON")
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Проверяем состояние перед установкой скорости
                if not IsCrawling(humanoid) then
                    humanoid:SetAttribute("NoSlowdown", true)
                    humanoid.WalkSpeed = 16
                end
                
                -- Отслеживаем изменения скорости и возвращаем к 16
                connection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    if enabled and humanoid then
                        UpdateWalkSpeed()
                    end
                end)
            end
        end
        
        -- Также отслеживаем появление нового персонажа
        local charAddedConn
        charAddedConn = Nexus.Player.CharacterAdded:Connect(function(char)
            task.wait(0.5) -- Даем время на инициализацию
            if enabled then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    -- Проверяем состояние перед установкой скорости
                    if not IsCrawling(hum) then
                        hum:SetAttribute("NoSlowdown", true)
                        hum.WalkSpeed = 16
                    end
                    
                    -- Обновляем соединение для нового персонажа
                    if connection then
                        connection:Disconnect()
                    end
                    
                    connection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                        if enabled and hum then
                            UpdateWalkSpeed()
                        end
                    end)
                end
            end
            charAddedConn:Disconnect()
        end)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoSlowdownEnabled = false
        print("No Slowdown: OFF")
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("NoSlowdown", nil)
                -- Не сбрасываем скорость, так как игра сама управляет этим
            end
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        IsCrawling = function()
            local character = Nexus.getCharacter()
            if not character then return false end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            return IsCrawling(humanoid)
        end
    }
end)()

-- ========== AUTO PARRY ==========

local AutoParry = (function()
    local spamActive = false
    local RANGE = 10
    local lastCheck = 0
    local CHECK_INTERVAL = 0.1

    local AttackAnimations = {
        "rbxassetid://110355011987939",
        "rbxassetid://139369275981139", 
        "rbxassetid://117042998468241",
        "rbxassetid://133963973694098",
        "rbxassetid://113255068724446",
        "rbxassetid://74968262036854",
        "rbxassetid://118907603246885",
        "rbxassetid://78432063483146",
        "rbxassetid://129784271201071",
        "rbxassetid://122812055447896",
        "rbxassetid://138720291317243",
        "rbxassetid://105834496520"
    }

    local AttackAnimationsLookup = {}
    for _, animId in ipairs(AttackAnimations) do
        AttackAnimationsLookup[animId] = true
    end

    local function isBlockingInRange()
        local currentTime = tick()
        if currentTime - lastCheck < CHECK_INTERVAL then return false end
        lastCheck = currentTime
        
        local myChar, myPos = Nexus.Player.Character, Nexus.Player.Character and Nexus.Player.Character.HumanoidRootPart and Nexus.Player.Character.HumanoidRootPart.Position
        if not myChar or not myPos then return false end

        for _, plr in ipairs(Nexus.Services.Players:GetPlayers()) do
            if plr == Nexus.Player then continue end
            local char, targetRoot = plr.Character, plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if not char or not targetRoot then continue end
            
            local targetPos = targetRoot.Position
            local distance = (myPos - targetPos).Magnitude
            
            if distance > RANGE then continue end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    if track.Animation and AttackAnimationsLookup[track.Animation.AnimationId] then 
                        return true 
                    end
                end
            end
        end
        return false
    end

    local function PerformParry()
        -- Используем стандартный метод через ЛКМ
        spamActive = true
        Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        task.spawn(function()
            task.wait(0.01)
            Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
            spamActive = false
        end)
    end

    local function Enable()
        if Nexus.States.AutoParryEnabled then return end
        Nexus.States.AutoParryEnabled = true
        print("AutoParry Enabled")
        
        Survivor.Connections.AutoParry = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not Nexus.States.AutoParryEnabled then
                if spamActive then 
                    spamActive = false; 
                    Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) 
                end
                return
            end

            if isBlockingInRange() then
                if not spamActive then
                    PerformParry()
                end
            elseif spamActive then
                spamActive = false
                Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
            end
        end)
    end

    local function Disable()
        Nexus.States.AutoParryEnabled = false
        if spamActive then 
            spamActive = false; 
            Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) 
        end 
        
        if Survivor.Connections.AutoParry then
            Survivor.Connections.AutoParry:Disconnect()
            Survivor.Connections.AutoParry = nil
        end
        print("AutoParry Disabled")
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return Nexus.States.AutoParryEnabled end,
        SetRange = function(value) 
            RANGE = tonumber(value) or 10
            print("AutoParry range set to: " .. RANGE)
        end,
        GetRange = function() return RANGE end
    }
end)()

-- ========== FAKE PARRY ==========

local FakeParry = (function()
    local enabled = false
    local animationId = "rbxassetid://127096285501517"
    local animationTrack = nil
    local characterConnection = nil
    
    local function stopAnimation()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
    end
    
    local function startAnimation()
        local character = Nexus.getCharacter()
        if not character then return false end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        
        -- Создаем анимацию
        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        
        -- Загружаем и воспроизводим анимацию один раз
        animationTrack = humanoid:LoadAnimation(animation)
        if animationTrack then
            animationTrack:Play()
            
            -- Останавливаем при завершении и очищаем
            animationTrack.Stopped:Connect(function()
                animationTrack = nil
            end)
            
            return true
        end
        
        return false
    end
    
    local function setupCharacterListeners()
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
        
        -- Останавливаем анимацию при смерти
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Connect(stopAnimation)
            end
        end
        
        -- Автоматически запускаем анимацию при появлении нового персонажа
        characterConnection = Nexus.Player.CharacterAdded:Connect(function(newCharacter)
            if enabled then
                task.wait(1) -- Ждем загрузки персонажа
                
                local humanoid = newCharacter:WaitForChild("Humanoid", 5)
                if humanoid then
                    -- Останавливаем при смерти
                    humanoid.Died:Connect(stopAnimation)
                    
                    -- Запускаем анимацию один раз
                    task.wait(0.5)
                    startAnimation()
                end
            end
        end)
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FakeParryEnabled = true
        print("Fake Parry: ON")
        
        -- Настраиваем слушатели для персонажа
        setupCharacterListeners()
        
        -- Запускаем анимацию один раз
        if not startAnimation() then
            print("Fake Parry: Waiting for character to start animation...")
        end
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FakeParryEnabled = false
        print("Fake Parry: OFF")
        
        -- Останавливаем анимацию
        stopAnimation()
        
        -- Отключаем слушатели
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        RestartAnimation = function()
            if enabled then
                stopAnimation()
                task.wait(0.1)
                startAnimation()
            end
        end
    }
end)()

local healingStates = {
    silentHealRunning = false,
    instantHealRunning = false,
    lastHealTime = 0,
    healCooldown = 0.2
}

local function StartInstantHeal()
    Nexus.States.InstantHealRunning = true
    healingStates.instantHealRunning = true
    
    Survivor.Connections.instantHeal = task.spawn(function()
        while healingStates.instantHealRunning do
            local char = Nexus.getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and myRoot then
                local myPosition = myRoot.Position
                
                for _, target in ipairs(Nexus.Services.Players:GetPlayers()) do
                    if target == Nexus.Player then continue end
                    
                    if target.Character then
                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local shouldHeal = true
                            
                            if not healingStates.silentHealRunning then
                                local distance = (myPosition - targetRoot.Position).Magnitude
                                shouldHeal = distance <= 15
                            end
                            
                            if shouldHeal then
                                local humanoid = target.Character:FindFirstChild("Humanoid")
                                if humanoid and humanoid.Health < humanoid.MaxHealth then
                                    pcall(function() 
                                        if Nexus.Services.ReplicatedStorage.Remotes and 
                                           Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                            Nexus.Services.ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer("success", 1, target.Character)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait() 
        end
    end)
end

local function StopInstantHeal()
    healingStates.instantHealRunning = false
    Nexus.States.InstantHealRunning = false
    Nexus.safeDisconnect(Survivor.Connections.instantHeal)
end

local function StartSilentHeal()
    if healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = true
    Nexus.States.SilentHealRunning = true
    local currentValue = true
    
    Survivor.Connections.silentHeal = task.spawn(function()
        while healingStates.silentHealRunning do
            local character = Nexus.getCharacter()
            if not character or not Nexus.getRootPart() then
                task.wait(0.4) -- Задержка при отсутствии персонажа, снижает нагрузку
                continue
            end
            
            local humanoid = Nexus.getHumanoid()
            if not humanoid or humanoid.Health <= 0 then
                task.wait(0.4) -- Задержка при смерти персонажа, снижает нагрузку
                continue
            end
            
            local currentTime = tick()
            if currentTime - healingStates.lastHealTime < healingStates.healCooldown then
                task.wait(healingStates.healCooldown) -- Кулдаун между лечениями (0.2 секунды)
                continue
            end
            
            local needsHealing = false
            local playersHealed = 0
            
            for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
                if targetPlayer == Nexus.Player then continue end
                
                if targetPlayer and targetPlayer.Character then
                    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetHumanoid and targetRoot and targetHumanoid.Health < targetHumanoid.MaxHealth then
                        needsHealing = true
                        playersHealed = playersHealed + 1
                        
                        if playersHealed <= 3 then
                            local args = {targetRoot, currentValue}
                            pcall(function() 
                                if Nexus.Services.ReplicatedStorage.Remotes and 
                                   Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                    Nexus.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                    healingStates.lastHealTime = tick()
                                    
                                    -- Вызываем HealAnim с аргументом false
                                    local healAnimRemote = Nexus.Services.ReplicatedStorage.Remotes.Healing:FindFirstChild("HealAnim")
                                    if healAnimRemote then
                                        healAnimRemote:FireServer(false)
                                    end
                                end
                            end)
                        end
                    else
                        local args = {targetRoot, false}
                        pcall(function() 
                            if Nexus.Services.ReplicatedStorage.Remotes and 
                               Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                Nexus.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                            end
                        end)
                    end
                end
            end
            
            if not needsHealing then 
                pcall(SendStopHealEvent)
            else 
                currentValue = not currentValue 
            end
            
            task.wait(0.1) -- Основная задержка цикла, предотвращает спам и снижает нагрузку
        end
        
        pcall(SendStopHealEvent)
    end)
end

local function StopSilentHeal()
    if not healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = false
    Nexus.States.SilentHealRunning = false
    
    task.wait(0.1) -- Задержка перед очисткой соединений
    
    if Survivor.Connections.silentHeal then
        Nexus.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
    end
    
    -- 2 раза вызываем HealAnim с аргументом false при выключении функции
    pcall(function()
        if Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Healing then
            local healAnimRemote = Nexus.Services.ReplicatedStorage.Remotes.Healing:FindFirstChild("HealAnim")
            if healAnimRemote then
                healAnimRemote:FireServer(false)
                healAnimRemote:FireServer(false)
            end
        end
    end)
    
    for i = 1, 2 do
        pcall(SendStopHealEvent)
        task.wait(0.05) -- Задержка между вызовами SendStopHealEvent
    end
    
    pcall(function()
        local character = Nexus.getCharacter()
        if character then
            local humanoid = Nexus.getHumanoid()
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            end
        end
    end)
end

local function ResetAllHealing()
    healingStates.silentHealRunning = false
    healingStates.instantHealRunning = false
    Nexus.States.SilentHealRunning = false
    Nexus.States.InstantHealRunning = false
    Nexus.States.autoHealEnabled = false
    
    if Survivor.Connections.silentHeal then
        Nexus.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
    end
    if Survivor.Connections.instantHeal then
        Nexus.safeDisconnect(Survivor.Connections.instantHeal)
        Survivor.Connections.instantHeal = nil
    end
    if Survivor.Connections.autoHeal then
        Nexus.safeDisconnect(Survivor.Connections.autoHeal)
        Survivor.Connections.autoHeal = nil
    end
end

-- ========== GATE TOOL ==========

local GateTool = (function()
    local toolInstance = nil
    local toolConnection = nil

    local function CreateTool()
        if not Nexus.Player:FindFirstChild("Backpack") then return nil end
        
        local existing = Nexus.Player.Backpack:FindFirstChild("Gate")
        if existing then 
            pcall(function() 
                if toolConnection then
                    toolConnection:Disconnect()
                    toolConnection = nil
                end
                existing:Destroy() 
            end) 
        end
        
        local tool = Instance.new("Tool")
        tool.Name = "Gate"
        tool.RequiresHandle = false
        tool.CanBeDropped = false
        tool.ToolTip = "Gate Tool - Use to interact with gates"
        tool.Parent = Nexus.Player.Backpack
        
        tool.ManualActivationOnly = true
        
        return tool
    end

    local function UseGate()
        -- Просто вызываем event "gate"
        local success = pcall(function()
            -- Пробуем найти и вызвать RemoteEvent "gate"
            local remotes = Nexus.Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local items = remotes:FindFirstChild("Items")
                if items then
                    local gate = items:FindFirstChild("Gate")
                    if gate then
                        local gateEvent = gate:FindFirstChild("gate")
                        if gateEvent and gateEvent:IsA("RemoteEvent") then
                            gateEvent:FireServer()
                            print("Gate event fired")
                            return true
                        end
                    end
                end
                
                -- Альтернативный путь поиска
                for _, remote in ipairs(remotes:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and (remote.Name:lower() == "gate" or remote.Name:find("gate")) then
                        remote:FireServer()
                        print("Gate event fired (alternative)")
                        return true
                    end
                end
            end
        end)
        
        if not success then
            print("Gate event not found or failed to fire")
        end
        
        return success
    end

    local function Enable()
        if Nexus.States.GateToolEnabled then return end
        Nexus.States.GateToolEnabled = true
        
        toolInstance = CreateTool()
        if toolInstance then 
            toolConnection = toolInstance.Activated:Connect(function()
                UseGate()
            end)
        end
    end

    local function Disable()
        Nexus.States.GateToolEnabled = false
        if toolConnection then
            Nexus.safeDisconnect(toolConnection)
            toolConnection = nil
        end
        if toolInstance then 
            pcall(function() 
                toolInstance:Destroy() 
            end) 
            toolInstance = nil
        end
        
        local backpack = Nexus.Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild("Gate")
            if tool then 
                pcall(function() tool:Destroy() end) 
            end
        end
    end

    Nexus.Player.CharacterAdded:Connect(function() 
        if Nexus.States.GateToolEnabled then 
            task.wait(2)
            Enable()
        end 
    end)

    return {Enable=Enable, Disable=Disable}
end)()

-- ========== AUTO SKILL CHECK ==========

local function FindSkillCheckGUI()
    local PlayerGui = Nexus.Player:WaitForChild("PlayerGui")
    local skillCheckGui = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if skillCheckGui then
        local checkPart = skillCheckGui:FindFirstChild("Check")
        if checkPart then
            local goalPart = checkPart:WaitForChild("Goal")
            local linePart = checkPart:WaitForChild("Line")
            return skillCheckGui, checkPart, goalPart, linePart
        end
    end
    return nil
end

local function DisableGeneratorFail()
    local char = Nexus.getCharacter()
    if char then
        local skillCheckGen = char:FindFirstChild("Skillcheck-gen")
        if skillCheckGen then skillCheckGen.Enabled = false end
    end
end

local function PerformPerfectSkillCheck()
    if not Nexus.States.autoSkillEnabled then return end
    local skillCheckGui, checkPart, goalPart, linePart = FindSkillCheckGUI()
    if not skillCheckGui or not checkPart or not checkPart.Visible then return end
    
    local lineRot, goalRot = linePart.Rotation, goalPart.Rotation
    local minRot, maxRot = (104 + goalRot) % 360, (114 + goalRot) % 360
    if (minRot > maxRot and (lineRot >= minRot or lineRot <= maxRot)) or (lineRot >= minRot and lineRot <= maxRot) then
        Nexus.Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        Nexus.Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        return true
    end
    return false
end

-- ========== MODULE INITIALIZATION ==========

function Survivor.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    Tabs.Main:AddParagraph({
        Title = "Hello, " .. Nexus.Player.Name .. "!",
        Content = "Have a great game — and a Happy New Year! ☃"
    })

    -- ========== CROSSHAIR ==========
    local CrosshairToggle = Tabs.Main:AddToggle("Crosshair", {
        Title = "Crosshair", 
        Description = "Display crosshair in the center of screen", 
        Default = false
    })

    CrosshairToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                Crosshair.Enable() 
            else 
                Crosshair.Disable() 
            end 
        end)
    end)

    local CrosshairTypeDropdown = Tabs.Main:AddDropdown("CrosshairType", {
        Title = "Crosshair Type",
        Description = "Select crosshair type",
        Values = {"crosshair", "dot", "circle"},
        Default = "crosshair",
        Callback = function(value)
            Nexus.SafeCallback(function()
                Crosshair.SetType(value)
            end)
        end
    })

    local RainbowCrosshairToggle = Tabs.Main:AddToggle("RainbowCrosshair", {
        Title = "Rainbow Crosshair", 
        Description = "Enable rainbow color effect on crosshair", 
        Default = false
    })

    RainbowCrosshairToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            Crosshair.ToggleRainbow(v)
        end)
    end)

    -- ========== AUTO VICTORY ==========
    local AutoVictoryToggle = Tabs.Main:AddToggle("AutoVictory", {
        Title = "Auto Victory (Survivor)", 
        Description = "Automatically teleports to exit for victory", 
        Default = false
    })

    AutoVictoryToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                AutoVictory.Enable() 
            else 
                AutoVictory.Disable() 
            end 
        end)
    end)

    -- ========== NO SLOWDOWN ==========
    local NoSlowdownToggle = Tabs.Main:AddToggle("NoSlowdown", {
        Title = "No Slowdown + Fast DropPallet", 
        Description = "Prevents all slowdown effects", 
        Default = false
    })

    NoSlowdownToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                NoSlowdown.Enable() 
            else 
                NoSlowdown.Disable() 
            end 
        end)
    end)

    -- ========== AUTO PARRY ==========
    local AutoParryToggle = Tabs.Main:AddToggle("AutoParry", {
        Title = "AutoParry", 
        Description = "automatic parry of attacks", 
        Default = false
    })

    AutoParryToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                AutoParry.Enable() 
            else 
                AutoParry.Disable() 
            end 
        end)
    end)

    local AutoParryRangeSlider = Tabs.Main:AddSlider("AutoParryRange", {
        Title = "ping compensation",
        Description = "",
        Default = 10,
        Min = 0,
        Max = 20,
        Rounding = 2,
        Callback = function(value)
            Nexus.SafeCallback(function()
                AutoParry.SetRange(value)
            end)
        end
    })

    -- ========== FAKE PARRY ==========
    local FakeParryToggle = Tabs.Main:AddToggle("FakeParry", {
        Title = "Fake Parry", 
        Description = "Plays parry animation continuously", 
        Default = false
    })

    FakeParryToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                FakeParry.Enable() 
            else 
                FakeParry.Disable() 
            end 
        end)
    end)

    -- ========== gamemode ==========
    local HealToggle = Tabs.Main:AddToggle("Heal", {
        Title = "Gamemode", 
        Description = "", 
        Default = false
    })

    HealToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Nexus.States.autoHealEnabled = v
            Nexus.safeDisconnect(Survivor.Connections.autoHeal)
            if v then
                Survivor.Connections.autoHeal = Nexus.Services.RunService.Heartbeat:Connect(function()
                    if not Nexus.States.autoHealEnabled or not Nexus.Player.Character then 
                        Nexus.safeDisconnect(Survivor.Connections.autoHeal)
                        return 
                    end
                    local hum = Nexus.Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                end)
            end
        end)
    end)

    -- ========== INSTANT HEAL ==========
    local InstantHealToggle = Tabs.Main:AddToggle("InstantHeal", {
        Title = "Instant Heal", 
        Description = "instant treatment", 
        Default = false
    })

    InstantHealToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                StartInstantHeal() 
            else 
                StopInstantHeal() 
            end 
        end)
    end)

    -- ========== SILENT HEAL ==========
    local SilentHealToggle = Tabs.Main:AddToggle("SilentHeal", {
        Title = "Silent Heal", 
        Description = "Heals all players anywhere on the map", 
        Default = false
    })

    SilentHealToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                StartSilentHeal() 
            else 
                StopSilentHeal() 
            end 
        end)
    end)

    -- ========== GATE TOOL ==========
    local GateToolToggle = Tabs.Main:AddToggle("GateTool", {
        Title = "Fast use [Gate Tool]", 
        Description = "Quick usage of the Gate Tool", 
        Default = false
    })

    GateToolToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                GateTool.Enable() 
            else 
                GateTool.Disable() 
            end 
        end)
    end)

    -- ========== NO HITBOX ==========
    local NoHitboxToggle = Tabs.Main:AddToggle("NoHitbox", {
        Title = "No Hitbox", 
        Description = "", 
        Default = false
    })

    NoHitboxToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            local char = Nexus.getCharacter()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do 
                if part:IsA("BasePart") then 
                    part.CanTouch = not v 
                end 
            end
            if v then
                Nexus.Player.CharacterAdded:Connect(function(char)
                    task.wait(1)
                    for _, part in ipairs(char:GetDescendants()) do 
                        if part:IsA("BasePart") then 
                            part.CanTouch = false 
                        end 
                    end
                end)
            end
        end)
    end)

    -- ========== AUTO PERFECT SKILL ==========
    local AutoSkillToggle = Tabs.Main:AddToggle("AutoPerfectSkill", {
        Title = "Auto Perfect Skill Check", 
        Description = "automatically clicks in the perfect location", 
        Default = false
    })

    AutoSkillToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Nexus.States.autoSkillEnabled = v
            Nexus.safeDisconnect(Survivor.Connections.skillCheck)
            if v then 
                Survivor.Connections.skillCheck = Nexus.Services.RunService.Heartbeat:Connect(PerformPerfectSkillCheck) 
            end
        end)
    end)
    
end

function Survivor.Cleanup()
    -- Отключаем все функции
    Crosshair.Disable()
    AutoVictory.Disable()
    NoSlowdown.Disable()
    AutoParry.Disable()
    FakeParry.Disable()
    ResetAllHealing()
    GateTool.Disable()
    
    for key, connection in pairs(Survivor.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Survivor.Connections = {}
end

return Survivor
