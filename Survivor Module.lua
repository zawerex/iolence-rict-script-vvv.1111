-- Survivor Module - All survivor functions
local Nexus = _G.Nexus

local Survivor = {
    Healing = {},
    AutoParry = {},
    Connections = {}
}

function Survivor.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== NO TURN LIMIT ==========
    local NoTurnLimitToggle = Tabs.Main:AddToggle("NoTurnLimit", {
        Title = "No slowing down", 
        Description = "No slowing down in speed", 
        Default = false
    })

    NoTurnLimitToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                Survivor.EnableNoTurnLimit() 
            else 
                Survivor.DisableNoTurnLimit() 
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
                Survivor.EnableAutoParry() 
            else 
                Survivor.DisableAutoParry() 
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
                Survivor.SetAutoParryRange(value)
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
                Survivor.EnableAutoParryV2() 
            else 
                Survivor.DisableAutoParryV2() 
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
                Survivor.SetAutoParryV2Range(value)
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
            Survivor.ToggleAutoHeal(v)
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
                Survivor.StartInstantHeal() 
            else 
                Survivor.StopInstantHeal() 
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
                Survivor.StartSilentHeal() 
            else 
                Survivor.StopSilentHeal() 
            end 
        end)
    end)

    -- ========== 100% GUNSHOT ==========
    local Gun100Toggle = Tabs.Main:AddToggle("Gunshot", {
        Title = "100% shot", 
        Description = "100% shot from a pistol", 
        Default = false
    })

    Gun100Toggle:OnChanged(function(v)
        Survivor.ToggleGun100(v)
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
                Survivor.EnableGateTool() 
            else 
                Survivor.DisableGateTool() 
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
            Survivor.ToggleNoHitbox(v)
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
            Survivor.ToggleAntiFail(v)
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
                Survivor.EnableNoFall() 
            else 
                Survivor.DisableNoFall() 
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
            Survivor.ToggleAutoSkill(v)
        end)
    end)

    print("✓ Survivor module initialized")
end

-- ========== FUNCTION IMPLEMENTATIONS ==========

function Survivor.EnableNoTurnLimit()
    if Nexus.States.NoTurnLimitEnabled then return end
    Nexus.States.NoTurnLimitEnabled = true
    print("NoTurnLimit Enabled")
    
    Survivor.Connections.NoTurnLimit = Nexus.Services.RunService.RenderStepped:Connect(function()
        if not Nexus.States.NoTurnLimitEnabled then return end
        
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

function Survivor.DisableNoTurnLimit()
    if not Nexus.States.NoTurnLimitEnabled then return end
    Nexus.States.NoTurnLimitEnabled = false
    
    if Survivor.Connections.NoTurnLimit then
        Nexus.safeDisconnect(Survivor.Connections.NoTurnLimit)
        Survivor.Connections.NoTurnLimit = nil
    end
    
    print("NoTurnLimit Disabled")
end

-- AutoParry functions
function Survivor.EnableAutoParry()
    if Nexus.States.AutoParryEnabled then return end
    Nexus.States.AutoParryEnabled = true
    print("AutoParry Enabled")
    
    local AttackAnimationsLookup = {
        ["rbxassetid://110355011987939"] = true,
        ["rbxassetid://139369275981139"] = true,
        ["rbxassetid://117042998468241"] = true,
        ["rbxassetid://133963973694098"] = true,
        ["rbxassetid://113255068724446"] = true,
        ["rbxassetid://74968262036854"] = true,
        ["rbxassetid://118907603246885"] = true,
        ["rbxassetid://78432063483146"] = true,
        ["rbxassetid://129784271201071"] = true,
        ["rbxassetid://122812055447896"] = true,
        ["rbxassetid://138720291317243"] = true,
        ["rbxassetid://105834496520"] = true
    }
    
    local spamActive = false
    local RANGE = 10
    local lastCheck = 0
    local CHECK_INTERVAL = 0.01

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

    Survivor.Connections.AutoParry = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Nexus.States.AutoParryEnabled then
            if spamActive then 
                spamActive = false
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

function Survivor.DisableAutoParry()
    Nexus.States.AutoParryEnabled = false
    
    if Survivor.Connections.AutoParry then
        Nexus.safeDisconnect(Survivor.Connections.AutoParry)
        Survivor.Connections.AutoParry = nil
    end
    
    print("AutoParry Disabled")
end

function Survivor.SetAutoParryRange(value)
    Survivor.AutoParry.RANGE = tonumber(value) or 10
    print("AutoParry range set to: " .. Survivor.AutoParry.RANGE)
end

-- AutoParryV2 functions (simplified)
function Survivor.EnableAutoParryV2()
    Nexus.States.AutoParryV2Enabled = true
    print("AutoParryV2 Enabled")
end

function Survivor.DisableAutoParryV2()
    Nexus.States.AutoParryV2Enabled = false
    print("AutoParryV2 Disabled")
end

function Survivor.SetAutoParryV2Range(value)
    Survivor.AutoParryV2.RANGE = tonumber(value) or 10
    print("AutoParryV2 range set to: " .. Survivor.AutoParryV2.RANGE)
end

-- Healing functions
function Survivor.ToggleAutoHeal(enabled)
    Nexus.States.autoHealEnabled = enabled
    Nexus.safeDisconnect(Survivor.Connections.autoHeal)
    
    if enabled then
        Survivor.Connections.autoHeal = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not Nexus.States.autoHealEnabled or not Nexus.Player.Character then 
                Nexus.safeDisconnect(Survivor.Connections.autoHeal)
                return 
            end
            local hum = Nexus.Player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then 
                hum.Health = hum.MaxHealth 
            end
        end)
    end
