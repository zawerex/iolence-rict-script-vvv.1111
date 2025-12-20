-- Movement Module - All movement functions
local Nexus = _G.Nexus

local Movement = {
    Connections = {},
    InfiniteLunge = {
        enabled = false,
        speed = 50,
        isLunging = false,
        connection = nil
    },
    WalkSpeed = {
        enabled = false,
        speed = 16,
        connection = nil
    },
    NoClip = {
        enabled = false,
        connection = nil,
        originalCollisions = {}
    },
    Fly = {
        enabled = false,
        speed = 50,
        bodyVelocity = nil,
        bodyGyro = nil,
        connection = nil
    },
    FreeCamera = {
        enabled = false,
        speed = 50,
        connection = nil,
        originalCameraType = nil,
        originalCameraSubject = nil,
        mouseLocked = false
    },
    FOV = {
        enabled = false,
        value = 95,
        targetValue = 95,
        currentTween = nil,
        tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    }
}

function Movement.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- ========== TELEPORT BUTTONS ==========
    Tabs.Movement:AddButton({
        Title = "Teleport to Random Generator", 
        Description = "Teleport to a random generator on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.TeleportToRandomGenerator)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Hook", 
        Description = "Teleport to a random hook on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.TeleportToRandomHook)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Player", 
        Description = "Teleport to a random player on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.TeleportToRandomPlayer)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Generator", 
        Description = "Teleport to the closest generator",
        Callback = function()
            Nexus.SafeCallback(Movement.TeleportToNearestGenerator)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Player", 
        Description = "Teleport to the closest player",
        Callback = function()
            Nexus.SafeCallback(Movement.TeleportToNearestPlayer)
        end
    })

    -- ========== INFINITE LUNGE ==========
    if Nexus.IS_DESKTOP then
        local InfiniteLungeToggle = Tabs.Movement:AddToggle("InfiniteLunge", {
            Title = "Infinite Lunge", 
            Description = "Hold LMB to lunge forward", 
            Default = false
        })

        InfiniteLungeToggle:OnChanged(function(v) 
            Nexus.SafeCallback(function()
                if v then 
                    Movement.EnableInfiniteLunge() 
                else 
                    Movement.DisableInfiniteLunge() 
                end 
            end)
        end)

        local LungeSpeedSlider = Tabs.Movement:AddSlider("LungeSpeed", {
            Title = "Lunge Speed", 
            Description = "", 
            Default = 50, 
            Min = 10, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                Nexus.SafeCallback(function()
                    Movement.SetLungeSpeed(value)
                end)
            end
        })
    end

    -- ========== WALK SPEED ==========
    local WalkSpeedToggle = Tabs.Movement:AddToggle("WalkSpeed", {
        Title = "Walk Speed", 
        Description = "", 
        Default = false
    })

    WalkSpeedToggle:OnChanged(function(v) 
        Nexus.SafeCallback(function()
            if v then 
                Movement.EnableWalkSpeed() 
            else 
                Movement.DisableWalkSpeed() 
            end 
        end)
    end)

    local WalkSpeedSlider = Tabs.Movement:AddSlider("WalkSpeedValue", {
        Title = "Walk Speed Value", 
        Description = "0-200", 
        Default = 16, 
        Min = 0, 
        Max = 200, 
        Rounding = 0, 
        Callback = function(value) 
            Nexus.SafeCallback(function()
                Movement.SetWalkSpeed(value)
            end)
        end
    })

    -- ========== NOCLIP ==========
    local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
        Title = "Noclip",
        Description = "",
        Default = false
    })

    NoclipToggle:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value then 
                Movement.EnableNoClip() 
            else 
                Movement.DisableNoClip()
            end 
        end)
    end)

    -- ========== FOV CHANGER ==========
    local FOVToggle = Tabs.Movement:AddToggle("FOVChanger", {
        Title = "FOV Changer", 
        Description = "", 
        Default = false
    })

    FOVToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Movement.ToggleFOV(v)
        end)
    end)

    local FOVSlider = Tabs.Movement:AddSlider("FOVValue", {
        Title = "FOV Value", 
        Description = "0-120",
        Default = 95,
        Min = 0,
        Max = 120,
        Rounding = 0,
        Callback = function(value)
            Nexus.SafeCallback(function()
                Movement.SetFOV(value)
            end)
        end
    })

    -- ========== FLY ==========
    if Nexus.IS_DESKTOP then
        local FlyToggle = Tabs.Movement:AddToggle("Fly", {
            Title = "Fly", 
            Description = "Allows flying in any direction", 
            Default = false
        })

        FlyToggle:OnChanged(function(value) 
            Nexus.SafeCallback(function()
                if value then 
                    Movement.EnableFly() 
                else 
                    Movement.DisableFly() 
                end 
            end)
        end)

        local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
            Title = "Fly Speed", 
            Description = "0-200", 
            Default = 50, 
            Min = 0, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                Nexus.SafeCallback(function()
                    Movement.SetFlySpeed(value)
                end)
            end
        })

        -- ========== FREE CAMERA ==========
        local FreeCameraToggle = Tabs.Movement:AddToggle("FreeCamera", {
            Title = "Free Camera", 
            Description = "", 
            Default = false
        })

        FreeCameraToggle:OnChanged(function(value) 
            Nexus.SafeCallback(function()
                if value then 
                    Movement.EnableFreeCamera() 
                else 
                    Movement.DisableFreeCamera() 
                end 
            end)
        end)

        local FreeCameraSpeedSlider = Tabs.Movement:AddSlider("FreeCameraSpeed", {
            Title = "Free Camera Speed", 
            Description = "0-100", 
            Default = 50, 
            Min = 0, 
            Max = 100, 
            Rounding = 0, 
            Callback = function(value) 
                Nexus.SafeCallback(function()
                    Movement.SetFreeCameraSpeed(value)
                end)
            end
        })
    end

    print("✓ Movement module initialized")
