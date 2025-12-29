local Nexus = _G.Nexus

local Killer = {
    Connections = {},
    States = {},
    Objects = {},
    HitboxCache = {}
}

-- ========== SPEAR CROSSHAIR ==========

local SpearCrosshair = (function()
    local enabled = false
    local crosshairX, crosshairY
    
    -- Создание прицела
    local function createCrosshair()
        crosshairX = Drawing.new("Line")
        crosshairY = Drawing.new("Line")
        
        crosshairX.Thickness = 2
        crosshairX.Transparency = 1
        crosshairX.Color = Color3.fromRGB(255, 0, 0)
        crosshairX.Visible = false
        
        crosshairY.Thickness = 2
        crosshairY.Transparency = 1
        crosshairY.Color = Color3.fromRGB(255, 0, 0)
        crosshairY.Visible = false
        
        -- Обновление позиции прицела
        local function updatePosition()
            local viewport = Nexus.Services.Workspace.CurrentCamera.ViewportSize
            local centerX = viewport.X / 2
            local centerY = viewport.Y / 2
            
            crosshairX.From = Vector2.new(centerX - 10, centerY)
            crosshairX.To = Vector2.new(centerX + 10, centerY)
            
            crosshairY.From = Vector2.new(centerX, centerY - 10)
            crosshairY.To = Vector2.new(centerX, centerY + 10)
        end
        
        Nexus.Services.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePosition)
        updatePosition()
    end
    
    -- Удаление прицела
    local function destroyCrosshair()
        if crosshairX then 
            pcall(function() 
                crosshairX:Remove() 
                crosshairX = nil 
            end) 
        end
        if crosshairY then 
            pcall(function() 
                crosshairY:Remove() 
                crosshairY = nil 
            end) 
        end
    end
    
    -- Обновление видимости прицела
    local function updateCrosshair()
        if not crosshairX or not crosshairY then
            createCrosshair()
        end
        
        local character = Nexus.Player.Character
        local shouldShow = enabled and character and character:GetAttribute("spearmode") == "spearing"
        
        crosshairX.Visible = shouldShow
        crosshairY.Visible = shouldShow
        
        if shouldShow then
            crosshairX.Color = Color3.fromRGB(255, 0, 0) -- Красный цвет
            crosshairY.Color = Color3.fromRGB(255, 0, 0)
        end
    end
    
    -- Основная функция
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.SpearCrosshairEnabled = true
        
        -- Создаем прицел
        createCrosshair()
        
        -- Запускаем обновление прицела
        Killer.Connections.SpearCrosshair = Nexus.Services.RunService.RenderStepped:Connect(updateCrosshair)
        
        print("Spear Crosshair: ON")
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.SpearCrosshairEnabled = false
        
        -- Удаляем прицел
        destroyCrosshair()
        
        -- Отключаем соединения
        if Killer.Connections.SpearCrosshair then
            Killer.Connections.SpearCrosshair:Disconnect()
            Killer.Connections.SpearCrosshair = nil
        end
        
        print("Spear Crosshair: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== DOUBLE TAP ==========

local DoubleTap = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    
    local function GetBasicAttackRemote()
        local success, result = pcall(function()
            return Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
        end)
        return success and result or nil
    end
    
    local function setupHook()
        if hooked then return end
        
        local basicAttack = GetBasicAttackRemote()
        if not basicAttack then
            print("DoubleTap: BasicAttack remote not found")
            return false
        end
        
        -- Получаем метатаблицу
        mt = getrawmetatable(basicAttack)
        if not mt then
            print("DoubleTap: Could not get metatable")
            return false
        end
        
        originalNamecall = mt.__namecall
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == basicAttack and method == "FireServer" and enabled then
                local args = {...}
                
                -- Первый оригинальный вызов
                originalNamecall(self, unpack(args))
                
                -- Второй вызов для дауна
                task.wait(0.03) -- Минимальная задержка
                originalNamecall(self, unpack(args))
                
                return
            end
            
            return originalNamecall(self, ...)
        end)
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = true
        print("DoubleTap: Hook установлен")
        return true
    end
    
    local function removeHook()
        if not hooked or not mt or not originalNamecall then return end
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = originalNamecall
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = false
        originalNamecall = nil
        mt = nil
        print("DoubleTap: Hook удален")
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.DoubleTapEnabled = true
        
        if not setupHook() then
            -- Пробуем найти Remote позже
            task.spawn(function()
                task.wait(2)
                if enabled then
                    setupHook()
                end
            end)
        end
        
        print("DoubleTap: ON")
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.DoubleTapEnabled = false
        
        removeHook()
        print("DoubleTap: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== SPAM HOOK ==========

local SpamHook = (function()
    local enabled = false
    local spamCount = 0
    local maxSpam = 50
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    
    local function GetHookEventRemote()
        local success, result = pcall(function()
            return Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Carry"):WaitForChild("HookEvent")
        end)
        return success and result or nil
    end
    
    -- Найти ближайшего выжившего
    local function findNearestSurvivor()
        local character = Nexus.getCharacter()
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return nil
        end
        
        local myPosition = character.HumanoidRootPart.Position
        local nearestPlayer = nil
        local nearestDistance = math.huge
        
        for _, player in pairs(Nexus.Services.Players:GetPlayers()) do
            if player ~= Nexus.Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local team = player.Team
                if team and team.Name == "Survivor" then
                    local distance = (player.Character.HumanoidRootPart.Position - myPosition).Magnitude
                    if distance < nearestDistance and distance < 50 then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
        
        return nearestPlayer
    end
    
    local function executeHookSpam()
        if not enabled then return end
        
        spamCount = 0
        
        for i = 1, maxSpam do
            if not enabled then break end
            
            local target = findNearestSurvivor()
            if target and target.Character then
                -- Вызываем HookEvent через pcall для безопасности
                local success = pcall(function()
                    -- Получаем remote здесь, так как он может быть nil при первом вызове
                    local hookEvent = GetHookEventRemote()
                    if hookEvent then
                        hookEvent:FireServer(target.Character)
                    end
                end)
                
                if success then
                    spamCount = spamCount + 1
                end
            end
            
            task.wait(0.1) -- Задержка между вызовами
        end
    end
    
    local function setupHook()
        if hooked then return end
        
        local hookEvent = GetHookEventRemote()
        if not hookEvent then
            print("SpamHook: HookEvent remote not found")
            return false
        end
        
        -- Получаем метатаблицу
        mt = getrawmetatable(hookEvent)
        if not mt then
            print("SpamHook: Could not get metatable")
            return false
        end
        
        originalNamecall = mt.__namecall
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == hookEvent and method == "FireServer" and enabled and spamCount < maxSpam then
                local args = {...}
                
                -- Оригинальный вызов
                originalNamecall(self, unpack(args))
                
                spamCount = spamCount + 1
                
                -- Если нужно спамить несколько раз сразу
                if enabled and spamCount < maxSpam then
                    task.wait(0.05)
                    originalNamecall(self, unpack(args))
                    spamCount = spamCount + 1
                end
                
                return
            end
            
            return originalNamecall(self, ...)
        end)
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = true
        print("SpamHook: Hook установлен")
        return true
    end
    
    local function removeHook()
        if not hooked or not mt or not originalNamecall then return end
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = originalNamecall
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = false
        originalNamecall = nil
        mt = nil
        spamCount = 0
        print("SpamHook: Hook удален")
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.SpamHookEnabled = true
        
        -- Устанавливаем хук
        if not setupHook() then
            -- Пробуем найти Remote позже
            task.spawn(function()
                task.wait(2)
                if enabled then
                    setupHook()
                end
            end)
        end
        
        -- Запускаем спам
        task.spawn(executeHookSpam)
        
        print("SpamHook: ON")
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.SpamHookEnabled = false
        
        spamCount = 0
        
        removeHook()
        print("SpamHook: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== DESTROY PALLETS ==========

local palletsDestroyed = false

local function DestroyAllPallets()
    if palletsDestroyed then
        return
    end
    
    local DestroyGlobal = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Destroy-Global")
    
    local character = Nexus.getCharacter()
    local savedPosition = nil
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        savedPosition = character.HumanoidRootPart.CFrame
    end
    
    palletsDestroyed = true
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name:find("PalletPoint") then
            DestroyGlobal:FireServer(obj)
        end
    end
    
    task.delay(3.2, function()
        if savedPosition and character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = savedPosition
        end
    end)
end

-- ========== NO SLOWDOWN ==========

local NoSlowdown = (function()
    local enabled = false
    local slowdownConnection = nil
    local originalSpeed = nil
    local speedLocked = false

    local function GetRole()
        if not Nexus.Player.Team then return "Survivor" end
        local teamName = Nexus.Player.Team.Name:lower()
        if teamName:find("killer") then 
            return "Killer" 
        end
        return "Survivor"
    end
    
    local function saveOriginalSpeed()
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            originalSpeed = humanoid.WalkSpeed
            speedLocked = false
            print("NoSlowdown: Saved original speed: " .. originalSpeed)
        end
    end
    
    local function restoreOriginalSpeed()
        local humanoid = Nexus.getHumanoid()
        if humanoid and originalSpeed then
            humanoid.WalkSpeed = originalSpeed
            print("NoSlowdown: Restored original speed: " .. originalSpeed)
        end
        speedLocked = false
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoSlowdownEnabled = true

        -- Сохраняем оригинальную скорость только один раз при включении
        saveOriginalSpeed()
        
        slowdownConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not enabled then return end
            
            if GetRole() ~= "Killer" then 
                return 
            end
            
            local char = Nexus.getCharacter()
            if not char then return end
            
            local hum = Nexus.getHumanoid()
            if not hum then return end
            
            -- Если скорость упала ниже 16 (замедление)
            if hum.WalkSpeed < 16 then
                -- Восстанавливаем сохраненную оригинальную скорость
                if originalSpeed and originalSpeed >= 16 then
                    hum.WalkSpeed = originalSpeed
                else
                    hum.WalkSpeed = 16  -- Минимальная нормальная скорость
                end
                speedLocked = true
            elseif not speedLocked and hum.WalkSpeed > (originalSpeed or 16) then
                -- Если скорость увеличилась (например, от эффектов), обновляем originalSpeed
                originalSpeed = hum.WalkSpeed
            end
        end)
        
        -- Обработчик смены персонажа
        local charAddedConnection
        charAddedConnection = Nexus.Player.CharacterAdded:Connect(function(newChar)
            if enabled then
                -- Отключаем старый коннекшн
                if slowdownConnection then
                    slowdownConnection:Disconnect()
                    slowdownConnection = nil
                end
                
                -- Ждем загрузки персонажа
                task.wait(1)
                
                -- Сохраняем новую оригинальную скорость
                saveOriginalSpeed()
                
                -- Перезапускаем цикл Heartbeat
                if enabled then
                    Enable() -- Перезапускаем для нового персонажа
                end
                
                -- Отключаем этот коннекшн, чтобы не копились
                if charAddedConnection then
                    charAddedConnection:Disconnect()
                end
            end
        end)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoSlowdownEnabled = false
        
        if slowdownConnection then
            Nexus.safeDisconnect(slowdownConnection)
            slowdownConnection = nil
        end
        
        -- Восстанавливаем оригинальную скорость
        restoreOriginalSpeed()
        
        print("NoSlowdown: Disabled")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()
-- ========== HITBOX EXPAND ==========

local Hitbox = (function()
    local enabled = false
    local size = 20
    local originalSizes = {}

    local function GetRole()
        if not Nexus.Player.Team then return "Survivor" end
        local teamName = Nexus.Player.Team.Name:lower()
        return teamName:find("killer") and "Killer" or "Survivor"
    end

    local function GetHealthPercent(hum)
        if not hum or hum.MaxHealth <= 0 then return 0 end
        return hum.Health / hum.MaxHealth
    end

    local function IsPlayerAlive(hum)
        local pct = GetHealthPercent(hum)
        return pct > 0.25
    end

    local function UpdateHitboxes()
        if not enabled or GetRole() ~= "Killer" then
            -- Восстанавливаем оригинальные размеры
            for player, originalSize in pairs(originalSizes) do
                if player and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size = originalSize
                        root.Transparency = 1
                        root.CanCollide = true
                    end
                end
            end
            originalSizes = {}
            return
        end
        
        for _, player in ipairs(Nexus.Services.Players:GetPlayers()) do
            if player ~= Nexus.Player then
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- Сохраняем оригинальный размер
                        if not originalSizes[player] then
                            originalSizes[player] = root.Size
                        end
                        
                        -- Устанавливаем новый размер
                        root.Size = Vector3.new(size, size, size)
                        root.CanCollide = false
                        root.Transparency = 0.7
                    elseif root then
                        -- Восстанавливаем оригинальный размер
                        if originalSizes[player] then
                            root.Size = originalSizes[player]
                            root.Transparency = 1
                            root.CanCollide = true
                            originalSizes[player] = nil
                        end
                    end
                end
            end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.HitboxEnabled = true
        
        Killer.Connections.Hitbox = Nexus.Services.RunService.Heartbeat:Connect(UpdateHitboxes)
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.HitboxEnabled = false
        
        if Killer.Connections.Hitbox then
            Killer.Connections.Hitbox:Disconnect()
            Killer.Connections.Hitbox = nil
        end
        
        -- Восстанавливаем оригинальные размеры
        for player, originalSize in pairs(originalSizes) do
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = originalSize
                    root.Transparency = 1
                    root.CanCollide = true
                end
            end
        end
        originalSizes = {}
    end

    local function SetSize(newSize)
        size = math.clamp(newSize, 20, 500)
        UpdateHitboxes()
    end

    local function GetSize()
        return size
    end

    return {
        Enable = Enable,
        Disable = Disable,
        SetSize = SetSize,
        GetSize = GetSize,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== BREAK GENERATOR ==========

local spamInProgress = false
local maxSpamCount = 1000

local function getGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

local function IsKiller()
    if not Nexus.Player.Team then return false end
    local teamName = Nexus.Player.Team.Name:lower()
    return teamName:find("killer") or teamName == "killer"
end

local function FindNearestGenerator(maxDistance)
    local character = Nexus.getCharacter()
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPosition = humanoidRootPart.Position
    local nearestGenerator = nil
    local nearestDistance = math.huge
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name == "Generator" then
            local hitBox = obj:FindFirstChild("HitBox")
            if hitBox then
                local distance = (hitBox.Position - playerPosition).Magnitude
                if distance < nearestDistance and distance <= maxDistance then
                    nearestDistance = distance
                    nearestGenerator = obj
                end
            end
        end
    end
    
    return nearestGenerator, nearestDistance
end

local function FullGeneratorBreak()
    if not IsKiller() then return end
    
    local nearestGenerator, distance = FindNearestGenerator(10)
    if not nearestGenerator then return end
    
    local progress = getGeneratorProgress(nearestGenerator)
    if progress <= 0 then return end
    
    local BreakGenEvent = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
    local hitBox = nearestGenerator:FindFirstChild("HitBox")
    
    if hitBox then
        BreakGenEvent:FireServer(hitBox, 0, true)
        return true
    end
    
    return false
end

local function SpamGeneratorBreak()
    if spamInProgress then return end
    
    if not IsKiller() then return end
    if not Nexus.Player.Character then return end
    
    local nearestGenerator = FindNearestGenerator(10)
    if not nearestGenerator then return end
    
    spamInProgress = true
    local spamCount = 0
    
    local connection
    connection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not spamInProgress then
            if connection then connection:Disconnect() end
            return
        end
        
        if not IsKiller() or not Nexus.Player.Character then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local currentGenerator = FindNearestGenerator(10)
        if not currentGenerator then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local progress = getGeneratorProgress(currentGenerator)
        if progress <= 0 then
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
        
        local hitBox = currentGenerator:FindFirstChild("HitBox")
        if hitBox then
            local BreakGenEvent = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
            BreakGenEvent:FireServer(hitBox, 0, true)
            spamCount = spamCount + 1
            
            if spamCount >= maxSpamCount then
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
        else
            spamInProgress = false
            if connection then connection:Disconnect() end
            return
        end
    end)
    
    local stopConnection
    stopConnection = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            if spamInProgress then
                spamInProgress = false
                if connection then connection:Disconnect() end
                if stopConnection then stopConnection:Disconnect() end
            end
        end
    end)
end

-- ========== THIRD PERSON ==========

local ThirdPerson = (function()
    local enabled = false
    local originalCameraType = nil
    local thirdPersonWasActive = false
    local offset = Vector3.new(2, 1, 8)

    local function GetRole()
        if not Nexus.Player.Team then return "Survivor" end
        local teamName = Nexus.Player.Team.Name:lower()
        return teamName:find("killer") and "Killer" or "Survivor"
    end

    local function UpdateThirdPerson()
        local cam = Nexus.Services.Workspace.CurrentCamera
        if not cam then return end
        local isKiller = GetRole() == "Killer"
        local shouldBeActive = enabled and isKiller
        
        if shouldBeActive then
            if not thirdPersonWasActive then
                originalCameraType = cam.CameraType
            end
            cam.CameraType = Enum.CameraType.Custom
            local char = Nexus.getCharacter()
            if char then
                local hum = Nexus.getHumanoid()
                if hum then hum.CameraOffset = offset end
            end
            thirdPersonWasActive = true
        elseif thirdPersonWasActive then
            if originalCameraType then
                cam.CameraType = originalCameraType
                originalCameraType = nil
            end
            local char = Nexus.getCharacter()
            if char then
                local hum = Nexus.getHumanoid()
                if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
            end
            thirdPersonWasActive = false
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.ThirdPersonEnabled = true
        
        Killer.Connections.ThirdPerson = Nexus.Services.RunService.Heartbeat:Connect(UpdateThirdPerson)
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.ThirdPersonEnabled = false
        
        if Killer.Connections.ThirdPerson then
            Killer.Connections.ThirdPerson:Disconnect()
            Killer.Connections.ThirdPerson = nil
        end
        
        -- Гарантированно восстанавливаем камеру
        task.wait(0.1) -- Небольшая задержка для стабильности
        
        local cam = Nexus.Services.Workspace.CurrentCamera
        if cam and originalCameraType then
            cam.CameraType = originalCameraType
            originalCameraType = nil
        end
        
        local char = Nexus.getCharacter()
        if char then
            local hum = Nexus.getHumanoid()
            if hum then 
                hum.CameraOffset = Vector3.new(0, 0, 0)
            end
        end
        thirdPersonWasActive = false
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetOffset = function(x, y, z)
            offset = Vector3.new(x or 2, y or 1, z or 8)
            UpdateThirdPerson()
        end
    }
end)()

-- ========== BEAT GAME (KILLER) ==========

local BeatGameKiller = (function()
    local enabled = false
    local targetPlayer = nil

    local function GetHealthPercent(hum)
        if not hum or hum.MaxHealth <= 0 then return 0 end
        return hum.Health / hum.MaxHealth
    end

    local function IsPlayerAlive(hum)
        local pct = GetHealthPercent(hum)
        return pct > 0.25
    end

    local function IsSurvivor(player)
        if not player or not player.Team then return false end
        local teamName = player.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end

    local function IsPlayerOnHook(player)
        if not player or not player.Character then return false end
        
        local character = player.Character
        
        -- Проверка по анимации/состоянию
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Проверка анимаций, связанных с хуком
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local animId = track.Animation.AnimationId:lower()
                    if animId:find("hook") or animId:find("trap") or animId:find("hanging") then
                        return true
                    end
                end
            end
        end
        
        -- Проверка по частям персонажа
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Проверка имени или описания
                local nameLower = part.Name:lower()
                if nameLower:find("hook") or nameLower:find("trap") then
                    return true
                end
            end
        end
        
        -- Проверка по атрибутам или значениям
        if character:GetAttribute("IsOnHook") or character:GetAttribute("IsTrapped") then
            return true
        end
        
        -- Проверка специальных объектов в персонаже
        if character:FindFirstChild("HookState") or character:FindFirstChild("TrapState") then
            return true
        end
        
        -- Проверка по позиции (если игрок долгое время стоит на месте)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- Если у игрока есть скрипт или объект Hook или Trap
            for _, obj in ipairs(rootPart:GetChildren()) do
                if obj.Name:lower():find("hook") or obj.Name:lower():find("trap") then
                    return true
                end
            end
        end
        
        return false
    end

    local function UpdateBeatGame()
        if not enabled then 
            targetPlayer = nil
            return 
        end
        
        if not Nexus.Player.Team or not Nexus.Player.Team.Name:lower():find("killer") then 
            targetPlayer = nil
            return 
        end
        
        local root = Nexus.getRootPart()
        if not root then return end
        
        local needNewTarget = true
        
        if targetPlayer and targetPlayer.Character then
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            
            if targetRoot and targetHum and IsPlayerAlive(targetHum) and IsSurvivor(targetPlayer) then
                -- Дополнительная проверка: не находится ли игрок на хуке
                if not IsPlayerOnHook(targetPlayer) then
                    needNewTarget = false
                else
                    targetPlayer = nil  -- Сбрасываем цель, если она на хуке
                end
            else
                targetPlayer = nil
            end
        end
        
        if needNewTarget then
            local survivors = {}
            
            for _, player in ipairs(Nexus.Services.Players:GetPlayers()) do
                if player ~= Nexus.Player and IsSurvivor(player) and player.Character then
                    local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if pRoot and pHum and IsPlayerAlive(pHum) then
                        -- Проверяем, не находится ли игрок на хуке
                        if not IsPlayerOnHook(player) then
                            table.insert(survivors, player)
                        end
                    end
                end
            end
            
            if #survivors > 0 then
                local closestDist = math.huge
                local closest = nil
                
                for _, player in ipairs(survivors) do
                    local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local dist = (pRoot.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
                
                targetPlayer = closest
            else
                targetPlayer = nil
                return
            end
        end
        
        if not targetPlayer or not targetPlayer.Character then return end
        
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not targetRoot or not targetHum then 
            targetPlayer = nil
            return 
        end
        
        if not IsPlayerAlive(targetHum) or IsPlayerOnHook(targetPlayer) then
            targetPlayer = nil
            return
        end
        
        -- Отключаем коллизию для телепортации
        local char = Nexus.getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        -- Телепортируемся к цели
        local targetPos = targetRoot.Position
        local direction = (root.Position - targetPos).Unit
        if direction.Magnitude ~= direction.Magnitude then 
            direction = Vector3.new(1, 0, 0)
        end
        local offsetPos = targetPos + direction * 3 + Vector3.new(0, 1, 0)
        
        root.CFrame = CFrame.new(offsetPos, targetPos)
        
        -- Атакуем
        pcall(function()
            local remotes = Nexus.Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local attacks = remotes:FindFirstChild("Attacks")
                if attacks then
                    local basicAttack = attacks:FindFirstChild("BasicAttack")
                    if basicAttack then
                        basicAttack:FireServer(false)
                    end
                end
            end
        end)
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.BeatGameKillerEnabled = true
        
        Killer.Connections.BeatGame = Nexus.Services.RunService.Heartbeat:Connect(UpdateBeatGame)
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.BeatGameKillerEnabled = false
        
        if Killer.Connections.BeatGame then
            Killer.Connections.BeatGame:Disconnect()
            Killer.Connections.BeatGame = nil
        end
        
        targetPlayer = nil
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        GetCurrentTarget = function() return targetPlayer end
    }
end)()

-- ========== ABYSSWALKER CORRUPT ==========

local AbysswalkerCorrupt = (function()
    local CorruptRemote = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Abysswalker"):WaitForChild("corrupt")
    local canActivate = true
    local cooldown = 0 

    local function fireCorruptEvent()
        if not canActivate then
            return
        end
        
        CorruptRemote:FireServer()
    
        canActivate = false
        task.delay(cooldown, function()
            canActivate = true
        end)
    end

    Nexus.Player.CharacterAdded:Connect(function(character)
        task.wait(2) 
    end)
    
    return {
        Activate = fireCorruptEvent,
        IsReady = function() return canActivate end
    }
end)()

-- ========== ANTI BLIND ==========

local AntiBlind = (function()
    local isAntiBlindEnabled = false
    local originalFireServer = nil
    local originalOnClientEvent = nil
    local hookedRemotes = {}

    local function findFlashlightRemote()
        local ReplicatedStorage = Nexus.Services.ReplicatedStorage
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        
        if remotes then
            local items = remotes:FindFirstChild("Items")
            if items then
                local flashlight = items:FindFirstChild("Flashlight")
                if flashlight then
                    local gotBlinded = flashlight:FindFirstChild("GotBlinded")
                    if gotBlinded and gotBlinded:IsA("RemoteEvent") then
                        return gotBlinded
                    end
                    
                    for _, child in ipairs(flashlight:GetChildren()) do
                        if child:IsA("RemoteEvent") and (child.Name:lower():find("blind") or child.Name:lower():find("flash")) then
                            return child
                        end
                    end
                end
            end
            
            local attacks = remotes:FindFirstChild("Attacks")
            if attacks then
                for _, child in ipairs(attacks:GetDescendants()) do
                    if child:IsA("RemoteEvent") and child.Name:lower():find("blind") then
                        return child
                    end
                end
            end
        end
        
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and (remote.Name:lower():find("blind") or remote.Name:lower():find("flashlight")) then
                return remote
            end
        end
        
        return nil
    end

    local function hookRemoteEvent(remote)
        if hookedRemotes[remote] then return end
        
        originalFireServer = remote.FireServer
        originalOnClientEvent = remote.OnClientEvent
        
        remote.FireServer = function(self, ...)
            if isAntiBlindEnabled then
                print("AntiBlind blocked: " .. self.Name)
                return nil
            end
            return originalFireServer(self, ...)
        end
        
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent = function(self, ...)
                if isAntiBlindEnabled then
                    print("AntiBlind blocked: " .. self.Name)
                    return nil
                end
                return originalOnClientEvent(self, ...)
            end
        end
        
        hookedRemotes[remote] = true
        print("AntiBlind hooked: " .. remote:GetFullName())
    end

    local function setupAntiBlind()
        local flashlightRemote = findFlashlightRemote()
        
        if flashlightRemote then
            hookRemoteEvent(flashlightRemote)
            return true
        else
            return false
        end
    end

    local function setupMetaTableHook()
        if not getrawmetatable or not setreadonly or not newcclosure then
            return false
        end
        
        local success = pcall(function()
            local gameMetaTable = getrawmetatable(game)
            if not gameMetaTable then return false end
            
            local originalNamecall = gameMetaTable.__namecall
            
            setreadonly(gameMetaTable, false)
            
            gameMetaTable.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                
                if isAntiBlindEnabled and method == "FireServer" then
                    local remoteName = tostring(self)
                    if remoteName:lower():find("blind") or remoteName:lower():find("flash") then
                        print("AntiBlind blocked via metatable: " .. remoteName)
                        return nil
                    end
                end
            
                return originalNamecall(self, ...)
            end)
            
            setreadonly(gameMetaTable, true)
            return true
        end)
        
        return success
    end

    local function restoreHooks()
        for remote, _ in pairs(hookedRemotes) do
            if remote and remote.Parent then
                if originalFireServer then
                    remote.FireServer = originalFireServer
                end
                if originalOnClientEvent then
                    remote.OnClientEvent = originalOnClientEvent
                end
            end
        end
        hookedRemotes = {}
    end

    local function Enable()
        if isAntiBlindEnabled then return end
        isAntiBlindEnabled = true
        Nexus.States.KillerAntiBlindEnabled = true
        
        setupAntiBlind()
        setupMetaTableHook()
        
        task.spawn(function()
            for i = 1, 5 do
                task.wait(2)
                if isAntiBlindEnabled then
                    setupAntiBlind()
                end
            end
        end)
        
        print("AntiBlind Enabled")
    end

    local function Disable()
        if not isAntiBlindEnabled then return end
        isAntiBlindEnabled = false
        Nexus.States.KillerAntiBlindEnabled = false
        
        print("AntiBlind: Disabled")
        restoreHooks()
    end

    task.spawn(function()
        task.wait(3)
        pcall(setupAntiBlind)
        pcall(setupMetaTableHook)
    end)

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return isAntiBlindEnabled end
    }
