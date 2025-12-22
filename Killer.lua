-- Killer Module - Killer functions for Violence District
local Nexus = _G.Nexus

local Killer = {
    Connections = {},
    States = {},
    Objects = {}
}

-- ========== ONE HIT KILL ==========

local LastDoubleTapTime = 0

local function DoubleTap()
    if not Nexus.States.OneHitKillEnabled then return end
    if not Nexus.Player.Team or not Nexus.Player.Team.Name:lower():find("killer") then return end
    if tick() - LastDoubleTapTime < 0.5 then return end
    
    pcall(function()
        local remotes = Nexus.Services.ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks")
        if not attacks then return end
        local basicAttack = attacks:FindFirstChild("BasicAttack")
        if basicAttack then
            basicAttack:FireServer(false)
            task.wait(0.01)
            basicAttack:FireServer(false)
            LastDoubleTapTime = tick()
        end
    end)
end

local OneHitKill = (function()
    local function Enable()
        Nexus.States.OneHitKillEnabled = true
        
        Killer.Connections.OneHitKill = Nexus.Services.RunService.Heartbeat:Connect(function()
            if Nexus.States.OneHitKillEnabled then
                DoubleTap()
            end
        end)
    end

    local function Disable()
        Nexus.States.OneHitKillEnabled = false
        
        if Killer.Connections.OneHitKill then
            Killer.Connections.OneHitKill:Disconnect()
            Killer.Connections.OneHitKill = nil
        end
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return Nexus.States.OneHitKillEnabled end
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
    local originalSpeed = 16

    local function GetRole()
        if not Nexus.Player.Team then return "Survivor" end
        local teamName = Nexus.Player.Team.Name:lower()
        if teamName:find("killer") then 
            return "Killer" 
        end
        return "Survivor"
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoSlowdownEnabled = true

        local character = Nexus.getCharacter()
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            originalSpeed = humanoid.WalkSpeed
        end
        
        slowdownConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not enabled then 
                if slowdownConnection then
                    slowdownConnection:Disconnect()
                    slowdownConnection = nil
                end
                return 
            end
            
            if GetRole() ~= "Killer" then 
                return 
            end
            
            local char = Nexus.getCharacter()
            if not char then return end
            
            local hum = Nexus.getHumanoid()
            if not hum then return end
            
            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = originalSpeed or 16
            end
        end)
        
        Nexus.Player.CharacterAdded:Connect(function(newChar)
            if enabled then
                task.wait(1)
                local newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
                if newHumanoid then
                    originalSpeed = newHumanoid.WalkSpeed
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
        
        local humanoid = Nexus.getHumanoid()
        if humanoid and originalSpeed then
            humanoid.WalkSpeed = originalSpeed
        end
        
        print("NoSlowdown Disabled")
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
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
    
    -- ========== ONE HIT KILL ==========
    if Nexus.IS_DESKTOP then
        local OneHitKillToggle = Tabs.Killer:AddToggle("OneHitKill", {
            Title = "OneHitKill", 
            Description = "Attack nearby players with one click (Killer only)", 
            Default = false
        })

        OneHitKillToggle:OnChanged(function(v)
            Nexus.SafeCallback(function()
                if v then 
                    OneHitKill.Enable() 
                else 
                    OneHitKill.Disable() 
                end
            end)
        end)
    end

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
    OneHitKill.Disable()
    NoSlowdown.Disable()
    AntiBlind.Disable()
    
    -- Очищаем все соединения
    for key, connection in pairs(Killer.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Killer.Connections = {}
    
    print("Killer module cleaned up")
end

return Killer