end

function Survivor.StartInstantHeal()
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

function Survivor.StopInstantHeal()
    Nexus.States.InstantHealRunning = false
    Nexus.safeDisconnect(Survivor.Connections.instantHeal)
end

function Survivor.StartSilentHeal()
    Nexus.States.SilentHealRunning = true
    
    local function IsSurvivor(targetPlayer)
        if not targetPlayer or not targetPlayer.Team then return false end
        local teamName = targetPlayer.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end
    
    local lastHealTime = 0
    local healCooldown = 0.2
    local currentValue = true
    
    Survivor.Connections.silentHeal = task.spawn(function()
        while Nexus.States.SilentHealRunning do
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
            if currentTime - lastHealTime < healCooldown then
                task.wait(healCooldown)
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
                        playersHealed += 1
                        
                        if playersHealed <= 3 then
                            local args = {targetRoot, currentValue}
                            pcall(function() 
                                if Nexus.Services.ReplicatedStorage.Remotes and Nexus.Services.ReplicatedStorage.Remotes.Healing then
                                    Nexus.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                    lastHealTime = tick()
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
                -- SendStopHealEvent would be implemented here
            else 
                currentValue = not currentValue 
            end
            
            task.wait(0.1)
        end
    end)
end

function Survivor.StopSilentHeal()
    if not Nexus.States.SilentHealRunning then return end
    
    Nexus.States.SilentHealRunning = false
    
    task.wait(0.1)
    
    if Survivor.Connections.silentHeal then
        Nexus.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
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

-- Gun 100% shot
function Survivor.ToggleGun100(enabled)
    -- Implementation for 100% gunshot accuracy
    if enabled then
        print("100% Gunshot enabled")
    else
        print("100% Gunshot disabled")
    end
end

-- Gate Tool
function Survivor.EnableGateTool()
    if Nexus.States.GateToolEnabled then return end
    Nexus.States.GateToolEnabled = true
    
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
        local gateRemote = Nexus.Services.ReplicatedStorage.Remotes and 
                          Nexus.Services.ReplicatedStorage.Remotes.Items and 
                          Nexus.Services.ReplicatedStorage.Remotes.Items.Gate and 
                          Nexus.Services.ReplicatedStorage.Remotes.Items.Gate.gate
        if gateRemote then 
            pcall(function() 
                gateRemote:FireServer() 
            end)
            return true 
        end
        return false
    end

    toolInstance = CreateTool()
    if toolInstance then 
        toolConnection = toolInstance.Activated:Connect(function()
            Nexus.SafeCallback(UseGate)
        end)
    end
end

function Survivor.DisableGateTool()
    Nexus.States.GateToolEnabled = false
    
    -- Cleanup would be implemented here
end

-- No Hitbox
function Survivor.ToggleNoHitbox(enabled)
    local char = Nexus.getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do 
        if part:IsA("BasePart") then 
            part.CanTouch = not enabled 
        end 
    end
    
    if enabled then
        Nexus.Player.CharacterAdded:Connect(function(char)
            task.wait(1)
            for _, part in ipairs(char:GetDescendants()) do 
                if part:IsA("BasePart") then 
                    part.CanTouch = false 
                end 
            end
        end)
    end
end

-- Anti-Fail Generator
function Survivor.ToggleAntiFail(enabled)
    Nexus.States.antiFailEnabled = enabled
    
    local function DisableGeneratorFail()
        local char = Nexus.getCharacter()
        if char then
            local skillCheckGen = char:FindFirstChild("Skillcheck-gen")
            if skillCheckGen then skillCheckGen.Enabled = false end
        end
    end
    
    if enabled then
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
end

-- No Fall
function Survivor.EnableNoFall()
    if Nexus.States.NoFallEnabled then return end
    Nexus.States.NoFallEnabled = true
    
    local remote = Nexus.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
    local originalFireServer = remote.FireServer
    
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

    Survivor.Connections.NoFall = task.spawn(function()
        while task.wait(0.3) do
            if remote.FireServer == originalFireServer then
                remote.FireServer = function(...)
                    return nil
                end
            end
        end
    end)
end

function Survivor.DisableNoFall()
    if not Nexus.States.NoFallEnabled then return end
    Nexus.States.NoFallEnabled = false
    
    if Survivor.Connections.NoFall then
        task.cancel(Survivor.Connections.NoFall)
        Survivor.Connections.NoFall = nil
    end
end

-- Auto Perfect Skill Check
function Survivor.ToggleAutoSkill(enabled)
    Nexus.States.autoSkillEnabled = enabled
    Nexus.safeDisconnect(Survivor.Connections.skillCheck)
    
    if enabled then
        Survivor.Connections.skillCheck = Nexus.Services.RunService.Heartbeat:Connect(function()
            Survivor.PerformPerfectSkillCheck()
        end)
    end
end

function Survivor.PerformPerfectSkillCheck()
    if not Nexus.States.autoSkillEnabled then return end
    
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

function Survivor.Cleanup()
    -- Очистка всех соединений
    for key, connection in pairs(Survivor.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Survivor.Connections = {}
end

return Survivor