end)()

-- ========== NO PALLET STUN ==========

local NoPalletStun = (function()
    local enabled = false
    local hooked = false
    local originalConnections = {}
    local stunRemote, stunOverRemote
    
    local function getRemotes()
        if not stunRemote then
            local success1, remote1 = pcall(function()
                return Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Stun")
            end)
            
            local success2, remote2 = pcall(function()
                return Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Stunover")
            end)
            
            if success1 then stunRemote = remote1 end
            if success2 then stunOverRemote = remote2 end
        end
        return stunRemote, stunOverRemote
    end
    
    local function setupHook()
        if hooked then return end
        
        local stunRemote, stunOverRemote = getRemotes()
        if not stunRemote or not stunOverRemote then
            print("NoPalletStun: Could not find remotes")
            return false
        end
        
        -- Блокируем через метатаблицу
        local mt = getrawmetatable(stunRemote)
        if not mt then return false end
        
        local originalNamecall = mt.__namecall
        
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == stunRemote and method == "FireServer" and enabled then
                -- Блокируем оглушение и сразу отправляем завершение
                if stunOverRemote then
                    stunOverRemote:FireServer()
                end
                return nil
            end
            
            return originalNamecall(self, ...)
        end)
        
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        -- Также блокируем OnClientEvent для клиентских вызовов
        local originalOnClientEvent = stunRemote.OnClientEvent
        stunRemote.OnClientEvent = function(...)
            if enabled then
                if stunOverRemote then
                    stunOverRemote:FireServer()
                end
                return nil
            end
            return originalOnClientEvent(...)
        end
        
        hooked = true
        print("NoPalletStun: Hook установлен")
        return true
    end
    
    local function removeHook()
        if not hooked then return end
        
        -- Восстанавливаем оригинальный функционал
        local stunRemote = getRemotes()
        if stunRemote then
            local mt = getrawmetatable(stunRemote)
            if mt and mt.__namecall then
                local wasReadonly = isreadonly and isreadonly(mt)
                if setreadonly then
                    setreadonly(mt, false)
                end
                
                -- Нужно найти оригинальный namecall в замыкании
                -- Для простоты перезагрузим игру или создадим новый экземпляр
                -- В этом случае проще отключить функцию
            end
        end
        
        hooked = false
        print("NoPalletStun: Hook удален")
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoPalletStunEnabled = true
        
        if not setupHook() then
            -- Пробуем найти Remote позже
            task.spawn(function()
                for i = 1, 5 do
                    task.wait(1)
                    if enabled and not hooked then
                        if setupHook() then break end
                    end
                end
            end)
        end
        
        print("NoPalletStun: ON")
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoPalletStunEnabled = false
        
        removeHook()
        print("NoPalletStun: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== NO FALL ==========

local NoFall = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    
    local function getFallRemote()
        local success, remote = pcall(function()
            return Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
        end)
        return success and remote or nil
    end
    
    local function setupHook()
        if hooked then return end
        
        local fallRemote = getFallRemote()
        if not fallRemote then
            print("NoFall: Fall remote not found")
            return false
        end
        
        -- Получаем метатаблицу
        mt = getrawmetatable(fallRemote)
        if not mt then
            print("NoFall: Could not get metatable")
            return false
        end
        
        originalNamecall = mt.__namecall
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == fallRemote and method == "FireServer" and enabled then
                print("NoFall: Blocked fall damage")
                return nil -- Блокируем вызов
            end
            
            return originalNamecall(self, ...)
        end)
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = true
        print("NoFall: Hook установлен")
        return true
    end
    
    local function removeHook()
        if not hooked or not mt or not originalNamecall then return end
        
        -- Временно снимаем защиту
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = originalNamecall
        
        -- Возвращаем защиту если была
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = false
        originalNamecall = nil
        mt = nil
        print("NoFall: Hook удален")
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoFallEnabled = true
        
        if not setupHook() then
            -- Пробуем найти Remote позже
            task.spawn(function()
                for i = 1, 5 do
                    task.wait(1)
                    if enabled and not hooked then
                        if setupHook() then break end
                    end
                end
            end)
        end
        
        print("NoFall: ON")
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoFallEnabled = false
        
        removeHook()
        print("NoFall: OFF")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== MASK POWERS ==========

