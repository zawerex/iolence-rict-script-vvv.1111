local Nexus = _G.Nexus

local Fun = {
    CurrentEmoteTrack = nil,
    CurrentSound = nil,
    CurrentAnimation = nil,
    AvailableEmotes = {},
    EmotesFolder = nil,
    JerkTool = {
        active = false,
        tool = nil,
        track = nil
    }
}

function Fun.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    
    local emotesInitialized = Fun.InitializeEmotesSystem()
    
    if emotesInitialized then
        Tabs.Fun:AddParagraph({
            Title = "Emotes System",
            Content = "Select an emote to play"
        })
        
        local emotesList = {}
        for _, emote in ipairs(Fun.AvailableEmotes) do
            table.insert(emotesList, emote)
        end
        table.insert(emotesList, "Jerk")
        table.insert(emotesList, 1, "--")
        
        local SelectedEmote = Tabs.Fun:AddDropdown("SelectedEmote", {
            Title = "Select Emote", 
            Description = "Choose an emote to play", 
            Values = emotesList, 
            Multi = false, 
            Default = "--"
        })
        
        SelectedEmote:OnChanged(function(value) 
            Nexus.SafeCallback(function()
                if value and value ~= "" and value ~= "--" then 
                    if value == "Jerk" then
                        Fun.StartJerk()
                    else
                        Fun.PlayEmote(value) 
                    end
                    
                    task.wait(0.1)
                    SelectedEmote:SetValue("--")
                end 
            end)
        end)

        Tabs.Fun:AddButton({
            Title = "Stop Current Emote", 
            Description = "Stops the currently playing emote", 
            Callback = function()
                Nexus.SafeCallback(Fun.StopEmote)
            end
        })
    else
        Tabs.Fun:AddParagraph({
            Title = "Fun Tools",
            Content = "Additional fun tools for the game"
        })
        
        Tabs.Fun:AddButton({
            Title = "Jerk Tool", 
            Description = "Adds Jerk Off tool to your backpack", 
            Callback = function()
                Nexus.SafeCallback(Fun.StartJerk)
            end
        })
    end
    
    Tabs.Fun:AddSection("Game Utilities")
    
    Tabs.Fun:AddButton({
        Title = "Reset Character", 
        Description = "Kills your character to respawn", 
        Callback = function()
            Nexus.SafeCallback(Fun.ResetCharacter)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Rejoin Game", 
        Description = "Rejoins the current game server", 
        Callback = function()
            Nexus.SafeCallback(Fun.RejoinGame)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Server Hop", 
        Description = "Joins a new random server", 
        Callback = function()
            Nexus.SafeCallback(Fun.ServerHop)
        end
    })
    
    Tabs.Fun:AddSection("Quick Actions")
    
    Tabs.Fun:AddButton({
        Title = "Suicide", 
        Description = "Instantly kills your character", 
        Callback = function()
            Nexus.SafeCallback(Fun.Suicide)
        end
    })
    
    Tabs.Fun:AddSection("Miscellaneous")
    
    local SpinToggle = Tabs.Fun:AddToggle("SpinCharacter", {
        Title = "Spin Character", 
        Description = "Makes your character spin continuously", 
        Default = false
    })
    
    SpinToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleSpin(v)
        end)
    end)
end

function Fun.InitializeEmotesSystem()
    if not Nexus.Services.ReplicatedStorage:FindFirstChild("Emotes") then 
        return false 
    end
    
    Fun.EmotesFolder = Nexus.Services.ReplicatedStorage:WaitForChild("Emotes")
    Fun.AvailableEmotes = {}
    
    for _, folder in pairs(Fun.EmotesFolder:GetChildren()) do
        if folder:IsA("Folder") then 
            table.insert(Fun.AvailableEmotes, folder.Name) 
        end
    end
    
    if #Fun.AvailableEmotes == 0 then
        return false
    end
    
    table.sort(Fun.AvailableEmotes)
    return true
end

function Fun.PlayEmote(emoteName)
    Fun.StopEmote()
    
    local emoteFolder = Fun.EmotesFolder:FindFirstChild(emoteName)
    if not emoteFolder then 
        return false 
    end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    
    if not animationId then 
        return false 
    end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if not character or not humanoid then 
        return false 
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    Fun.CurrentAnimation = animation
    
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play(0.1, 1, 1)
    Fun.CurrentEmoteTrack = animationTrack
    
    if soundId and soundId ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Parent = head
            sound:Play()
            Fun.CurrentSound = sound
            
            sound.Ended:Connect(function()
                if sound == Fun.CurrentSound then 
                    sound:Destroy()
                    Fun.CurrentSound = nil 
                end
            end)
        end
    end
    
    humanoid.Died:Connect(function()
        Fun.StopEmote()
    end)
    
    return true
end

function Fun.StopEmote()
    if Fun.CurrentEmoteTrack then 
        Fun.CurrentEmoteTrack:Stop()
        Fun.CurrentEmoteTrack = nil 
    end
    
    if Fun.CurrentSound then 
        Fun.CurrentSound:Stop()
        Fun.CurrentSound:Destroy()
        Fun.CurrentSound = nil 
    end
    
    Fun.CurrentAnimation = nil
