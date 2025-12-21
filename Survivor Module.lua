-- Survivor Module - Survivor functions for Violence District
local Nexus = _G.Nexus

local Survivor = {
    Connections = {},
    States = {}
}

-- ========== NO TURN LIMIT ==========

local NoTurnLimit = (function()
    local enabled = false
    local turnLimitConnection = nil
    
    local function IsSurvivor()
        if not Nexus.Player.Team then return false end
        local teamName = Nexus.Player.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoTurnLimitEnabled = true
        print("NoTurnLimit Enabled")
        
        turnLimitConnection = Nexus.Services.RunService.RenderStepped:Connect(function()
            if not enabled or not IsSurvivor() then return end
            
            local character = Nexus.getCharacter()
            if not character then return end
            
            local humanoid = Nexus.getHumanoid()
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
        Nexus.States.NoTurnLimitEnabled = false
        
        if turnLimitConnection then
            Nexus.safeDisconnect(turnLimitConnection)
            turnLimitConnection = nil
        end
        
        print("NoTurnLimit Disabled")
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== AUTO PARRY ==========

local AutoParry = (function()
    local spamActive = false
    local RANGE = 10
    local lastCheck = 0
    local CHECK_INTERVAL = 0.01

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
                    spamActive = true
                    Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.spawn(function()
                        task.wait(0.01)
                        Nexus.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    end)
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

-- ========== AUTO PARRY V2 ==========

local AutoParryV2 = (function()
    local isParryOnCooldown = false
    local animationConnections, customBar, fillBar, timeText = {}, nil, nil, nil
    local PARRY_COOLDOWN = 40.264
    local RANGE = 10
    local hideBarsConnection = nil

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

    local function IsPlayerKiller(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return false end
        if targetPlayer.Team then return targetPlayer.Team.Name:lower() == "killer" end
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        return humanoid and humanoid.DisplayName:lower() == "killer"
    end

    local function IsPlayerInRange(targetPlayer, maxDistance)
        local localRoot = Nexus.getRootPart()
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
        pcall(function()
            local playerGui = Nexus.Player:WaitForChild("PlayerGui")
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
                            end
                            if originalBack then 
                                originalBack.Visible = false 
                            end
                        end
                    end
                end
            end
        end)
    end

    local function ShowOriginalBars()
        pcall(function()
            local playerGui = Nexus.Player:WaitForChild("PlayerGui")
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
        
        hideBarsConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not Nexus.States.AutoParryV2Enabled then
                if hideBarsConnection then
                    hideBarsConnection:Disconnect()
                    hideBarsConnection = nil
                end
                return
            end
            
            pcall(function()
                local playerGui = Nexus.Player:WaitForChild("PlayerGui")
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
            pcall(function() customBar.Gui:Destroy() end) 
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CustomParryBar"
        screenGui.Parent = Nexus.Player:WaitForChild("PlayerGui")
        screenGui.ResetOnSpawn = false
        
        local mainContainer = Instance.new("Frame")
        mainContainer.Name = "MainContainer"
        mainContainer.Size = UDim2.new(0, 40, 0, 150)
        mainContainer.Position = UDim2.new(0, 10, 1, -317)
        mainContainer.BackgroundTransparency = 1
        mainContainer.Visible = Nexus.States.AutoParryV2Enabled
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
            Nexus.safeDisconnect(connection) 
        end
        animationConnections = {}
    end

    local function Enable()
        if Nexus.States.AutoParryV2Enabled then return end
        Nexus.States.AutoParryV2Enabled = true
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
                            pcall(function()
                                Nexus.Services.ReplicatedStorage.Remotes.Items["Parrying Dagger"].parry:FireServer()
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
                    Nexus.safeDisconnect(animationConnections[targetPlayer])
                    animationConnections[targetPlayer] = nil 
                end
            end)
        end
        
        for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do 
            if targetPlayer ~= Nexus.Player then 
                setupPlayerTracking(targetPlayer) 
            end 
        end
        
        Nexus.Services.Players.PlayerAdded:Connect(function(targetPlayer) 
            if targetPlayer ~= Nexus.Player then 
                setupPlayerTracking(targetPlayer) 
            end 
        end)
    end

    local function Disable()
        if not Nexus.States.AutoParryV2Enabled then return end
        Nexus.States.AutoParryV2Enabled = false
        
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
        Nexus.Player:WaitForChild("PlayerGui")
        CreateCustomBar()
    end)

    Nexus.Player.CharacterRemoving:Connect(function()
        if Nexus.States.AutoParryV2Enabled then
            if customBar and customBar.Container then 
                customBar.Container.Visible = false 
            end
        end
    end)

    Nexus.Player.CharacterAdded:Connect(function()
        if Nexus.States.AutoParryV2Enabled then
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
        IsEnabled = function() return Nexus.States.AutoParryV2Enabled end,
        SetRange = function(value) 
            RANGE = tonumber(value) or 10
            
            if Nexus.States.AutoParryV2Enabled then
                Disable()
                task.wait(0.1)
                Enable()
            end
            print("AutoParryV2 range set to: " .. RANGE)
        end,
        GetRange = function() return RANGE end
    }
end)()

-- ========== HEALING FUNCTIONS ==========

local StopEmote = function() end
local SendStopHealEvent = function() end

local healingStates = {
    silentHealRunning = false,
    instantHealRunning = false,
    lastHealTime = 0,
    healCooldown = 0.2
}

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

local function StartInstantHeal()
    Nexus.States.InstantHealRunning = true
    
    local function IsSurvivor(targetPlayer)
        if not targetPlayer or not targetPlayer.Team then return false end
        
        local teamName = targetPlayer.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end
    
    Survivor.Connections.instantHeal = task.spawn(function()
        while Nexus.States.InstantHealRunning do
            local char = Nexus.getCharacter()
            if char and Nexus.getRootPart() then
                for _, target in ipairs(Nexus.Services.Players:GetPlayers()) do
                    if target ~= Nexus.Player then
                        if not IsSurvivor(target) then
                            continue 
                        end
                        if target.Character then
                            local targetChar, humanoid = target.Character, target.Character:FindFirstChild("Humanoid")
                            if humanoid and humanoid.Health < humanoid.MaxHealth then
                                pcall(function() 
                                    if Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                        Nexus.Services.ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer("success", 1, targetChar) 
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
    Nexus.States.InstantHealRunning = false
    Nexus.safeDisconnect(Survivor.Connections.instantHeal)
end

local function StartSilentHeal()
    if healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = true
    Nexus.States.SilentHealRunning = true
    local currentValue = true
    
    local function IsSurvivor(targetPlayer)
        if not targetPlayer or not targetPlayer.Team then return false end
        
        local teamName = targetPlayer.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end
    
    Survivor.Connections.silentHeal = task.spawn(function()
        while healingStates.silentHealRunning do
            local character = Nexus.getCharacter()
            if not character or not Nexus.getRootPart() then
                task.wait(0.4)
                continue
            end
            
            local humanoid = Nexus.getHumanoid()
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
            
            for _, targetPlayer in ipairs(Nexus.Services.Players:GetPlayers()) do
                if targetPlayer == Nexus.Player then continue end
                
                if not IsSurvivor(targetPlayer) then
                    continue
                end
                
                if targetPlayer and targetPlayer.Character then
                    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetHumanoid and targetRoot and targetHumanoid.Health < targetHumanoid.MaxHealth then
                        needsHealing = true
                        playersHealed = playersHealed + 1
                        
                        if playersHealed <= 3 then
                            local args = {targetRoot, currentValue}
                            pcall(function() 
                                if Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                    Nexus.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                    healingStates.lastHealTime = tick()
                                    print("Healing Survivor: " .. targetPlayer.Name)
                                end
                            end)
                        end
                    else
                        local args = {targetRoot, false}
                        pcall(function() 
                            if Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Healing then
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
            
            task.wait(0.1)
        end
        
        pcall(SendStopHealEvent)
    end)
end

local function StopSilentHeal()
    if not healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = false
    Nexus.States.SilentHealRunning = false
    
    task.wait(0.1)
    
    if Survivor.Connections.silentHeal then
        Nexus.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
    end
    
    for i = 1, 2 do
        pcall(SendStopHealEvent)
        task.wait(0.05)
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
        local gateRemote = Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Items and Nexus.Services.ReplicatedStorage.Remotes.Items.Gate and Nexus.Services.ReplicatedStorage.Remotes.Items.Gate.gate
        if gateRemote then 
            pcall(function() 
                gateRemote:FireServer() 
            end)
            return true 
        end
        return false
    end

    local function Enable()
        if Nexus.States.GateToolEnabled then return end
        Nexus.States.GateToolEnabled = true
        
        toolInstance = CreateTool()
        if toolInstance then 
            toolConnection = toolInstance.Activated:Connect(function()
                Nexus.SafeCallback(UseGate)
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
            Nexus.SafeCallback(Enable)
        end 
    end)

    return {Enable=Enable, Disable=Disable}
end)()

-- ========== NO FALL ==========

local SimpleNoFall = (function()
    local enabled = false
    local remote = nil
    local originalFireServer = nil
    local loopConnection = nil

    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoFallEnabled = true
        
        task.spawn(function()
            remote = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
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
        Nexus.States.NoFallEnabled = false
        
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
        Content = "Enjoy using it ♡"
    })

    -- ========== NO TURN LIMIT ==========
    local NoTurnLimitToggle = Tabs.Main:AddToggle("NoTurnLimit", {
        Title = "No slowing down", 
        Description = "No slowing down in speed", 
        Default = false
    })

    NoTurnLimitToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                NoTurnLimit.Enable() 
            else 
                NoTurnLimit.Disable() 
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

    -- ========== AUTO PARRY V2 ==========
    local AutoParryV2Toggle = Tabs.Main:AddToggle("AutoParryV2", {
        Title = "AutoParry (Anti-Stun)", 
        Description = "automatic parry of attacks without delay", 
        Default = false
    })

    AutoParryV2Toggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                AutoParryV2.Enable() 
            else 
                AutoParryV2.Disable() 
            end 
        end)
    end)

    local AutoParryV2RangeSlider = Tabs.Main:AddSlider("AutoParryV2Range", {
        Title = "ping compensation",
        Description = "",
        Default = 10,
        Min = 0,
        Max = 20,
        Rounding = 2,
        Callback = function(value)
            Nexus.SafeCallback(function()
                AutoParryV2.SetRange(value)
            end)
        end
    })

    -- ========== HEAL ==========
    local HealToggle = Tabs.Main:AddToggle("Heal", {
        Title = "Heal", 
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
        Title = "Gate Tool", 
        Description = "", 
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

    -- ========== ANTI-FAIL GENERATOR ==========
    local AntiFailToggle = Tabs.Main:AddToggle("AntiFailGenerator", {
        Title = "Anti-Fail Generator", 
        Description = "", 
        Default = false
    })

    AntiFailToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Nexus.States.antiFailEnabled = v
            if v then
                DisableGeneratorFail()
                Nexus.Player.CharacterAdded:Connect(function(char) 
                    task.wait(1); 
                    if Nexus.States.antiFailEnabled then 
                        DisableGeneratorFail() 
                    end 
                end)
                Survivor.Connections.antiFail = Nexus.Services.RunService.Heartbeat:Connect(function() 
                    if Nexus.States.antiFailEnabled then 
                        DisableGeneratorFail() 
                    end 
                end)
            else
                Nexus.safeDisconnect(Survivor.Connections.antiFail)
            end
        end)
    end)

    -- ========== NO FALL ==========
    local NoFallToggle = Tabs.Main:AddToggle("NoFall", {
        Title = "NoFall", 
        Description = "", 
        Default = false
    })

    NoFallToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                SimpleNoFall.Enable() 
                Nexus.States.NoFallEnabled = true
            else 
                SimpleNoFall.Disable() 
                Nexus.States.NoFallEnabled = false
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

    print("✓ Survivor module initialized")
end

-- ========== CLEANUP ==========

function Survivor.Cleanup()
    -- Отключаем все функции
    NoTurnLimit.Disable()
    AutoParry.Disable()
    AutoParryV2.Disable()
    ResetAllHealing()
    GateTool.Disable()
    SimpleNoFall.Disable()
    
    -- Очищаем все соединения
    for key, connection in pairs(Survivor.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Survivor.Connections = {}
    
    print("Survivor module cleaned up")
end

return Survivor
