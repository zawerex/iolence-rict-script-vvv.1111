-- Movement Module - Movement functions for Violence District
local Nexus = _G.Nexus

local Movement = {
    Connections = {},
    States = {
        WalkSpeedEnabled = false,
        FlyEnabled = false,
        FreeCameraEnabled = false,
        noclipEnabled = false
    },
    Settings = {
        walkSpeed = 50,
        flySpeed = 50,
        freeCameraSpeed = 50,
        fovValue = 95,
        fovEnabled = false
    },
    Objects = {
        bodyVelocity = nil,
        bodyGyro = nil,
        currentTween = nil
    }
}

-- ========== HELPER FUNCTIONS ==========

function Movement.GetCharacter()
    return Nexus.Player.Character
end

function Movement.GetHumanoid()
    local char = Movement.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Movement.GetRootPart()
    local char = Movement.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ========== WALKSPEED ==========

local WalkSpeed = (function()
    local WALKSPEED_ENABLED = false
    local currentSpeed = 50
    local speedConnection = nil
    
    local function EnableWalkSpeed()
        if WALKSPEED_ENABLED then return end
        
        WALKSPEED_ENABLED = true
        Movement.States.WalkSpeedEnabled = true
        
        speedConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not WALKSPEED_ENABLED or not Nexus.Player.Character then
                if speedConnection then
                    speedConnection:Disconnect()
                    speedConnection = nil
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
                local velocity = direction * currentSpeed
                rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
            end
        end)
    end
    
    local function DisableWalkSpeed()
        if not WALKSPEED_ENABLED then return end
        
        WALKSPEED_ENABLED = false
        Movement.States.WalkSpeedEnabled = false
        
        if speedConnection then
            Nexus.safeDisconnect(speedConnection)
            speedConnection = nil
        end
    end
    
    local function SetSpeed(speed)
        currentSpeed = tonumber(speed) or 50
        Movement.Settings.walkSpeed = currentSpeed
    end
    
    return {
        Enable = EnableWalkSpeed,
        Disable = DisableWalkSpeed,
        SetSpeed = SetSpeed,
        IsEnabled = function() return WALKSPEED_ENABLED end,
        GetSpeed = function() return currentSpeed end
    }
end)()

-- ========== NOCLIP ==========

local NoClip = (function()
    local noclipEnabled = false
    local noclipConnection = nil
    local originalCollisions = {}

    local function saveOriginalCollisions(character)
        if not character then return end
        
        originalCollisions = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then 
                originalCollisions[part] = part.CanCollide
            end
        end
    end

    local function restoreOriginalCollisions(character)
        if not character then return end
        
        for part, canCollide in pairs(originalCollisions) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = canCollide
                end)
            end
        end
        originalCollisions = {}
    end

    local function EnableNoClip()
        if noclipEnabled then return end
        noclipEnabled = true
        Movement.States.noclipEnabled = true
        
        local character = Movement.GetCharacter()
        if character then
            saveOriginalCollisions(character)
        end
        
        noclipConnection = Nexus.Services.RunService.Stepped:Connect(function()
            if not noclipEnabled or not Movement.GetCharacter() then 
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                return 
            end
            
            local character = Movement.GetCharacter()
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
            if noclipEnabled then
                task.wait(1)
                saveOriginalCollisions(newChar)
            end
        end)
    end

    local function DisableNoClip()
        if not noclipEnabled then return end
        
        noclipEnabled = false
        Movement.States.noclipEnabled = false
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        local character = Movement.GetCharacter()
        if character then
            restoreOriginalCollisions(character)
        end
    end

    return {
        Enable = EnableNoClip,
        Disable = DisableNoClip,
        IsEnabled = function() return noclipEnabled end
    }
end)()

-- ========== FLY ==========

local function enableFly()
    if Movement.States.FlyEnabled then return end
    Movement.States.FlyEnabled = true
    
    local character, humanoid, rootPart = Movement.GetCharacter(), Movement.GetHumanoid(), Movement.GetRootPart()
    if not character or not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    Movement.Objects.bodyVelocity = Instance.new("BodyVelocity")
    Movement.Objects.bodyGyro = Instance.new("BodyGyro")
    
    Movement.Objects.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Movement.Objects.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Objects.bodyVelocity.Parent = rootPart
    
    Movement.Objects.bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Objects.bodyGyro.P = 10000
    Movement.Objects.bodyGyro.D = 500
    Movement.Objects.bodyGyro.CFrame = rootPart.CFrame
    Movement.Objects.bodyGyro.Parent = rootPart

    Movement.Connections.flyLoop = Nexus.Services.RunService.Heartbeat:Connect(function()
        if not Movement.States.FlyEnabled or not Movement.Objects.bodyVelocity or not Movement.Objects.bodyGyro or 
           not character or not humanoid or not rootPart then
            if Movement.Connections.flyLoop then
                Movement.Connections.flyLoop:Disconnect()
                Movement.Connections.flyLoop = nil
            end
            return
        end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)
        
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
            direction = direction.Unit * Movement.Settings.flySpeed 
        end
        
        Movement.Objects.bodyVelocity.Velocity = direction
        Movement.Objects.bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
    end)
