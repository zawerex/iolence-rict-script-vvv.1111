-- Survivor.lua - Модуль для функций Survivor
local Nexus = require(script.Parent.NexusMain) -- Предполагаем, что основной файл называется NexusMain

local SurvivorModule = {}

-- Инициализация функций Survivor
function SurvivorModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    -- Получаем глобальные функции
    local player = nexus.Player
    local ReplicatedStorage = nexus.Services.ReplicatedStorage
    local RunService = nexus.Services.RunService
    local UserInputService = nexus.Services.UserInputService
    local VirtualInputManager = nexus.Services.VirtualInputManager
    local Workspace = nexus.Services.Workspace
    
    -- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
    local function getCharacter()
        return player.Character
    end
    
    local function getRootPart()
        local char = getCharacter()
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    
    local function getHumanoid()
        local char = getCharacter()
        return char and char:FindFirstChildOfClass("Humanoid")
    end
    
    local function r15(speaker)
        local character = speaker.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        return humanoid.RigType == Enum.HumanoidRigType.R15
    end
    
    -- ========== NoTurnLimit ФУНКЦИЯ ==========
    local NoTurnLimit = (function()
        local enabled = false
        local turnLimitConnection = nil
        
        local function IsSurvivor()
            if not player.Team then return false end
            local teamName = player.Team.Name:lower()
            return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
        end

        local function Enable()
            if enabled then return end
            enabled = true
            nexus.FunctionStates.NoTurnLimitEnabled = true
            print("NoTurnLimit Enabled")
            
            turnLimitConnection = RunService.RenderStepped:Connect(function()
                if not enabled or not IsSurvivor() then return end
                
                local character = getCharacter()
                if not character then return end
                
                local humanoid = getHumanoid()
                if humanoid then
                    if humanoid.WalkSpeed < 16 then 
                        humanoid.WalkSpeed = 16
                    end
                    
                    humanoid.AutoRotate = true
                end
            end)
        end

        local function Disable()
            if not enabled then return end
            enabled = false
            nexus.FunctionStates.NoTurnLimitEnabled = false
            
            if turnLimitConnection then
                SafeCallback(function()
                    turnLimitConnection:Disconnect()
                    turnLimitConnection = nil
                end)
            end
            
            print("NoTurnLimit Disabled")
        end

        return {
            Enable = Enable,
            Disable = Disable,
            IsEnabled = function() return enabled end
        }
    end)()
    
    -- ========== AutoParry (ОРИГИНАЛЬНЫЙ) ==========
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

    local AutoParry = (function()
        local spamActive = false
        local RANGE = 10
        local lastCheck = 0
        local CHECK_INTERVAL = 0.01

        local function isBlockingInRange()
            local currentTime = tick()
            if currentTime - lastCheck < CHECK_INTERVAL then return false end
            lastCheck = currentTime
            
            local myChar, myPos = player.Character, player.Character and player.Character.HumanoidRootPart and player.Character.HumanoidRootPart.Position
            if not myChar or not myPos then return false end

            for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                if plr == player then continue end
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

        local function Enable()
            if nexus.FunctionStates.AutoParryEnabled then return end
            nexus.FunctionStates.AutoParryEnabled = true
            print("AutoParry Enabled")
            
            nexus.Connections.AutoParry = RunService.Heartbeat:Connect(function()
                if not nexus.FunctionStates.AutoParryEnabled then
                    if spamActive then 
                        spamActive = false; 
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) 
                    end
                    return
                end

                if isBlockingInRange() then
                    if not spamActive then
                        spamActive = true
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                        task.spawn(function()
                            task.wait(0.01)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                        end)
                    end
                elseif spamActive then
                    spamActive = false
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                end
            end)
        end

        local function Disable()
            nexus.FunctionStates.AutoParryEnabled = false
            if spamActive then 
                spamActive = false; 
                VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) 
            end 
            
            if nexus.Connections.AutoParry then
                nexus.Connections.AutoParry:Disconnect()
                nexus.Connections.AutoParry = nil
            end
            print("AutoParry Disabled")
        end

        return {
            Enable = Enable,
            Disable = Disable,
            IsEnabled = function() return nexus.FunctionStates.AutoParryEnabled end,
            SetRange = function(value) 
                RANGE = tonumber(value) or 10
                print("AutoParry range set to: " .. RANGE)
            end,
            GetRange = function() return RANGE end
        }
    end)()
    
    -- ========== AutoParryV2 (АНТИ-СТАН) ==========
    local AutoParryV2 = (function()
        local isParryOnCooldown = false
        local animationConnections, customBar, fillBar, timeText = {}, nil, nil, nil
        local PARRY_COOLDOWN = 40.264
        local RANGE = 10
        local hideBarsConnection = nil

        local function IsPlayerKiller(targetPlayer)
            if not targetPlayer or not targetPlayer.Character then return false end
            if targetPlayer.Team then return targetPlayer.Team.Name:lower() == "killer" end
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            return humanoid and humanoid.DisplayName:lower() == "killer"
        end

        local function IsPlayerInRange(targetPlayer, maxDistance)
            local localRoot = getRootPart()
            local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if not localRoot or not targetRoot then return false end
            
            local distance = (localRoot.Position - targetRoot.Position).Magnitude
            local numDistance = tonumber(distance) or 0
            local numMaxDistance = tonumber(maxDistance) or 10
            
            return numDistance <= numMaxDistance
        end

        local function IsAttackEmote(emoteId)
            if not emoteId or type(emoteId) ~= "string" then return false end
            
            for _, attackId in ipairs(AttackAnimations) do 
                if emoteId == attackId then 
                    return true 
                end 
            end
            return false
        end

        local function HideOriginalBars()
            SafeCallback(function()
                local playerGui = player:WaitForChild("PlayerGui")
                local survivorGui = playerGui:FindFirstChild("Survivor")
                if survivorGui then
                    local genFrame = survivorGui:FindFirstChild("Gen")
                    if genFrame then
                        local itemFrame = genFrame:FindFirstChild("ItemFrame")
                        if itemFrame then
                            local gui = itemFrame:FindFirstChild("Gui")
                            if gui then
                                local originalBar = gui:FindFirstChild("Bar")
                                local originalBack = gui:FindFirstChild("back")
                                if originalBar then 
                                    originalBar.Visible = false 
                                    print("Original Bar hidden")
                                end
                                if originalBack then 
                                    originalBack.Visible = false 
                                    print("Original Back hidden")
                                end
                            end
                        end
                    end
                end
            end)
        end

        local function ShowOriginalBars()
            SafeCallback(function()
                local playerGui = player:WaitForChild("PlayerGui")
                local survivorGui = playerGui:FindFirstChild("Survivor")
                if survivorGui then
                    local genFrame = survivorGui:FindFirstChild("Gen")
                    if genFrame then
                        local itemFrame = genFrame:FindFirstChild("ItemFrame")
                        if itemFrame then
                            local gui = itemFrame:FindFirstChild("Gui")
                            if gui then
                                local originalBar = gui:FindFirstChild("Bar")
                                local originalBack = gui:FindFirstChild("back")
                                if originalBar then originalBar.Visible = true end
                                if originalBack then originalBack.Visible = true end
                            end
                        end
                    end
                end
            end)
        end

        local function StartConstantBarHiding()
            if hideBarsConnection then
                hideBarsConnection:Disconnect()
                hideBarsConnection = nil
            end
            
            hideBarsConnection = RunService.Heartbeat:Connect(function()
                if not nexus.FunctionStates.AutoParryV2Enabled then
                    if hideBarsConnection then
                        hideBarsConnection:Disconnect()
                        hideBarsConnection = nil
                    end
                    return
                end
                
                SafeCallback(function()
                    local playerGui = player:WaitForChild("PlayerGui")
                    local survivorGui = playerGui:FindFirstChild("Survivor")
                    if survivorGui then
                        local genFrame = survivorGui:FindFirstChild("Gen")
                        if genFrame then
                            local itemFrame = genFrame:FindFirstChild("ItemFrame")
                            if itemFrame then
                                local gui = itemFrame:FindFirstChild("Gui")
                                if gui then
                                    local originalBar = gui:FindFirstChild("Bar")
                                    local originalBack = gui:FindFirstChild("back")
                                    
                                    if originalBar and originalBar.Visible then
                                        originalBar.Visible = false
                                    end
                                    if originalBack and originalBack.Visible then
                                        originalBack.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end)
            end)
        end

        local function CreateCustomBar()
            if customBar and customBar.Gui then 
                SafeCallback(function() customBar.Gui:Destroy() end) 
            end
            
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "CustomParryBar"
            screenGui.Parent = player:WaitForChild("PlayerGui")
            screenGui.ResetOnSpawn = false
            
            local mainContainer = Instance.new("Frame")
            mainContainer.Name = "MainContainer"
            mainContainer.Size = UDim2.new(0, 40, 0, 150)
            mainContainer.Position = UDim2.new(0, 10, 1, -317)
            mainContainer.BackgroundTransparency = 1
            mainContainer.Visible = nexus.FunctionStates.AutoParryV2Enabled
            mainContainer.Parent = screenGui
            
            timeText = Instance.new("TextLabel")
            timeText.Name = "TimeText"
            timeText.Size = UDim2.new(1, 0, 0, 25)
            timeText.Position = UDim2.new(0, 0, 0, 0)
            timeText.BackgroundTransparency = 1
            timeText.Text = "00.000"
            timeText.TextColor3 = Color3.fromRGB(255, 255, 255)
            timeText.TextScaled = true
            timeText.Font = Enum.Font.GothamBold
            timeText.TextXAlignment = Enum.TextXAlignment.Center
            timeText.Parent = mainContainer
            
            local barContainer = Instance.new("Frame")
            barContainer.Name = "BarContainer"
            barContainer.Size = UDim2.new(0, 10, 0, 80)
            barContainer.Position = UDim2.new(0.5, -5, 0, 30)
            barContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            barContainer.BorderSizePixel = 1
            barContainer.BorderColor3 = Color3.fromRGB(100, 100, 100)
            barContainer.Parent = mainContainer
            
            local containerCorner = Instance.new("UICorner")
            containerCorner.CornerRadius = UDim.new(1, 0) 
            containerCorner.Parent = barContainer
            
            fillBar = Instance.new("Frame")
            fillBar.Name = "Fill"
            fillBar.Size = UDim2.new(1, 0, 0, 0)
            fillBar.Position = UDim2.new(0, 0, 1, 0)
            fillBar.AnchorPoint = Vector2.new(0, 1)
            fillBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            fillBar.BorderSizePixel = 0
            fillBar.Parent = barContainer
            
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fillBar
            
            customBar = {Gui = screenGui, Container = mainContainer, Fill = fillBar, TimeText = timeText}
            return customBar
        end

        local function StartParryCooldown()
            if isParryOnCooldown then return end
            isParryOnCooldown = true
            if customBar and customBar.Container then customBar.Container.Visible = true end
            
            local startTime, endTime = tick(), tick() + PARRY_COOLDOWN
            task.spawn(function()
                while tick() < endTime and isParryOnCooldown do
                    local currentTime, elapsed, progress, remainingTime = tick(), tick() - startTime, (tick() - startTime) / PARRY_COOLDOWN, endTime - tick()
                    if progress > 1 then progress = 1 end
                    if fillBar then fillBar.Size = UDim2.new(1, 0, progress, 0) end
                    if timeText then
                        timeText.Text = remainingTime > 0 and string.format("%02d.%03d", math.floor(remainingTime), math.floor((remainingTime - math.floor(remainingTime)) * 1000)) or "00.000"
                    end
                    task.wait(0.01)
                end
                
                if isParryOnCooldown then
                    isParryOnCooldown = false
                    if customBar and customBar.Container then
                        if fillBar then fillBar.Size = UDim2.new(1, 0, 1, 0) end
                        if timeText then timeText.Text = "00.000" end
                    end
                end
            end)
        end

        local function ClearAnimationConnections()
            for _, connection in pairs(animationConnections) do 
                SafeCallback(function() connection:Disconnect() end)
            end
            animationConnections = {}
        end

        local function Enable()
            if nexus.FunctionStates.AutoParryV2Enabled then return end
            nexus.FunctionStates.AutoParryV2Enabled = true
            print("AutoParryV2 Enabled")
            
            CreateCustomBar()
            HideOriginalBars()
            StartConstantBarHiding()
            
            if customBar and customBar.Container then 
                customBar.Container.Visible = true 
            end
            
            local function setupPlayerTracking(targetPlayer)
                if animationConnections[targetPlayer] then return end
                
                local function trackCharacter(character)
                    local humanoid = character:WaitForChild("Humanoid")
                    if humanoid then
                        local connection = humanoid.AnimationPlayed:Connect(function(animationTrack)
                            if not animationTrack or not animationTrack.Animation then return end
                            
                            if IsPlayerKiller(targetPlayer) and 
                               IsPlayerInRange(targetPlayer, RANGE) and 
                               IsAttackEmote(animationTrack.Animation.AnimationId) and 
                               not isParryOnCooldown then
                                SafeCallback(function()
                                    ReplicatedStorage.Remotes.Items["Parrying Dagger"].parry:FireServer()
                                    StartParryCooldown()
                                end)
                            end
                        end)
                        animationConnections[targetPlayer] = connection
                    end
                end
                
                if targetPlayer.Character then trackCharacter(targetPlayer.Character) end
                targetPlayer.CharacterAdded:Connect(trackCharacter)
                targetPlayer.CharacterRemoving:Connect(function()
                    if animationConnections[targetPlayer] then 
                        SafeCallback(function() animationConnections[targetPlayer]:Disconnect() end)
                        animationConnections[targetPlayer] = nil 
                    end
                end)
            end
            
            for _, targetPlayer in ipairs(game:GetService("Players"):GetPlayers()) do 
                if targetPlayer ~= player then 
                    setupPlayerTracking(targetPlayer) 
                end 
            end
            
            game:GetService("Players").PlayerAdded:Connect(function(targetPlayer) 
                if targetPlayer ~= player then 
                    setupPlayerTracking(targetPlayer) 
                end 
            end)
        end

        local function Disable()
            if not nexus.FunctionStates.AutoParryV2Enabled then return end
            nexus.FunctionStates.AutoParryV2Enabled = false
            
            if hideBarsConnection then
                hideBarsConnection:Disconnect()
                hideBarsConnection = nil
            end
            
            ClearAnimationConnections()
            ShowOriginalBars()
            if customBar and customBar.Container then 
                customBar.Container.Visible = false 
            end
            print("AutoParryV2 Disabled")
        end

        task.spawn(function()
            player:WaitForChild("PlayerGui")
            CreateCustomBar()
        end)

        player.CharacterRemoving:Connect(function()
            if nexus.FunctionStates.AutoParryV2Enabled then
                if customBar and customBar.Container then 
                    customBar.Container.Visible = false 
                end
            end
        end)

        player.CharacterAdded:Connect(function()
            if nexus.FunctionStates.AutoParryV2Enabled then
                task.wait(1)
                CreateCustomBar()
                HideOriginalBars()
                StartConstantBarHiding()
                
                if customBar and customBar.Container then 
                    customBar.Container.Visible = true 
                end
            end
        end)

        return {
            Enable = Enable, 
            Disable = Disable, 
            IsEnabled = function() return nexus.FunctionStates.AutoParryV2Enabled end,
            SetRange = function(value) 
                RANGE = tonumber(value) or 10
                
                if nexus.FunctionStates.AutoParryV2Enabled then
                    Disable()
                    task.wait(0.1)
                    Enable()
                end
                print("AutoParryV2 range set to: " .. RANGE)
            end,
            GetRange = function() return RANGE end
        }
    end)()
    
    -- ========== HEALING ФУНКЦИИ ==========
    local SendStopHealEvent = function() end
    
    local function StartInstantHeal()
        nexus.FunctionStates.InstantHealRunning = true
        
        local function IsSurvivor(targetPlayer)
            if not targetPlayer or not targetPlayer.Team then return false end
            
            local teamName = targetPlayer.Team.Name:lower()
            return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
        end
        
        nexus.Connections.instantHeal = task.spawn(function()
            while nexus.FunctionStates.InstantHealRunning do
                local char = getCharacter()
                if char and getRootPart() then
                    for _, target in ipairs(game:GetService("Players"):GetPlayers()) do
                        if target ~= player then
                            if not IsSurvivor(target) then
                                continue 
                            end
                            if target.Character then
                                local targetChar, humanoid = target.Character, target.Character:FindFirstChild("Humanoid")
                                if humanoid and humanoid.Health < humanoid.MaxHealth then
                                    SafeCallback(function() 
                                        if ReplicatedStorage.Remotes and ReplicatedStorage.Remotes.Healing then
                                            ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer("success", 1, targetChar) 
                                            print("Instant Healing Survivor: " .. target.Name)
                                        end
                                    end)
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
        nexus.FunctionStates.InstantHealRunning = false
        SafeCallback(function()
            if nexus.Connections.instantHeal then
                nexus.Connections.instantHeal:Disconnect()
                nexus.Connections.instantHeal = nil
            end
        end)
    end
    
    -- ========== SILENT HEAL ==========
    local currentValue = true
    local healingStates = {
        silentHealRunning = false,
        instantHealRunning = false,
        lastHealTime = 0,
        healCooldown = 0.2
    }

    local function ResetAllHealing()
        healingStates.silentHealRunning = false
        healingStates.instantHealRunning = false
        nexus.FunctionStates.SilentHealRunning = false
        nexus.FunctionStates.InstantHealRunning = false
        nexus.FunctionStates.autoHealEnabled = false
        
        if nexus.Connections.silentHeal then
            SafeCallback(function() nexus.Connections.silentHeal:Disconnect() end)
            nexus.Connections.silentHeal = nil
        end
        if nexus.Connections.instantHeal then
            SafeCallback(function() nexus.Connections.instantHeal:Disconnect() end)
            nexus.Connections.instantHeal = nil
        end
        if nexus.Connections.autoHeal then
            SafeCallback(function() nexus.Connections.autoHeal:Disconnect() end)
            nexus.Connections.autoHeal = nil
        end
        
        SafeCallback(function()
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if track and track.IsPlaying then
                            local animName = track.Animation and track.Animation.Name:lower() or ""
                            if animName:find("heal") or animName:find("cure") or animName:find("medical") then
                                track:Stop()
                            end
                        end
                    end
                end
            end
        end)
        
        for i = 1, 3 do
            SafeCallback(SendStopHealEvent)
            task.wait(0.1)
        end
        
        currentValue = true
    end

    local function StartSilentHeal()
        if healingStates.silentHealRunning then return end
        
        healingStates.silentHealRunning = true
        nexus.FunctionStates.SilentHealRunning = true
        currentValue = true
        
        local function IsSurvivor(targetPlayer)
            if not targetPlayer or not targetPlayer.Team then return false end
            
            local teamName = targetPlayer.Team.Name:lower()
            return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
        end
        
        nexus.Connections.silentHeal = task.spawn(function()
            while healingStates.silentHealRunning do
                local character = getCharacter()
                if not character or not getRootPart() then
                    task.wait(0.4)
                    continue
                end
                
                local humanoid = getHumanoid()
                if not humanoid or humanoid.Health <= 0 then
                    task.wait(0.4)
                    continue
                end
                
                local currentTime = tick()
                if currentTime - healingStates.lastHealTime < healingStates.healCooldown then
                    task.wait(healingStates.healCooldown)
                    continue
                end
                
                local needsHealing = false
                local playersHealed = 0
                
                for _, targetPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                    if targetPlayer == player then continue end
                    
                    if not IsSurvivor(targetPlayer) then
                        continue
                    end
                    
                    if targetPlayer and targetPlayer.Character then
                        local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if targetHumanoid and targetRoot and targetHumanoid.Health < targetHumanoid.MaxHealth then
                            needsHealing = true
                            playersHealed += 1
                            
                            if playersHealed <= 3 then
                                local args = {targetRoot, currentValue}
                                SafeCallback(function() 
                                    if ReplicatedStorage.Remotes and ReplicatedStorage.Remotes.Healing then
                                        ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                        healingStates.lastHealTime = tick()
                                        print("Healing Survivor: " .. targetPlayer.Name)
                                    end
                                end)
                            end
                        else
                            local args = {targetRoot, false}
                            SafeCallback(function() 
                                if ReplicatedStorage.Remotes and ReplicatedStorage.Remotes.Healing then
                                    ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                end
                            end)
                        end
                    end
                end
                
                if not needsHealing then 
                    SafeCallback(SendStopHealEvent)
                else 
                    currentValue = not currentValue 
                end
                
                task.wait(0.1)
            end
            
            SafeCallback(SendStopHealEvent)
            currentValue = true
        end)
    end

    local function StopSilentHeal()
        if not healingStates.silentHealRunning then return end
        
        healingStates.silentHealRunning = false
        nexus.FunctionStates.SilentHealRunning = false
        
        task.wait(0.1)
        
        if nexus.Connections.silentHeal then
            SafeCallback(function() nexus.Connections.silentHeal:Disconnect() end)
            nexus.Connections.silentHeal = nil
        end
        
        for i = 1, 2 do
            SafeCallback(SendStopHealEvent)
            task.wait(0.05)
        end
        
        SafeCallback(function()
            local character = getCharacter()
            if character then
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                end
            end
        end)
    end
    
    -- ========== SKILL CHECK ФУНКЦИИ ==========
    local function FindSkillCheckGUI()
        local PlayerGui = player:WaitForChild("PlayerGui")
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
        local char = player.Character
        if char then
            local skillCheckGen = char:FindFirstChild("Skillcheck-gen")
            if skillCheckGen then skillCheckGen.Enabled = false end
        end
    end

    local function PerformPerfectSkillCheck()
        if not nexus.FunctionStates.autoSkillEnabled then return end
        local skillCheckGui, checkPart, goalPart, linePart = FindSkillCheckGUI()
        if not skillCheckGui or not checkPart or not checkPart.Visible then return end
        
        local lineRot, goalRot = linePart.Rotation, goalPart.Rotation
        local minRot, maxRot = (104 + goalRot) % 360, (114 + goalRot) % 360
        if (minRot > maxRot and (lineRot >= minRot or lineRot <= maxRot)) or (lineRot >= minRot and lineRot <= maxRot) then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            return true
        end
        return false
    end
    
    -- ========== GATE TOOL ФУНКЦИЯ ==========
    local GateTool = (function()
        local toolInstance = nil
        local toolConnection = nil

        local function CreateTool()
            if not player:FindFirstChild("Backpack") then return nil end
            
            local existing = player.Backpack:FindFirstChild("Gate")
            if existing then 
                SafeCallback(function() 
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
            tool.Parent = player.Backpack
            
            tool.ManualActivationOnly = true
            
            return tool
        end

        local function UseGate()
            local gateRemote = ReplicatedStorage.Remotes and ReplicatedStorage.Remotes.Items and ReplicatedStorage.Remotes.Items.Gate and ReplicatedStorage.Remotes.Items.Gate.gate
            if gateRemote then 
                SafeCallback(function() 
                    gateRemote:FireServer() 
                end)
                return true 
            end
            return false
        end

        local function Enable()
            if nexus.FunctionStates.GateToolEnabled then return end
            nexus.FunctionStates.GateToolEnabled = true
            
            toolInstance = CreateTool()
            if toolInstance then 
                toolConnection = toolInstance.Activated:Connect(function()
                    SafeCallback(UseGate)
                end)
            end
        end

        local function Disable()
            nexus.FunctionStates.GateToolEnabled = false
            if toolConnection then
                SafeCallback(function() toolConnection:Disconnect() end)
                toolConnection = nil
            end
            if toolInstance then 
                SafeCallback(function() 
                    toolInstance:Destroy() 
                end) 
                toolInstance = nil
            end
            
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                local tool = backpack:FindFirstChild("Gate")
                if tool then 
                    SafeCallback(function() tool:Destroy() end) 
                end
            end
        end

        player.CharacterAdded:Connect(function() 
            if nexus.FunctionStates.GateToolEnabled then 
                task.wait(2)
                SafeCallback(Enable)
            end 
        end)

        return {Enable=Enable, Disable=Disable}
    end)()
    
    -- ========== NoFall ФУНКЦИЯ ==========
    local SimpleNoFall = (function()
        local enabled = false
        local remote = nil
        local originalFireServer = nil
        local loopConnection = nil

        local function Enable()
            if enabled then return end
            enabled = true
            
            task.spawn(function()
                remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
                originalFireServer = remote.FireServer

                local mt = getrawmetatable(remote)
                if mt then
                    setreadonly(mt, false)
                    local originalIndex = mt.__index
                    mt.__index = function(self, key)
                        if key == "FireServer" then
                            return function(...)
                                return nil
                            end
                        end
                        return originalIndex(self, key)
                    end
                    setreadonly(mt, true)
                end

                remote.FireServer = function(...)
                    return nil
                end

                loopConnection = task.spawn(function()
                    while task.wait(0.3) do
                        if remote.FireServer == originalFireServer then
                            remote.FireServer = function(...)
                                return nil
                            end
                        end
                    end
                end)
            end)
        end

        local function Disable()
            if not enabled then return end
            enabled = false
            
            if loopConnection then
                task.cancel(loopConnection)
                loopConnection = nil
            end
            
            if remote and originalFireServer then
                remote.FireServer = originalFireServer
            end
        end

        return {
            Enable = Enable,
            Disable = Disable,
            IsEnabled = function() return enabled end
        }
    end)()
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    -- Заголовок
    Tabs.Main:AddParagraph({
        Title = "Hello, " .. player.Name .. "!",
        Content = "Enjoy using it ♡"
    })

    -- NoTurnLimit Toggle
    local NoTurnLimitToggle = Tabs.Main:AddToggle("NoTurnLimit", {
        Title = "No slowing down", 
        Description = "No slowing down in speed", 
        Default = false
    })

    NoTurnLimitToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                NoTurnLimit.Enable() 
            else 
                NoTurnLimit.Disable() 
            end 
        end)
    end)

    -- AutoParry Toggle
    local AutoParryToggle = Tabs.Main:AddToggle("AutoParry", {
        Title = "AutoParry", 
        Description = "automatic parry of attacks", 
        Default = false
    })

    AutoParryToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                AutoParry.Enable() 
            else 
                AutoParry.Disable() 
            end 
        end)
    end)

    -- AutoParry Range Slider
    local AutoParryRangeSlider = Tabs.Main:AddSlider("AutoParryRange", {
        Title = "ping compensation",
        Description = "",
        Default = 10,
        Min = 0,
        Max = 20,
        Rounding = 2,
        Callback = function(value)
            SafeCallback(function()
                if AutoParry and AutoParry.SetRange then
                    local numValue = tonumber(value) or 10
                    AutoParry.SetRange(numValue)
                end
            end)
        end
    })

    -- AutoParryV2 Toggle
    local AutoParryV2Toggle = Tabs.Main:AddToggle("AutoParryV2", {
        Title = "AutoParry (Anti-Stun)", 
        Description = "automatic parry of attacks without delay", 
        Default = false
    })

    AutoParryV2Toggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                AutoParryV2.Enable() 
            else 
                AutoParryV2.Disable() 
            end 
        end)
    end)

    -- AutoParryV2 Range Slider
    local AutoParryV2RangeSlider = Tabs.Main:AddSlider("AutoParryV2Range", {
        Title = "ping compensation",
        Description = "",
        Default = 10,
        Min = 0,
        Max = 20,
        Rounding = 2,
        Callback = function(value)
            SafeCallback(function()
                if AutoParryV2 and AutoParryV2.SetRange then
                    local numValue = tonumber(value) or 10
                    AutoParryV2.SetRange(numValue)
                end
            end)
        end
    })

    -- Heal Toggle
    local HealToggle = Tabs.Main:AddToggle("Heal", {
        Title = "Heal", 
        Description = "", 
        Default = false
    })

    HealToggle:OnChanged(function(v)
        SafeCallback(function()
            nexus.FunctionStates.autoHealEnabled = v
            SafeCallback(function()
                if nexus.Connections.autoHeal then
                    nexus.Connections.autoHeal:Disconnect()
                end
            end)
            if v then
                nexus.Connections.autoHeal = RunService.Heartbeat:Connect(function()
                    if not nexus.FunctionStates.autoHealEnabled or not player.Character then 
                        SafeCallback(function()
                            if nexus.Connections.autoHeal then
                                nexus.Connections.autoHeal:Disconnect()
                            end
                        end)
                        return 
                    end
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                end)
            end
        end)
    end)

    -- Instant Heal Toggle
    local InstantHealToggle = Tabs.Main:AddToggle("InstantHeal", {
        Title = "Instant Heal", 
        Description = "instant treatment", 
        Default = false
    })

    InstantHealToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                StartInstantHeal() 
            else 
                StopInstantHeal() 
            end 
        end)
    end)

    -- Silent Heal Toggle
    local SilentHealToggle = Tabs.Main:AddToggle("SilentHeal", {
        Title = "Silent Heal", 
        Description = "Heals all players anywhere on the map. (recommended for instant healing)", 
        Default = false
    })

    SilentHealToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                StartSilentHeal() 
            else 
                StopSilentHeal() 
            end 
        end)
    end)

    -- Gunshot Toggle
    local Gun100Toggle = Tabs.Main:AddToggle("Gunshot", {
        Title = "100% shot", 
        Description = "100% shot from a pistol", 
        Default = false
    })

    -- Gate Tool Toggle
    local GateToolToggle = Tabs.Main:AddToggle("GateTool", {
        Title = "Gate Tool", 
        Description = "", 
        Default = false
    })

    GateToolToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                GateTool.Enable() 
            else 
                GateTool.Disable() 
            end 
        end)
    end)

    -- No Hitbox Toggle
    local NoHitboxToggle = Tabs.Main:AddToggle("NoHitbox", {
        Title = "No Hitbox", 
        Description = "", 
        Default = false
    })

    NoHitboxToggle:OnChanged(function(v)
        SafeCallback(function()
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do 
                if part:IsA("BasePart") then 
                    part.CanTouch = not v 
                end 
            end
            if v then
                player.CharacterAdded:Connect(function(char)
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

    -- Anti-Fail Generator Toggle
    local AntiFailToggle = Tabs.Main:AddToggle("AntiFailGenerator", {
        Title = "Anti-Fail Generator", 
        Description = "", 
        Default = false
    })

    AntiFailToggle:OnChanged(function(v)
        SafeCallback(function()
            nexus.FunctionStates.antiFailEnabled = v
            if v then
                DisableGeneratorFail()
                player.CharacterAdded:Connect(function(char) 
                    task.wait(1); 
                    if nexus.FunctionStates.antiFailEnabled then 
                        DisableGeneratorFail() 
                    end 
                end)
                nexus.Connections.antiFail = RunService.Heartbeat:Connect(function() 
                    if nexus.FunctionStates.antiFailEnabled then 
                        DisableGeneratorFail() 
                    end 
                end)
            else
                SafeCallback(function()
                    if nexus.Connections.antiFail then
                        nexus.Connections.antiFail:Disconnect()
                    end
                end)
            end
        end)
    end)

    -- NoFall Toggle
    local NoFallToggle = Tabs.Main:AddToggle("NoFall", {
        Title = "NoFall", 
        Description = "", 
        Default = false
    })

    NoFallToggle:OnChanged(function(v) 
        SafeCallback(function()
            if v then 
                SimpleNoFall.Enable() 
                nexus.FunctionStates.NoFallEnabled = true
            else 
                SimpleNoFall.Disable() 
                nexus.FunctionStates.NoFallEnabled = false
            end 
        end)
    end)

    -- Auto Perfect Skill Check Toggle
    local AutoSkillToggle = Tabs.Main:AddToggle("AutoPerfectSkill", {
        Title = "Auto Perfect Skill Check", 
        Description = "automatically clicks in the perfect location", 
        Default = false
    })

    AutoSkillToggle:OnChanged(function(v)
        SafeCallback(function()
            nexus.FunctionStates.autoSkillEnabled = v
            SafeCallback(function()
                if nexus.Connections.skillCheck then
                    nexus.Connections.skillCheck:Disconnect()
                end
            end)
            if v then 
                nexus.Connections.skillCheck = RunService.Heartbeat:Connect(PerformPerfectSkillCheck) 
            end
        end)
    end)
    
    -- Сохраняем функции в Nexus
    nexus.Functions.NoTurnLimit = NoTurnLimit
    nexus.Functions.AutoParry = AutoParry
    nexus.Functions.AutoParryV2 = AutoParryV2
    nexus.Functions.StartInstantHeal = StartInstantHeal
    nexus.Functions.StopInstantHeal = StopInstantHeal
    nexus.Functions.StartSilentHeal = StartSilentHeal
    nexus.Functions.StopSilentHeal = StopSilentHeal
    nexus.Functions.ResetAllHealing = ResetAllHealing
    nexus.Functions.GateTool = GateTool
    nexus.Functions.SimpleNoFall = SimpleNoFall
    
    return SurvivorModule
end

return SurvivorModule