local function activateMaskPower(maskName)
    local success, result = pcall(function()
        local remotes = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes")
        local killers = remotes:WaitForChild("Killers")
        local masked = killers:WaitForChild("Masked")
        local activatePower = masked:WaitForChild("Activatepower")
        
        if not Nexus.Player.Team or Nexus.Player.Team.Name ~= "Killer" then
            return false
        end
        
        activatePower:FireServer(maskName)
        return true
    end)
    
    return success and result
end

-- ========== MODULE INITIALIZATION ==========

function Killer.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== SPEAR CROSSHAIR ==========
    local SpearCrosshairToggle = Tabs.Killer:AddToggle("SpearCrosshair", {
        Title = "Spear Crosshair (Veil)", 
        Description = "Показывает прицел в режиме копья Veil", 
        Default = false
    })

    SpearCrosshairToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                SpearCrosshair.Enable() 
            else 
                SpearCrosshair.Disable() 
            end
        end)
    end)

    -- ========== DESTROY PALLETS ==========
    local DestroyPalletsToggle = Tabs.Killer:AddToggle("DestroyPallets", {
        Title = "Destroy Pallets", 
        Description = "smash all the pallets on the map", 
        Default = false
    })

    DestroyPalletsToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Nexus.States.DestroyPalletsEnabled = v
        end)
    end)

    -- ========== NO SLOWDOWN ==========
    local NoSlowdownToggle = Tabs.Killer:AddToggle("NoSlowdown", {
        Title = "No Slowdown", 
        Description = "Prevents slowdown when attacking", 
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

    -- ========== HITBOX EXPAND ==========
    local HitboxToggle = Tabs.Killer:AddToggle("Hitbox", {
        Title = "Hitbox Expand", 
        Description = "Expand survivor hitboxes for easier hits", 
        Default = false
    })

    HitboxToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Hitbox.Enable() 
            else 
                Hitbox.Disable() 
            end
        end)
    end)

    local HitboxSlider = Tabs.Killer:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Description = "Adjust hitbox size",
        Default = 20,
        Min = 20,
        Max = 500,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                Hitbox.SetSize(value)
            end)
        end
    })

    -- ========== BREAK GENERATOR ==========
    local BreakGeneratorToggle = Tabs.Killer:AddToggle("BreakGenerator", {
        Title = "FullGeneratorBreak", 
        Description = "complete generator failure", 
        Default = false
    })

    BreakGeneratorToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Nexus.States.BreakGeneratorEnabled = v
        end)
    end)

    -- ========== THIRD PERSON ==========
    local ThirdPersonToggle = Tabs.Killer:AddToggle("ThirdPerson", {
        Title = "Third Person", 
        Description = "Toggle third person view (Killer only)", 
        Default = false
    })

    ThirdPersonToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                ThirdPerson.Enable() 
            else 
                ThirdPerson.Disable() 
            end
        end)
    end)

        -- ========== NO PALLET STUN ==========
    local NoPalletStunToggle = Tabs.Killer:AddToggle("NoPalletStun", {
        Title = "No Pallet Stun", 
        Description = "Protection against pallet stunning", 
        Default = false
    })

    NoPalletStunToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                NoPalletStun.Enable() 
            else 
                NoPalletStun.Disable() 
            end
        end)
    end)

    -- ========== NO FALL ==========
    local NoFallToggle = Tabs.Killer:AddToggle("NoFall", {
        Title = "No Fall", 
        Description = "Disables the penalty when falling", 
        Default = false
    })

    NoFallToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                NoFall.Enable() 
            else 
                NoFall.Disable() 
            end
        end)
    end)

 -- ========== DOUBLE TAP ==========
    local DoubleTapToggle = Tabs.Killer:AddToggle("DoubleTap", {
        Title = "Double Tap", 
        Description = "Атакует дважды при одной атаке", 
        Default = false
    })

    DoubleTapToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                DoubleTap.Enable() 
            else 
                DoubleTap.Disable() 
            end
        end)
    end)

    -- ========== SPAM HOOK ==========
    local SpamHookToggle = Tabs.Killer:AddToggle("SpamHook", {
        Title = "Spam Hook", 
        Description = "You can kill a survivor with one hook hit (and still farm the reward)", 
        Default = false
    })

    SpamHookToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                SpamHook.Enable() 
            else 
                SpamHook.Disable() 
            end
        end)
    end)

    
    -- ========== BEAT GAME (KILLER) ==========
    local BeatGameToggle = Tabs.Killer:AddToggle("BeatGame", {
        Title = "Beat Game (Killer)", 
        Description = "Automatically hunt and kill all survivors", 
        Default = false
    })

    BeatGameToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                BeatGameKiller.Enable() 
            else 
                BeatGameKiller.Disable() 
            end
        end)
    end)

    -- ========== ABYSSWALKER CORRUPT ==========
    local AbysswalkerCorruptKeybind = Tabs.Killer:AddKeybind("AbysswalkerCorruptKeybind", {
        Title = "Abysswalker Corrupt [NO COOLDOWN]",
        Description = "Activate Abysswalker corrupt ability",
        Default = "",
        Callback = function()
            Nexus.SafeCallback(function()
                AbysswalkerCorrupt.Activate()
            end)
        end,
        ChangedCallback = function(newKey)
            -- Optional: handle key change
        end
    })

    -- ========== ANTI BLIND ==========
    local AntiBlindToggle = Tabs.Killer:AddToggle("AntiBlind", {
        Title = "Anti Blind", 
        Description = "prevents you from being blinded by a flashlight", 
        Default = false
    })

    AntiBlindToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                AntiBlind.Enable() 
            else 
                AntiBlind.Disable() 
            end
        end)
    end)

    -- ========== MASK POWERS ==========
    local MaskPowers = Tabs.Killer:AddDropdown("MaskPowers", {
        Title = "Mask Powers",
        Description = "Select mask power to activate immediately",
        Values = {"Alex", "Tony", "Brandon", "Jake", "Richter", "Graham", "Richard"},
        Multi = false,
        Default = ""
    })

    MaskPowers:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value and value ~= "" then
                activateMaskPower(value)
            end
        end)
    end)

    -- ========== INFORMATION ==========
    Tabs.Killer:AddParagraph({
        Title = "Mask Powers Information",
        Content = "Alex - Chainsaw\nTony - Fists\nBrandon - Speed\nJake - Long lunge\nRichter - Stealth\nGraham - Faster vaults\nRichard - Default mask"
    })

    -- ========== HANDLE DESTRUCTION FUNCTIONS ==========
    local function handleDestructionFunctions()
        while true do
            task.wait(0.5)
            if Nexus.States.DestroyPalletsEnabled then
                DestroyAllPallets()
            end
        end
    end
    task.spawn(handleDestructionFunctions)

    -- ========== HANDLE GENERATOR BREAK ==========
    Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            if Nexus.States.BreakGeneratorEnabled then
                SpamGeneratorBreak()
            end
        end
    end)

    print("✓ Killer module initialized")
end

-- ========== CLEANUP ==========

function Killer.Cleanup()
    -- Отключаем все функции
    SpearCrosshair.Disable()
    NoSlowdown.Disable()
    Hitbox.Disable()
    DoubleTap.Disable()      
    SpamHook.Disable()  
    ThirdPerson.Disable()
    NoPalletStun.Disable()  
    NoFall.Disable()   
    BeatGameKiller.Disable()
    AntiBlind.Disable()
    
    -- Очищаем все соединения
    for key, connection in pairs(Killer.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Killer.Connections = {}
    
    -- Очищаем кэш хитбоксов
    Killer.HitboxCache = {}
    
    print("Killer module cleaned up")
end

return Killer --  Дай полный модульный код с добавленными новыми функциями , сохрани весь функционал
