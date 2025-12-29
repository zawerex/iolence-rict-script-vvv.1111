local Nexus = _G.Nexus

local Movement = {
    Connections = {},
    States = {},
    Objects = {}
}

-- ========== UTILITY FUNCTIONS ==========

local function setupCharacterListener(callback)
    local charAddedConn = Nexus.Player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        callback(character)
    end)
    
    local currentChar = Nexus.getCharacter()
    if currentChar then
        task.spawn(function()
            task.wait(0.5)
            callback(currentChar)
        end)
    end
    
    return charAddedConn
end

-- ========== INFINITE LUNGE ==========

local InfiniteLunge = (function()
    local enabled = false
    local characterListeners = {}
    
    local function updateInfiniteLunge()
        if enabled then
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local state = humanoid:GetState()
                    local isCrawling = state == Enum.HumanoidStateType.FallingDown or 
                                      state == Enum.HumanoidStateType.GettingUp or
                                      state == Enum.HumanoidStateType.Freefall
                    
                    if not isCrawling then
                        humanoid:SetAttribute("InfiniteLunge", true)
                        humanoid.WalkSpeed = 28
                    else
                        humanoid:SetAttribute("InfiniteLunge", nil)
                    end
                end
            end
        else
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("InfiniteLunge", nil)
                end
            end
        end
    end
    
    local function setupInfiniteLungeForCharacter(character)
        if not enabled then return end
        
        task.wait(1)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetAttribute("InfiniteLunge", true)
            humanoid.WalkSpeed = 28
            
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if enabled and humanoid.WalkSpeed ~= 28 then
                    task.wait(0.1)
                    humanoid.WalkSpeed = 28
                end
            end)
            
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2)
                    if Nexus.getCharacter() then
                        setupInfiniteLungeForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.InfiniteLungeEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(setupInfiniteLungeForCharacter))
        
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupInfiniteLungeForCharacter(currentChar)
        end
        
        local updateConn = Nexus.Services.RunService.Heartbeat:Connect(updateInfiniteLunge)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.InfiniteLungeEnabled = false
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("InfiniteLunge", nil)
            end
        end
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== WALK SPEED ==========

local WalkSpeed = (function()
    local enabled = false
    local targetSpeed = 16
    local characterListeners = {}
    local originalSpeeds = {}
    
    local function updateWalkSpeed()
        if enabled then
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local state = humanoid:GetState()
                    local isCrawling = state == Enum.HumanoidStateType.FallingDown or 
                                      state == Enum.HumanoidStateType.GettingUp or
                                      state == Enum.HumanoidStateType.Freefall
                    
                    if not isCrawling and humanoid.WalkSpeed ~= targetSpeed then
                        humanoid:SetAttribute("WalkSpeedBoost", true)
                        humanoid.WalkSpeed = targetSpeed
                    end
                end
            end
        else
            local character = Nexus.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("WalkSpeedBoost", nil)
                    if originalSpeeds[character] then
                        humanoid.WalkSpeed = originalSpeeds[character]
                        originalSpeeds[character] = nil
                    end
                end
            end
        end
    end
    
    local function setupWalkSpeedForCharacter(character)
        if not enabled then return end
        
        task.wait(1)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if not originalSpeeds[character] then
                originalSpeeds[character] = humanoid.WalkSpeed
            end
            
            humanoid:SetAttribute("WalkSpeedBoost", true)
            humanoid.WalkSpeed = targetSpeed
            
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if enabled and humanoid.WalkSpeed ~= targetSpeed then
                    task.wait(0.1)
                    humanoid.WalkSpeed = targetSpeed
                end
            end)
            
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2)
                    if Nexus.getCharacter() then
                        setupWalkSpeedForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.WalkSpeedEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(setupWalkSpeedForCharacter))
        
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupWalkSpeedForCharacter(currentChar)
        end
        
        local updateConn = Nexus.Services.RunService.Heartbeat:Connect(updateWalkSpeed)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.WalkSpeedEnabled = false
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("WalkSpeedBoost", nil)
                if originalSpeeds[character] then
                    humanoid.WalkSpeed = originalSpeeds[character]
                    originalSpeeds[character] = nil
                end
            end
        end
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    local function SetSpeed(speed)
        targetSpeed = math.clamp(speed, 16, 100)
        if enabled then
            updateWalkSpeed()
        end
    end
    
    local function GetSpeed()
        return targetSpeed
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetSpeed = SetSpeed,
        GetSpeed = GetSpeed
    }
