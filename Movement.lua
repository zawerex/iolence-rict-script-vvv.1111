-- Movement Module - All movement functions
local Nexus = _G.Nexus

local Movement = {
    Connections = {}
}

function Movement.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    local Options = Nexus.Options
    
    -- Кнопки телепортации
    Tabs.Movement:AddButton({
        Title = "Teleport to Random Generator", 
        Description = "Teleport to a random generator on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.teleportToRandomGenerator)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Hook", 
        Description = "Teleport to a random hook on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.teleportToRandomHook)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Random Player", 
        Description = "Teleport to a random player on the map",
        Callback = function()
            Nexus.SafeCallback(Movement.teleportToRandomPlayer)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Generator", 
        Description = "Teleport to the closest generator",
        Callback = function()
            Nexus.SafeCallback(Movement.teleportToNearestGenerator)
        end
    })

    Tabs.Movement:AddButton({
        Title = "Teleport to Nearest Player", 
        Description = "Teleport to the closest player",
        Callback = function()
            Nexus.SafeCallback(Movement.teleportToNearestPlayer)
        end
    })

    -- Infinite Lunge
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

    -- Walk Speed
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

    -- Noclip
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

    -- FOV Changer
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

    -- Fly
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

        -- Free Camera
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

-- Здесь будут реализации функций движения...

return Movement