end

-- ========== TELEPORT FUNCTIONS ==========

function Movement.TeleportToRandomGenerator()
    local matches = Movement.CollectGenerators()
    if #matches > 0 then 
        Movement.SafeTeleportTo(matches[math.random(1, #matches)])
        Nexus.Fluent:Notify({
            Title = "Teleport",
            Content = "Teleported to random generator",
            Duration = 2
        })
    end
end

function Movement.TeleportToRandomHook()
    local matches = Movement.CollectHooks()
    if #matches > 0 then 
        Movement.SafeTeleportTo(matches[math.random(1, #matches)])
        Nexus.Fluent:Notify({
            Title = "Teleport",
            Content = "Teleported to random hook",
            Duration = 2
        })
    end
end

function Movement.TeleportToRandomPlayer()
    local pool = Movement.CollectPlayers()
    if #pool > 0 then
        local target = pool[math.random(1, #pool)]
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then 
            Movement.SafeTeleportTo(hrp)
            Nexus.Fluent:Notify({
                Title = "Teleport",
                Content = "Teleported to " .. target.Name,
                Duration = 2
            })
        end
    end
end

function Movement.TeleportToNearestGenerator()
    local matches = Movement.CollectGenerators()
    if #matches == 0 then return false end
    
    local character = Nexus.getCharacter()
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local nearestGenerator = nil
    local nearestDistance = math.huge
    
    for _, generator in ipairs(matches) do
        local distance = (hrp.Position - generator.Position).Magnitude
        if distance < nearestDistance then
            nearestDistance = distance
            nearestGenerator = generator
        end
    end
    
    if nearestGenerator then
        Movement.SafeTeleportTo(nearestGenerator)
        Nexus.Fluent:Notify({
            Title = "Teleport",
            Content = "Teleported to nearest generator",
            Duration = 2
        })
        return true
    end
    return false
end

function Movement.TeleportToNearestPlayer()
    local pool = Movement.CollectPlayers()
    if #pool == 0 then return false end
    
    local character = Nexus.getCharacter()
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local nearestPlayer = nil
    local nearestDistance = math.huge
    
    for _, target in ipairs(pool) do
        if target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                local distance = (hrp.Position - targetHrp.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = target
                end
            end
        end
    end
    
    if nearestPlayer and nearestPlayer.Character then
        local targetHrp = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            Movement.SafeTeleportTo(targetHrp)
            Nexus.Fluent:Notify({
                Title = "Teleport",
                Content = "Teleported to nearest player: " .. nearestPlayer.Name,
                Duration = 2
            })
            return true
        end
    end
    return false
end

function Movement.CollectGenerators()
    local matches = {}
    local generatorNames = {
        ["generator"] = true,
        ["generator_old"] = true,
        ["gene"] = true
    }
    local generatorPrefix = "ge"
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if generatorNames[nameLower] or string.sub(nameLower, 1, #generatorPrefix) == generatorPrefix then
                local root = Movement.FindRootForDesc(obj) or obj
                if root and root.Parent then
                    table.insert(matches, root)
                end
            end
        end
    end
    return matches
end

function Movement.CollectHooks()
    local matches = {}
    local hookNames = {
        ["hookpoint"] = true,
        ["hook"] = true,
        ["hookmeat"] = true
    }
    local hookPrefix = "ho"
    
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if hookNames[nameLower] or string.sub(nameLower, 1, #hookPrefix) == hookPrefix then
                local root = Movement.FindRootForDesc(obj) or obj
                if root and root.Parent then
                    table.insert(matches, root)
                end
            end
        end
    end
    return matches
end

function Movement.CollectPlayers()
    local pool = {}
    for _, pl in ipairs(Nexus.Services.Players:GetPlayers()) do
        if pl ~= Nexus.Player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(pool, pl)
        end
    end
    return pool
end

function Movement.FindRootForDesc(desc)
    if not desc then return nil end
    if desc:IsA("BasePart") or desc:IsA("MeshPart") then
        return desc
    end
    if desc:IsA("Model") then
        return desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart") or desc:FindFirstChildWhichIsA("MeshPart")
    end
    return nil
end

function Movement.SafeTeleportTo(part)
    local char = Nexus.getCharacter()
    if not char or not part then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if not part or not part.Parent then return false end
    
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end)
    return true
end

-- ========== INFINITE LUNGE FUNCTIONS ==========

function Movement.EnableInfiniteLunge()
    if Movement.InfiniteLunge.enabled then return end
    Movement.InfiniteLunge.enabled = true
    Nexus.States.InfiniteLungeEnabled = true
    
    -- Input handlers
    local inputBeganConn = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        Movement.HandleLungeInput(input, gameProcessed, true)
    end)
    
    local inputEndedConn = Nexus.Services.UserInputService.InputEnded:Connect(function(input, gameProcessed)
        Movement.HandleLungeInput(input, gameProcessed, false)
    end)
    
    Movement.Connections.InfiniteLungeBegan = inputBeganConn
    Movement.Connections.InfiniteLungeEnded = inputEndedConn
    
    print("Infinite Lunge Enabled")
end

function Movement.DisableInfiniteLunge()
    if not Movement.InfiniteLunge.enabled then return end
    Movement.InfiniteLunge.enabled = false
    Nexus.States.InfiniteLungeEnabled = false
    Movement.InfiniteLunge.isLunging = false
    
    if Movement.InfiniteLunge.connection then
        Movement.InfiniteLunge.connection:Disconnect()
        Movement.InfiniteLunge.connection = nil
    end
    
    Nexus.safeDisconnect(Movement.Connections.InfiniteLungeBegan)
    Nexus.safeDisconnect(Movement.Connections.InfiniteLungeEnded)
    
    print("Infinite Lunge Disabled")
end

function Movement.HandleLungeInput(input, gameProcessed, isBegan)
    if gameProcessed or not Movement.InfiniteLunge.enabled then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isBegan then
            Movement.InfiniteLunge.isLunging = true
            Movement.StartLunge()
        else
            Movement.InfiniteLunge.isLunging = false
            Movement.StopLunge()
        end
    end
end

function Movement.StartLunge()
    if Movement.InfiniteLunge.connection then
        Movement.InfiniteLunge.connection:Disconnect()
    end
    
    Movement.InfiniteLunge.connection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Movement.InfiniteLunge.enabled or not Movement.InfiniteLunge.isLunging or not Nexus.Player.Character then
            if Movement.InfiniteLunge.connection then
                Movement.InfiniteLunge.connection:Disconnect()
                Movement.InfiniteLunge.connection = nil
            end
            return
        end
        
        local rootPart = Nexus.Player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local lookVector = rootPart.CFrame.LookVector
            local velocity = lookVector * Movement.InfiniteLunge.speed
            rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
        end
    end)
end

function Movement.StopLunge()
    if Movement.InfiniteLunge.connection then
        Movement.InfiniteLunge.connection:Disconnect()
        Movement.InfiniteLunge.connection = nil
    end
end

function Movement.SetLungeSpeed(speed)
    Movement.InfiniteLunge.speed = tonumber(speed) or 50
    print("Lunge speed set to: " .. Movement.InfiniteLunge.speed)
end

-- ========== WALK SPEED FUNCTIONS ==========

function Movement.EnableWalkSpeed()
    if Movement.WalkSpeed.enabled then return end
    Movement.WalkSpeed.enabled = true
    Nexus.States.WalkSpeedEnabled = true
    
    Movement.WalkSpeed.connection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Movement.WalkSpeed.enabled or not Nexus.Player.Character then
            if Movement.WalkSpeed.connection then
                Movement.WalkSpeed.connection:Disconnect()
                Movement.WalkSpeed.connection = nil
            end
            return
        end
        
        local character = Nexus.Player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local direction = Vector3.new(0, 0, 0)
        local camera = Nexus.Services.Workspace.CurrentCamera
        
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit
            local velocity = direction * Movement.WalkSpeed.speed
            rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
        end
    end)
    
    print("WalkSpeed Enabled")
end

function Movement.DisableWalkSpeed()
    if not Movement.WalkSpeed.enabled then return end
    Movement.WalkSpeed.enabled = false
    Nexus.States.WalkSpeedEnabled = false
    
    if Movement.WalkSpeed.connection then
        Movement.WalkSpeed.connection:Disconnect()
        Movement.WalkSpeed.connection = nil
    end
    
    print("WalkSpeed Disabled")
end

function Movement.SetWalkSpeed(speed)
    Movement.WalkSpeed.speed = tonumber(speed) or 16
    print("WalkSpeed set to: " .. Movement.WalkSpeed.speed)
end

-- ========== NOCLIP FUNCTIONS ==========

function Movement.EnableNoClip()
    if Movement.NoClip.enabled then return end
    Movement.NoClip.enabled = true
    Nexus.States.noclipEnabled = true
    
    local function saveOriginalCollisions(character)
        if not character then return end
        
        Movement.NoClip.originalCollisions = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then 
                Movement.NoClip.originalCollisions[part] = part.CanCollide
            end
        end
    end

    local function restoreOriginalCollisions(character)
        if not character then return end
        
        for part, canCollide in pairs(Movement.NoClip.originalCollisions) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = canCollide
                end)
            end
        end
        Movement.NoClip.originalCollisions = {}
    end

    local character = Nexus.getCharacter()
    if character then
        saveOriginalCollisions(character)
    end
    
    Movement.NoClip.connection = Nexus.Services.RunService.Stepped:Connect(function()
        if not Movement.NoClip.enabled or not Nexus.getCharacter() then 
            if Movement.NoClip.connection then
                Movement.NoClip.connection:Disconnect()
                Movement.NoClip.connection = nil
            end
            return 
        end
        
        local character = Nexus.getCharacter()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then 
                    pcall(function()
                        part.CanCollide = false
                    end)
                end
            end
        end
    end)
    
    Nexus.Player.CharacterAdded:Connect(function(newChar)
        if Movement.NoClip.enabled then
            task.wait(1)
            saveOriginalCollisions(newChar)
            print("NoClip applied to new character")
        end
    end)
    
    print("NoClip Enabled")
end

function Movement.DisableNoClip()
    if not Movement.NoClip.enabled then return end
    Movement.NoClip.enabled = false
    Nexus.States.noclipEnabled = false
    
    if Movement.NoClip.connection then
        Movement.NoClip.connection:Disconnect()
        Movement.NoClip.connection = nil
    end
    
    local character = Nexus.getCharacter()
    if character then
        restoreOriginalCollisions(character)
    end
    
    print("NoClip Disabled")
end

-- ========== FOV FUNCTIONS ==========

function Movement.ToggleFOV(enabled)
    Movement.FOV.enabled = enabled
    Movement.ApplyFOV()
end

function Movement.SetFOV(value)
    Movement.FOV.value = value
    Movement.FOV.targetValue = value
    Movement.ApplyFOV()
end

function Movement.ApplyFOV()
    local camera = Nexus.Camera
    if camera and Movement.FOV.enabled then
        Movement.FOV.targetValue = Movement.FOV.value
        
        if Movement.FOV.currentTween then
            Movement.FOV.currentTween:Cancel()
        end
        
        Movement.FOV.currentTween = Nexus.Services.TweenService:Create(camera, Movement.FOV.tweenInfo, 
            {FieldOfView = Movement.FOV.targetValue})
        Movement.FOV.currentTween:Play()
    elseif camera then
        if Movement.FOV.currentTween then
            Movement.FOV.currentTween:Cancel()
            Movement.FOV.currentTween = nil
        end
        camera.FieldOfView = 70
    end
end

-- ========== FLY FUNCTIONS ==========

function Movement.EnableFly()
    if Movement.Fly.enabled then return end
    Movement.Fly.enabled = true
    Nexus.States.FlyEnabled = true
    
    local character, humanoid, rootPart = Nexus.getCharacter(), Nexus.getHumanoid(), Nexus.getRootPart()
    if not character or not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    Movement.Fly.bodyVelocity = Instance.new("BodyVelocity")
    Movement.Fly.bodyGyro = Instance.new("BodyGyro")
    
    Movement.Fly.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Movement.Fly.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Fly.bodyVelocity.Parent = rootPart
    
    Movement.Fly.bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Fly.bodyGyro.P = 10000
    Movement.Fly.bodyGyro.D = 500
    Movement.Fly.bodyGyro.CFrame = rootPart.CFrame
    Movement.Fly.bodyGyro.Parent = rootPart

    Movement.Fly.connection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Movement.Fly.enabled or not Movement.Fly.bodyVelocity or not Movement.Fly.bodyGyro or 
           not character or not humanoid or not rootPart then
            if Movement.Fly.connection then
                Movement.Fly.connection:Disconnect()
                Movement.Fly.connection = nil
            end
            return
        end
        
        local camera, direction = Nexus.Services.Workspace.CurrentCamera, Vector3.new(0, 0, 0)
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            direction = direction + camera.CFrame.LookVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            direction = direction - camera.CFrame.LookVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            direction = direction - camera.CFrame.RightVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            direction = direction + camera.CFrame.RightVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
            direction = direction + Vector3.new(0, 1, 0) 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then 
            direction = direction + Vector3.new(0, -1, 0) 
        end

        if direction.Magnitude > 0 then 
            direction = direction.Unit * Movement.Fly.speed 
        end
        
        Movement.Fly.bodyVelocity.Velocity = direction
        Movement.Fly.bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
    end)
    
    print("Fly Enabled")
end

function Movement.DisableFly()
    if not Movement.Fly.enabled then return end
    Movement.Fly.enabled = false
    Nexus.States.FlyEnabled = false
    
    if Movement.Fly.bodyVelocity then 
        Movement.Fly.bodyVelocity:Destroy()
        Movement.Fly.bodyVelocity = nil 
    end
    if Movement.Fly.bodyGyro then 
        Movement.Fly.bodyGyro:Destroy()
        Movement.Fly.bodyGyro = nil 
    end
    
    local humanoid = Nexus.getHumanoid()
    if humanoid then 
        humanoid.PlatformStand = false 
    end
    
    if Movement.Fly.connection then
        Movement.Fly.connection:Disconnect()
        Movement.Fly.connection = nil
    end
    
    print("Fly Disabled")
end

function Movement.SetFlySpeed(speed)
    Movement.Fly.speed = tonumber(speed) or 50
    print("Fly speed set to: " .. Movement.Fly.speed)
end

-- ========== FREE CAMERA FUNCTIONS ==========

function Movement.EnableFreeCamera()
    if Movement.FreeCamera.enabled then return end
    Movement.FreeCamera.enabled = true
    Nexus.States.FreeCameraEnabled = true
    
    local camera = Nexus.Camera
    Movement.FreeCamera.originalCameraType = camera.CameraType
    Movement.FreeCamera.originalCameraSubject = camera.CameraSubject
    camera.CameraType = Enum.CameraType.Scriptable
    
    local cameraPosition = camera.CFrame.Position
    local lookVector = camera.CFrame.LookVector
    local cameraRotation = Vector2.new(math.atan2(lookVector.X, lookVector.Z), math.asin(lookVector.Y))
    
    Movement.LockMouse()
    
    if Nexus.getCharacter() then
        local humanoid, rootPart = Nexus.getHumanoid(), Nexus.getRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = false 
        end
        if rootPart then 
            rootPart.Anchored = true 
        end
    end
    
    Movement.FreeCamera.connection = Nexus.Services.RunService.RenderStepped:Connect(function(delta)
        if not Movement.FreeCamera.enabled then 
            if Movement.FreeCamera.connection then
                Movement.FreeCamera.connection:Disconnect()
                Movement.FreeCamera.connection = nil
            end
            return 
        end
        
        local mouseDelta = Nexus.Services.UserInputService:GetMouseDelta()
        cameraRotation = cameraRotation + Vector2.new(-mouseDelta.X * 0.003, -mouseDelta.Y * 0.003)
        cameraRotation = Vector2.new(cameraRotation.X, 
            math.clamp(cameraRotation.Y, -math.pi/2 + 0.1, math.pi/2 - 0.1))
        
        local rotationCFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
        local moveDirection = Vector3.new(0, 0, 0)
        
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            moveDirection = moveDirection + rotationCFrame.LookVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            moveDirection = moveDirection - rotationCFrame.LookVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            moveDirection = moveDirection - rotationCFrame.RightVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            moveDirection = moveDirection + rotationCFrame.RightVector 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.E) or 
           Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
            moveDirection = moveDirection + Vector3.new(0, 1, 0) 
        end
        if Nexus.Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) then 
            moveDirection = moveDirection + Vector3.new(0, -1, 0) 
        end
        
        if moveDirection.Magnitude > 0 then 
            moveDirection = moveDirection.Unit * Movement.FreeCamera.speed
            cameraPosition = cameraPosition + moveDirection * delta 
        end
        
        camera.CFrame = CFrame.new(cameraPosition) * rotationCFrame
    end)
    
    print("Free Camera Enabled")
end

function Movement.DisableFreeCamera()
    if not Movement.FreeCamera.enabled then return end
    Movement.FreeCamera.enabled = false
    Nexus.States.FreeCameraEnabled = false
    
    Movement.UnlockMouse()
    
    if Movement.FreeCamera.connection then
        Movement.FreeCamera.connection:Disconnect()
        Movement.FreeCamera.connection = nil
    end
    
    local camera = Nexus.Camera
    camera.CameraType = Movement.FreeCamera.originalCameraType
    camera.CameraSubject = Movement.FreeCamera.originalCameraSubject
    
    if Nexus.getCharacter() then
        local humanoid, rootPart = Nexus.getHumanoid(), Nexus.getRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true 
        end
        if rootPart then 
            rootPart.Anchored = false 
        end
    end
    
    print("Free Camera Disabled")
end

function Movement.LockMouse()
    if not Movement.FreeCamera.enabled then return end
    Movement.FreeCamera.mouseLocked = true
    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Nexus.Services.UserInputService.MouseIconEnabled = false
end

function Movement.UnlockMouse()
    Movement.FreeCamera.mouseLocked = false
    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Nexus.Services.UserInputService.MouseIconEnabled = true
end

function Movement.SetFreeCameraSpeed(speed)
    Movement.FreeCamera.speed = tonumber(speed) or 50
    print("Free Camera speed set to: " .. Movement.FreeCamera.speed)
end

-- ========== CLEANUP ==========

function Movement.Cleanup()
    -- Отключаем все функции
    Movement.DisableInfiniteLunge()
    Movement.DisableWalkSpeed()
    Movement.DisableNoClip()
    Movement.DisableFly()
    Movement.DisableFreeCamera()
    Movement.ToggleFOV(false)
    
    -- Очищаем соединения
    for key, connection in pairs(Movement.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Movement.Connections = {}
    
    print("Movement module cleaned up")
end

return Movement