end)()

-- ========== NOCLIP ==========

local Noclip = (function()
    local enabled = false
    local characterListeners = {}
    local noclipConnection = nil
    
    local function updateNoclip()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    local function setupNoclipForCharacter(character)
        if not enabled then return end
        
        task.wait(1)
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        local function onDescendantAdded(descendant)
            if enabled and descendant:IsA("BasePart") then
                descendant.CanCollide = false
            end
        end
        
        local descendantConn = character.DescendantAdded:Connect(onDescendantAdded)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2)
                    if Nexus.getCharacter() then
                        setupNoclipForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
        
        return descendantConn
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.NoclipEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(function(character)
            local descendantConn = setupNoclipForCharacter(character)
            if descendantConn then
                table.insert(characterListeners, descendantConn)
            end
        end))
        
        local currentChar = Nexus.getCharacter()
        if currentChar then
            local descendantConn = setupNoclipForCharacter(currentChar)
            if descendantConn then
                table.insert(characterListeners, descendantConn)
            end
        end
        
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        noclipConnection = Nexus.Services.RunService.Stepped:Connect(updateNoclip)
        table.insert(characterListeners, noclipConnection)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.NoclipEnabled = false
        
        local character = Nexus.getCharacter()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== FOV CHANGER ==========

local FOVChanger = (function()
    local enabled = false
    local targetFOV = 70
    local characterListeners = {}
    local currentTween = nil
    local defaultFOV = 70
    
    local function updateFOV()
        if not enabled then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        
        if camera.FieldOfView ~= targetFOV then
            currentTween = Nexus.Services.TweenService:Create(
                camera,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {FieldOfView = targetFOV}
            )
            currentTween:Play()
        end
    end
    
    local function resetFOV()
        local camera = Nexus.Services.Workspace.CurrentCamera
        if camera then
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            
            camera.FieldOfView = defaultFOV
            targetFOV = defaultFOV
        end
    end
    
    local function setupFOVForCharacter()
        if not enabled then return end
        
        task.wait(0.5)
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if camera then
            defaultFOV = camera.FieldOfView
            targetFOV = defaultFOV
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FOVChangerEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(setupFOVForCharacter))
        
        local cameraChangedConn = Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if enabled then
                task.wait(0.1)
                setupFOVForCharacter()
            end
        end)
        table.insert(characterListeners, cameraChangedConn)
        
        setupFOVForCharacter()
        
        local updateConn = Nexus.Services.RunService.Heartbeat:Connect(updateFOV)
        table.insert(characterListeners, updateConn)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FOVChangerEnabled = false
        
        resetFOV()
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    local function SetFOV(fov)
        targetFOV = math.clamp(fov, 1, 120)
        if enabled then
            updateFOV()
        end
    end
    
    local function GetFOV()
        return targetFOV
    end
    
    local function GetCurrentFOV()
        local camera = Nexus.Services.Workspace.CurrentCamera
        return camera and camera.FieldOfView or defaultFOV
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetFOV = SetFOV,
        GetFOV = GetFOV,
        GetCurrentFOV = GetCurrentFOV
    }
end)()

-- ========== FLY ==========