end

local function disableFly()
    if not Movement.States.FlyEnabled then return end
    Movement.States.FlyEnabled = false
    
    if Movement.Objects.bodyVelocity then 
        Movement.Objects.bodyVelocity:Destroy()
        Movement.Objects.bodyVelocity = nil 
    end
    if Movement.Objects.bodyGyro then 
        Movement.Objects.bodyGyro:Destroy()
        Movement.Objects.bodyGyro = nil 
    end
    
    local humanoid = Movement.GetHumanoid()
    if humanoid then 
        humanoid.PlatformStand = false 
    end
    
    if Movement.Connections.flyLoop then
        Movement.Connections.flyLoop:Disconnect()
        Movement.Connections.flyLoop = nil
    end
end

-- ========== FREE CAMERA ==========

local function lockMouse()
    if not Movement.States.FreeCameraEnabled then return end
    Movement.Objects.mouseLocked = true
    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Nexus.Services.UserInputService.MouseIconEnabled = false
end

local function unlockMouse()
    Movement.Objects.mouseLocked = false
    Nexus.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Nexus.Services.UserInputService.MouseIconEnabled = true
end

local function startFreeCamera()
    if Movement.States.FreeCameraEnabled then return end
    Movement.States.FreeCameraEnabled = true
    
    local camera = Nexus.Camera
    Movement.Objects.originalCameraType = camera.CameraType
    Movement.Objects.originalCameraSubject = camera.CameraSubject
    camera.CameraType = Enum.CameraType.Scriptable
    
    local cameraPosition = camera.CFrame.Position
    local lookVector = camera.CFrame.LookVector
    local cameraRotation = Vector2.new(math.atan2(lookVector.X, lookVector.Z), math.asin(lookVector.Y))
    
    lockMouse()
    
    if Movement.GetCharacter() then
        local humanoid, rootPart = Movement.GetHumanoid(), Movement.GetRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = false 
        end
        if rootPart then 
            rootPart.Anchored = true 
        end
    end
    
    Movement.Connections.freeCamera = Nexus.Services.RunService.RenderStepped:Connect(function(delta)
        if not Movement.States.FreeCameraEnabled then 
            if Movement.Connections.freeCamera then
                Movement.Connections.freeCamera:Disconnect()
                Movement.Connections.freeCamera = nil
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
            moveDirection = moveDirection.Unit * Movement.Settings.freeCameraSpeed
            cameraPosition = cameraPosition + moveDirection * delta 
        end
        
        camera.CFrame = CFrame.new(cameraPosition) * rotationCFrame
    end)
end

local function stopFreeCamera()
    if not Movement.States.FreeCameraEnabled then return end
    Movement.States.FreeCameraEnabled = false
    
    unlockMouse()
    
    if Movement.Connections.freeCamera then
        Movement.Connections.freeCamera:Disconnect()
        Movement.Connections.freeCamera = nil
    end
    
    local camera = Nexus.Camera
    camera.CameraType = Movement.Objects.originalCameraType
    camera.CameraSubject = Movement.Objects.originalCameraSubject
    
    if Movement.GetCharacter() then
        local humanoid, rootPart = Movement.GetHumanoid(), Movement.GetRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true 
        end
        if rootPart then 
            rootPart.Anchored = false 
        end
    end
end

-- ========== INFINITE LUNGE ==========