end

function Fun.StartJerk()
    Nexus.SafeCallback(function()
        local humanoid = Nexus.getHumanoid()
        local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        if not humanoid or not backpack then 
            return 
        end

        if Fun.JerkTool.tool and Fun.JerkTool.tool.Parent then
            if Fun.JerkTool.active then
                Fun.JerkTool.active = false
                if Fun.JerkTool.track then
                    Fun.JerkTool.track:Stop()
                    Fun.JerkTool.track = nil
                end
                return
            else
                Fun.JerkTool.active = true
                return
            end
        end

        local tool = Instance.new("Tool")
        tool.Name = "Jerk Off"
        tool.ToolTip = "Left Click to jerk"
        tool.RequiresHandle = false
        tool.Parent = backpack

        local humanoidRootPart = Nexus.getCharacter():WaitForChild("HumanoidRootPart")

        Fun.JerkTool.tool = tool
        Fun.JerkTool.active = true

        local function stopAnimation()
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
                Fun.JerkTool.track = nil
            end
            Fun.JerkTool.active = false
        end

        local function startAnimation()
            if not Fun.JerkTool.active then return end
            
            local currentHumanoid = Nexus.getHumanoid()
            if not currentHumanoid or currentHumanoid.Health <= 0 then return end
            
            local function isR15()
                local character = Nexus.getCharacter()
                if not character then return false end
                local hum = character:FindFirstChildOfClass("Humanoid")
                if not hum then return false end
                return hum.RigType == Enum.HumanoidRigType.R15
            end
            
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
                Fun.JerkTool.track = nil
            end
            
            local r15 = isR15()
            local anim = Instance.new("Animation")
            anim.AnimationId = not r15 and "rbxassetid://72042024" or "rbxassetid://698251653"
            Fun.JerkTool.track = currentHumanoid:LoadAnimation(anim)
            
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Play()
                Fun.JerkTool.track:AdjustSpeed(r15 and 0.7 or 0.65)
            end
        end

        tool.Activated:Connect(function()
            if Fun.JerkTool.active then
                stopAnimation()
            else
                Fun.JerkTool.active = true
                startAnimation()
            end
        end)

        tool.Unequipped:Connect(function()
            stopAnimation()
        end)

        local deathConnection = humanoid.Died:Connect(function()
            stopAnimation()
        end)

        local characterAddedConnection = Nexus.Player.CharacterAdded:Connect(function()
            task.wait(1)
            if Fun.JerkTool.tool and Fun.JerkTool.tool.Parent then
                stopAnimation()
            end
        end)

        local removalConnection
        removalConnection = tool.AncestryChanged:Connect(function(_, parent)
            if not parent then
                stopAnimation()
                if deathConnection then
                    deathConnection:Disconnect()
                end
                if removalConnection then
                    removalConnection:Disconnect()
                end
                if characterAddedConnection then
                    characterAddedConnection:Disconnect()
                end
                if tool == Fun.JerkTool.tool then
                    Fun.JerkTool.tool = nil
                end
            end
        end)

        tool:SetAttribute("DeathConnection", deathConnection)
        tool:SetAttribute("RemovalConnection", removalConnection)
        tool:SetAttribute("CharacterConnection", characterAddedConnection)
    end)
end

function Fun.StopJerk()
    if Fun.JerkTool.track then
        Fun.JerkTool.track:Stop()
        Fun.JerkTool.track = nil
    end
    
    if Fun.JerkTool.tool then
        local deathConnection = Fun.JerkTool.tool:GetAttribute("DeathConnection")
        local removalConnection = Fun.JerkTool.tool:GetAttribute("RemovalConnection")
        local characterConnection = Fun.JerkTool.tool:GetAttribute("CharacterConnection")
        
        if deathConnection and deathConnection.Connected then
            deathConnection:Disconnect()
        end
        if removalConnection and removalConnection.Connected then
            removalConnection:Disconnect()
        end
        if characterConnection and characterConnection.Connected then
            characterConnection:Disconnect()
        end
        
        Fun.JerkTool.tool:Destroy()
        Fun.JerkTool.tool = nil
    end
    
    Fun.JerkTool.active = false
end

function Fun.ResetCharacter()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if placeId and jobId then
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Nexus.Player)
    end
end

function Fun.ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    
    pcall(function()
        TeleportService:Teleport(placeId, Nexus.Player)
    end)
end

function Fun.Suicide()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end
end

function Fun.ToggleSpin(enabled)
    if enabled then
        Fun.StartSpin()
    else
        Fun.StopSpin()
    end
end

function Fun.StartSpin()
    local character = Nexus.getCharacter()
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
    end
    
    Fun.SpinConnection = Nexus.Services.RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
        else
            Fun.StopSpin()
        end
    end)
end

function Fun.StopSpin()
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
end

function Fun.Cleanup()
    Fun.StopEmote()
    Fun.StopJerk()
    Fun.StopSpin()
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.StopJerk()
    end
end

return Fun 