local Fly = (function()
    local enabled = false
    local flySpeed = 50
    local characterListeners = {}
    local flyConnection = nil
    local controls = {
        W = false,
        A = false,
        S = false,
        D = false,
        Space = false,
        LeftShift = false
    }
    
    local function updateFly()
        if not enabled then return end
        
        local character = Nexus.getCharacter()
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local direction = Vector3.new(0, 0, 0)
        
        if controls.W then direction = direction + Nexus.Services.Workspace.CurrentCamera.CFrame.LookVector end
        if controls.S then direction = direction - Nexus.Services.Workspace.CurrentCamera.CFrame.LookVector end
        if controls.D then direction = direction + Nexus.Services.Workspace.CurrentCamera.CFrame.RightVector end
        if controls.A then direction = direction - Nexus.Services.Workspace.CurrentCamera.CFrame.RightVector end
        
        if controls.Space then direction = direction + Vector3.new(0, 1, 0) end
        if controls.LeftShift then direction = direction + Vector3.new(0, -1, 0) end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeed
            
            humanoid.PlatformStand = true
            
            humanoidRootPart.Velocity = direction
        else
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    local function setupControls()
        local inputBeganConn = Nexus.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not enabled then return end
            
            if input.KeyCode == Enum.KeyCode.W then controls.W = true
            elseif input.KeyCode == Enum.KeyCode.A then controls.A = true
            elseif input.KeyCode == Enum.KeyCode.S then controls.S = true
            elseif input.KeyCode == Enum.KeyCode.D then controls.D = true
            elseif input.KeyCode == Enum.KeyCode.Space then controls.Space = true
            elseif input.KeyCode == Enum.KeyCode.LeftShift then controls.LeftShift = true end
        end)
        
        local inputEndedConn = Nexus.Services.UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed or not enabled then return end
            
            if input.KeyCode == Enum.KeyCode.W then controls.W = false
            elseif input.KeyCode == Enum.KeyCode.A then controls.A = false
            elseif input.KeyCode == Enum.KeyCode.S then controls.S = false
            elseif input.KeyCode == Enum.KeyCode.D then controls.D = false
            elseif input.KeyCode == Enum.KeyCode.Space then controls.Space = false
            elseif input.KeyCode == Enum.KeyCode.LeftShift then controls.LeftShift = false end
        end)
        
        return {inputBeganConn, inputEndedConn}
    end
    
    local function resetFlyState()
        controls = {
            W = false,
            A = false,
            S = false,
            D = false,
            Space = false,
            LeftShift = false
        }
        
        local character = Nexus.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
    
    local function setupFlyForCharacter(character)
        if not enabled then return end
        
        task.wait(1)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetAttribute("FlyEnabled", true)
            
            humanoid.Died:Connect(function()
                if enabled then
                    resetFlyState()
                    task.wait(2)
                    if Nexus.getCharacter() then
                        setupFlyForCharacter(Nexus.getCharacter())
                    end
                end
            end)
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FlyEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Nexus.safeDisconnect(conn)
                end
            else
                Nexus.safeDisconnect(listener)
            end
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(setupFlyForCharacter))
        
        local controlConns = setupControls()
        for _, conn in ipairs(controlConns) do
            table.insert(characterListeners, conn)
        end
        
        local currentChar = Nexus.getCharacter()
        if currentChar then
            setupFlyForCharacter(currentChar)
        end
        
        if flyConnection then
            flyConnection:Disconnect()
        end
        flyConnection = Nexus.Services.RunService.Heartbeat:Connect(updateFly)
        table.insert(characterListeners, flyConnection)
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FlyEnabled = false
        
        resetFlyState()
        
        for _, listener in ipairs(characterListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Nexus.safeDisconnect(conn)
                end
            else
                Nexus.safeDisconnect(listener)
            end
        end
        characterListeners = {}
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
    
    local function SetSpeed(speed)
        flySpeed = math.clamp(speed, 10, 200)
    end
    
    local function GetSpeed()
        return flySpeed
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetSpeed = SetSpeed,
        GetSpeed = GetSpeed
    }
end)()

-- ========== FREE CAMERA ==========