local InfiniteLunge = (function()
    local isLunging = false
    local lungeSpeed = 50
    local lungeConnection = nil
    
    local function EnableInfiniteLunge()
        if Movement.States.InfiniteLungeEnabled then return end
        Movement.States.InfiniteLungeEnabled = true
    end
    
    local function DisableInfiniteLunge()
        Movement.States.InfiniteLungeEnabled = false
        isLunging = false
        
        if lungeConnection then
            lungeConnection:Disconnect()
            lungeConnection = nil
        end
    end
    
    local function HandleInput(input, gameProcessed)
        if gameProcessed or not Movement.States.InfiniteLungeEnabled then
            return
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.UserInputState == Enum.UserInputState.Begin then
                isLunging = true
                if Nexus.Player.Character then
                    if lungeConnection then
                        lungeConnection:Disconnect()
                    end
                    
                    lungeConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
                        if not Movement.States.InfiniteLungeEnabled or not isLunging or not Nexus.Player.Character then
                            if lungeConnection then
                                lungeConnection:Disconnect()
                                lungeConnection = nil
                            end
                            return
                        end
                        
                        local rootPart = Nexus.Player.Character:FindFirstChild("HumanoidRootPart")
                        
                        if rootPart then
                            local lookVector = rootPart.CFrame.LookVector
                            local velocity = lookVector * lungeSpeed
                            rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
                        end
                    end)
                end
                
            elseif input.UserInputState == Enum.UserInputState.End then
                isLunging = false
                if lungeConnection then
                    lungeConnection:Disconnect()
                    lungeConnection = nil
                end
            end
        end
    end
    

    local inputBeganConn = Nexus.Services.UserInputService.InputBegan:Connect(HandleInput)
    local inputEndedConn = Nexus.Services.UserInputService.InputEnded:Connect(HandleInput)

    Movement.Connections.InfiniteLungeBegan = inputBeganConn
    Movement.Connections.InfiniteLungeEnded = inputEndedConn
    
    return {
        Enable = EnableInfiniteLunge,
        Disable = DisableInfiniteLunge,
        SetSpeed = function(speed) 
            lungeSpeed = speed 
            Movement.Settings.lungeSpeed = speed
        end,
        IsEnabled = function() return Movement.States.InfiniteLungeEnabled end
    }
end)()

-- ========== FOV SYSTEM ==========

local function ApplyFOV()
    local camera = Nexus.Camera
    if camera and Movement.Settings.fovEnabled then
        Movement.Settings.fovTargetValue = Movement.Settings.fovValue
        
        if Movement.Objects.currentTween then
            Movement.Objects.currentTween:Cancel()
        end
        
        Movement.Objects.currentTween = Nexus.Services.TweenService:Create(camera, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {FieldOfView = Movement.Settings.fovTargetValue})
        Movement.Objects.currentTween:Play()
    elseif camera then
        if Movement.Objects.currentTween then
            Movement.Objects.currentTween:Cancel()
            Movement.Objects.currentTween = nil
        end
        camera.FieldOfView = 70
    end
end

-- ========== MODULE INITIALIZATION ==========

function Movement.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- Setup FOV system
    Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait(0.1)
        Nexus.Camera = Nexus.Services.Workspace.CurrentCamera
        ApplyFOV()
    end)

    if Nexus.Services.RunService.RenderStepped then
        Movement.Connections.FOVUpdater = Nexus.Services.RunService.RenderStepped:Connect(function()
            if Movement.Settings.fovEnabled and Nexus.Camera and 
               math.abs(Nexus.Camera.FieldOfView - Movement.Settings.fovTargetValue) > 0.1 then
                ApplyFOV()
            end
        end)
    end
    
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
                    InfiniteLunge.Enable() 
                else 
                    InfiniteLunge.Disable() 
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
                    InfiniteLunge.SetSpeed(value)
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
                WalkSpeed.Enable() 
            else 
                WalkSpeed.Disable() 
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
                WalkSpeed.SetSpeed(value)
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
                NoClip.Enable() 
            else 
                NoClip.Disable()
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
            Movement.Settings.fovEnabled = v
            ApplyFOV()
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
                Movement.Settings.fovValue = value
                ApplyFOV()
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
                    enableFly() 
                else 
                    disableFly() 
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
                    Movement.Settings.flySpeed = value
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
                    startFreeCamera() 
                else 
                    stopFreeCamera() 
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
                    Movement.Settings.freeCameraSpeed = value
                end)
            end
        })
    end
end

-- ========== CLEANUP ==========

function Movement.Cleanup()
    -- Отключаем все функции
    InfiniteLunge.Disable()
    WalkSpeed.Disable()
    NoClip.Disable()
    disableFly()
    stopFreeCamera()
    Movement.Settings.fovEnabled = false
    
    -- Восстанавливаем FOV
    local camera = Nexus.Camera
    if camera then
        camera.FieldOfView = 50
    end
    
    -- Очищаем объекты
    if Movement.Objects.bodyVelocity then 
        Movement.Objects.bodyVelocity:Destroy()
        Movement.Objects.bodyVelocity = nil 
    end
    if Movement.Objects.bodyGyro then 
        Movement.Objects.bodyGyro:Destroy()
        Movement.Objects.bodyGyro = nil 
    end
    
    -- Отключаем все соединения
    for key, connection in pairs(Movement.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Movement.Connections = {}
    
end

return Movement
