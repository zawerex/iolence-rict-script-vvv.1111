-- Killer.lua - Модуль для функций Killer
local Nexus = require(script.Parent.NexusMain)

local KillerModule = {}

function KillerModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    local player = nexus.Player
    local ReplicatedStorage = nexus.Services.ReplicatedStorage
    local RunService = nexus.Services.RunService
    local UserInputService = nexus.Services.UserInputService
    local Workspace = nexus.Services.Workspace
    
    -- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
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
    
    local function IsKiller()
        if not player.Team then return false end
        local teamName = player.Team.Name:lower()
        return teamName:find("killer") == 1 or teamName == "killer"
    end
    
    -- ========== OneHitKill ФУНКЦИЯ ==========
    local OneHitKill = (function()
        local enabled = false
        local mouseClickConnection = nil
        local basicAttackRemote = nil

        local function GetBasicAttackRemote()
            if not basicAttackRemote then
                SafeCallback(function()
                    basicAttackRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
                end)
                
                if not basicAttackRemote then
                    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("attack") or remote.Name:lower():find("basic")) then
                            basicAttackRemote = remote
                            break
                        end
                    end
                end
            end
            return basicAttackRemote
        end

        local function IsValidTarget(targetPlayer)
            if not targetPlayer or targetPlayer == player then return false end
            if not targetPlayer.Character then return false end
            
            if targetPlayer.Team then
                local teamName = targetPlayer.Team.Name:lower()
                if teamName:find("killer") then return false end
            end
            
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            
            return true
        end

        local function GetNearestTarget()
            if not IsKiller() then return nil end
            
            local character = player.Character
            if not character then return nil end
            
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return nil end
            
            local nearestTarget = nil
            local nearestDistance = 20
            
            for _, targetPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                if targetPlayer ~= player and IsValidTarget(targetPlayer) then
                    local targetCharacter = targetPlayer.Character
                    if targetCharacter then
                        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
                        
                        if targetRoot then
                            local currentDistance = (rootPart.Position - targetRoot.Position).Magnitude
                            
                            if currentDistance < nearestDistance then
                                nearestDistance = currentDistance
                                nearestTarget = targetRoot
                            end
                        end
                    end
                end
            end
            
            return nearestTarget
        end

        local function OnMouseClick(input, gameProcessed)
            if gameProcessed or not enabled then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not IsKiller() then
                    print("OneHitKill: Player is not in Killer team")
                    return
                end
                
                local target = GetNearestTarget()
                if target then
                    local attackRemote = GetBasicAttackRemote()
                    if attackRemote then
                        SafeCallback(function()
                            attackRemote:FireServer(target.Position)
                            print("OneHitKill activated on target at distance: " .. (target.Position - player.Character.HumanoidRootPart.Position).Magnitude)
                        end)
                    end
                end
            end
        end

        local function Enable()
            if enabled then return end
            enabled = true
            nexus.FunctionStates.OneHitKillEnabled = true
            
            mouseClickConnection = UserInputService.InputBegan:Connect(OnMouseClick)
            
            print("OneHitKill enabled")
        end

        local function Disable()
            if not enabled then return end
            enabled = false
            nexus.FunctionStates.OneHitKillEnabled = false
            
            if mouseClickConnection then
                mouseClickConnection:Disconnect()
                mouseClickConnection = nil
            end
            
            print("OneHitKill disabled")
        end

        return {
            Enable = Enable,
            Disable = Disable,
            IsEnabled = function() return enabled end
        }
    end)()
    
    -- ========== NoSlowdown ФУНКЦИЯ ==========
    local NoSlowdown = (function()
        local enabled = false
        local slowdownConnection = nil
        local originalSpeed = 16
        
        local function GetRole()
            if not player.Team then return "Survivor" end
            local teamName = player.Team.Name:lower()
            if teamName:find("killer") then 
                return "Killer" 
            end
            return "Survivor"
        end
        
        local function Enable()
            if enabled then return end
            enabled = true
            nexus.FunctionStates.NoSlowdownEnabled = true
            print("NoSlowdown Enabled (Killer Only)")
            
            local character = getCharacter()
            local humanoid = getHumanoid()
            if humanoid then
                originalSpeed = humanoid.WalkSpeed
            end
            
            slowdownConnection = RunService.Heartbeat:Connect(function()
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
                
                local char = getCharacter()
                if not char then return end
                
                local hum = getHumanoid()
                if not hum then return end
                
                if hum.WalkSpeed < 16 then
                    hum.WalkSpeed = originalSpeed or 16
                end
            end)
            
            player.CharacterAdded:Connect(function(newChar)
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
            nexus.FunctionStates.NoSlowdownEnabled = false
            
            if slowdownConnection then
                SafeCallback(function() slowdownConnection:Disconnect() end)
                slowdownConnection = nil
            end
            
            local humanoid = getHumanoid()
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
    
    -- ========== AntiBlind ФУНКЦИЯ ==========
    local AntiBlind = (function()
        local isAntiBlindEnabled = false
        local originalFireServer = nil
        local originalOnClientEvent = nil
        local hookedRemotes = {}

        local function findFlashlightRemote()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
                    print("", self.Name)
                    return nil
                end
                return originalFireServer(self, ...)
            end
            
            if remote:IsA("RemoteEvent") then
                remote.OnClientEvent = function(self, ...)
                    if isAntiBlindEnabled then
                        print("", self.Name)
                        return nil
                    end
                    return originalOnClientEvent(self, ...)
                end
            end
            
            hookedRemotes[remote] = true
            print("", remote:GetFullName())
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
            
            local success = SafeCallback(function()
                local gameMetaTable = getrawmetatable(game)
                if not gameMetaTable then return false end
                
                local originalNamecall = gameMetaTable.__namecall
                
                setreadonly(gameMetaTable, false)
                
                gameMetaTable.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    
                    if isAntiBlindEnabled and method == "FireServer" then
                        local remoteName = tostring(self)
                        if remoteName:lower():find("blind") or remoteName:lower():find("flash") then
                            print("", remoteName)
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
            nexus.FunctionStates.KillerAntiBlindEnabled = true
            
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
        end

        local function Disable()
            if not isAntiBlindEnabled then return end
            isAntiBlindEnabled = false
            nexus.FunctionStates.KillerAntiBlindEnabled = false
            
            print("AntiBlind: Disabled")
            restoreHooks()
        end

        task.spawn(function()
            task.wait(3)
            SafeCallback(setupAntiBlind)
            SafeCallback(setupMetaTableHook)
        end)

        return {
            Enable = Enable,
            Disable = Disable,
            IsEnabled = function() return isAntiBlindEnabled end
        }
    end)()
    
    -- ========== PALET DESTRUCTION ==========
    local palletsDestroyed = false

    local function DestroyAllPallets()
        if palletsDestroyed then
            return
        end
        
        local DestroyGlobal = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Destroy-Global")
        
        local savedPosition = nil
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            savedPosition = character.HumanoidRootPart.CFrame
        end
        
        palletsDestroyed = true
        
        for _, obj in ipairs(workspace:GetDescendants()) do
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
    
    -- ========== GENERATOR BREAK ==========
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

    local function FindNearestGenerator(maxDistance)
        local character = player.Character
        if not character then return nil end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return nil end
        
        local playerPosition = humanoidRootPart.Position
        local nearestGenerator = nil
        local nearestDistance = math.huge
        
        for _, obj in ipairs(workspace:GetDescendants()) do
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
        
        local BreakGenEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
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
        if not player.Character then return end
        
        local nearestGenerator = FindNearestGenerator(10)
        if not nearestGenerator then return end
        
        spamInProgress = true
        local spamCount = 0
        
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not spamInProgress then
                if connection then connection:Disconnect() end
                return
            end
            
            if not IsKiller() or not player.Character then
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
                local BreakGenEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
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
        stopConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
                if spamInProgress then
                    spamInProgress = false
                    if connection then connection:Disconnect() end
                    if stopConnection then stopConnection:Disconnect() end
                end
            end
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            if nexus.FunctionStates.BreakGeneratorEnabled then
                SpamGeneratorBreak()
            end
        end
    end)
    
    -- ========== MASK POWERS ==========
    local function activateMaskPower(maskName)
        local success, result = SafeCallback(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            local killers = remotes:WaitForChild("Killers")
            local masked = killers:WaitForChild("Masked")
            local activatePower = masked:WaitForChild("Activatepower")
            
            if not player.Team or player.Team.Name ~= "Killer" then
                return false
            end
            
            activatePower:FireServer(maskName)
            return true
        end)
        
        return success and result
    end
    
    -- ========== ABYSSWALKER CORRUPT ==========
    local AbysswalkerCorrupt = (function()
        local CorruptRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Abysswalker"):WaitForChild("corrupt")
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

        player.CharacterAdded:Connect(function(character)
            task.wait(2) 
        end)
        
        return {
            Activate = fireCorruptEvent,
            IsReady = function() return canActivate end
        }
    end)()
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    -- OneHitKill Toggle (только для десктопа)
    if nexus.IS_DESKTOP then
        local OneHitKillToggle = Tabs.Killer:AddToggle("OneHitKill", {
            Title = "OneHitKill", 
            Description = "Attack nearby players with one click (Killer only)", 
            Default = false
        })

        OneHitKillToggle:OnChanged(function(v)
            SafeCallback(function()
                if v then 
                    OneHitKill.Enable() 
                else 
                    OneHitKill.Disable() 
                end
            end)
        end)
    end

    -- Abysswalker Corrupt Keybind
    local AbysswalkerCorruptKeybind = Tabs.Killer:AddKeybind("AbysswalkerCorruptKeybind", {
        Title = "Abysswalker Corrupt [NO COOLDOWN]",
        Description = "Activate Abysswalker corrupt ability",
        Default = "",
        Callback = function()
            SafeCallback(function()
                AbysswalkerCorrupt.Activate()
            end)
        end,
        ChangedCallback = function(newKey)
            -- Можно добавить логику для изменения клавиши
        end
    })

    -- Destroy Pallets Toggle
    local DestroyPalletsToggle = Tabs.Killer:AddToggle("DestroyPallets", {
        Title = "Destroy Pallets", 
        Description = "smash all the pallets on the map", 
        Default = false
    })

    DestroyPalletsToggle:OnChanged(function(v)
        SafeCallback(function()
            nexus.FunctionStates.DestroyPalletsEnabled = v
        end)
    end)

    -- No Slowdown Toggle
    local NoSlowdownToggle = Tabs.Killer:AddToggle("NoSlowdown", {
        Title = "No Slowdown", 
        Description = "Prevents slowdown when attacking", 
        Default = false
    })

    NoSlowdownToggle:OnChanged(function(v)
        SafeCallback(function()
            if v then 
                NoSlowdown.Enable() 
            else 
                NoSlowdown.Disable() 
            end
        end)
    end)

    -- Break Generator Toggle
    local BreakGeneratorToggle = Tabs.Killer:AddToggle("BreakGenerator", {
        Title = "FullGeneratorBreak", 
        Description = "complete generator failure", 
        Default = false
    })

    BreakGeneratorToggle:OnChanged(function(v)
        SafeCallback(function()
            nexus.FunctionStates.BreakGeneratorEnabled = v
        end)
    end)

    -- Anti Blind Toggle
    local AntiBlindToggle = Tabs.Killer:AddToggle("AntiBlind", {
        Title = "Anti Blind", 
        Description = "prevents you from being blinded by a flashlight", 
        Default = false
    })

    AntiBlindToggle:OnChanged(function(v)
        SafeCallback(function()
            if v then 
                AntiBlind.Enable() 
            else 
                AntiBlind.Disable() 
            end
        end)
    end)

    -- Mask Powers Dropdown
    local MaskPowers = Tabs.Killer:AddDropdown("MaskPowers", {
        Title = "Mask Powers",
        Description = "Select mask power to activate immediately",
        Values = {"Alex", "Tony", "Brandon", "Jake", "Richter", "Graham", "Richard"},
        Multi = false,
        Default = ""
    })

    MaskPowers:OnChanged(function(value)
        SafeCallback(function()
            if value and value ~= "" then
                activateMaskPower(value)
            end
        end)
    end)

    -- Information Paragraph
    Tabs.Killer:AddParagraph({
        Title = "Mask Powers Information",
        Content = "Alex - Chainsaw\nTony - Fists\nBrandon - Speed\nJake - Long lunge\nRichter - Stealth\nGraham - Faster vaults\nRichard - Default mask"
    })
    
    -- Сохраняем функции в Nexus
    nexus.Functions.OneHitKill = OneHitKill
    nexus.Functions.NoSlowdown = NoSlowdown
    nexus.Functions.AntiBlind = AntiBlind
    nexus.Functions.DestroyAllPallets = DestroyAllPallets
    nexus.Functions.FullGeneratorBreak = FullGeneratorBreak
    nexus.Functions.AbysswalkerCorrupt = AbysswalkerCorrupt
    
    return KillerModule
end

return KillerModule