local FreeCamera = (function()
    local enabled = false
    local characterListeners = {}
    local originalCameraType = nil
    local originalCameraSubject = nil
    local cameraLocked = false
    
    local function lockCamera()
        if cameraLocked then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        originalCameraType = camera.CameraType
        originalCameraSubject = camera.CameraSubject
        
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
        cameraLocked = true
    end
    
    local function unlockCamera()
        if not cameraLocked then return end
        
        local camera = Nexus.Services.Workspace.CurrentCamera
        if not camera then return end
        
        camera.CameraType = originalCameraType or Enum.CameraType.Custom
        camera.CameraSubject = originalCameraSubject
        
        originalCameraType = nil
        originalCameraSubject = nil
        cameraLocked = false
    end
    
    local function setupFreeCameraForCharacter()
        if not enabled then return end
        
        task.wait(0.5)
        
        lockCamera()
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Nexus.States.FreeCameraEnabled = true
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
        
        table.insert(characterListeners, setupCharacterListener(setupFreeCameraForCharacter))
        
        local cameraChangedConn = Nexus.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if enabled then
                task.wait(0.1)
                setupFreeCameraForCharacter()
            end
        end)
        table.insert(characterListeners, cameraChangedConn)
        
        setupFreeCameraForCharacter()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Nexus.States.FreeCameraEnabled = false
        
        unlockCamera()
        
        for _, listener in ipairs(characterListeners) do
            Nexus.safeDisconnect(listener)
        end
        characterListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- ========== MODULE INITIALIZATION ==========

function Movement.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    local InfiniteLungeToggle = Tabs.Movement:AddToggle("InfiniteLunge", {
        Title = "Infinite Lunge", 
        Description = "Unlimited lunge distance and speed", 
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

    local WalkSpeedToggle = Tabs.Movement:AddToggle("WalkSpeed", {
        Title = "Walk Speed", 
        Description = "Increase walking speed", 
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
        Description = "Adjust walking speed",
        Default = 16,
        Min = 16,
        Max = 100,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                WalkSpeed.SetSpeed(value)
            end)
        end
    })

    local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
        Title = "Noclip", 
        Description = "Walk through walls and objects", 
        Default = false
    })

    NoclipToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Noclip.Enable() 
            else 
                Noclip.Disable() 
            end
        end)
    end)

    local FOVToggle = Tabs.Movement:AddToggle("FOVChanger", {
        Title = "FOV Changer", 
        Description = "Change field of view (1-120)", 
        Default = false
    })

    FOVToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                FOVChanger.Enable() 
            else 
                FOVChanger.Disable() 
            end
        end)
    end)

    local FOVSlider = Tabs.Movement:AddSlider("FOVValue", {
        Title = "FOV Value",
        Description = "Adjust field of view (1-120)",
        Default = 70,
        Min = 1,
        Max = 120,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                FOVChanger.SetFOV(value)
            end)
        end
    })

    local FlyToggle = Tabs.Movement:AddToggle("Fly", {
        Title = "Fly", 
        Description = "Fly around the map", 
        Default = false
    })

    FlyToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                Fly.Enable() 
            else 
                Fly.Disable() 
            end
        end)
    end)

    local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Description = "Adjust flying speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                Fly.SetSpeed(value)
            end)
        end
    })

    local FreeCameraToggle = Tabs.Movement:AddToggle("FreeCamera", {
        Title = "Free Camera", 
        Description = "Detach camera from character", 
        Default = false
    })

    FreeCameraToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            if v then 
                FreeCamera.Enable() 
            else 
                FreeCamera.Disable() 
            end
        end)
    end)
end

-- ========== CLEANUP ==========

function Movement.Cleanup()
    InfiniteLunge.Disable()
    WalkSpeed.Disable()
    Noclip.Disable()
    FOVChanger.Disable()
    Fly.Disable()
    FreeCamera.Disable()
    
    for key, connection in pairs(Movement.Connections) do
        Nexus.safeDisconnect(connection)
    end
    Movement.Connections = {}
end

return Movement
