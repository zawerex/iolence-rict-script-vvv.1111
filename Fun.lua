-- Fun Module - Various fun and utility functions for Violence District
local Nexus = _G.Nexus

local Fun = {
    CurrentEmoteTrack = nil,
    CurrentSound = nil,
    CurrentAnimation = nil,
    AvailableEmotes = {},
    EmotesFolder = nil,
    Connections = {},
    Tools = {},
    Effects = {}
}

function Fun.Init(nxs)
    Nexus = nxs
    
    local Tabs = Nexus.Tabs
    
    -- ========== WELCOME MESSAGE ==========
    Tabs.Fun:AddParagraph({
        Title = "Fun & Utilities",
        Content = "Various fun tools and utilities for Violence District"
    })
    
    -- ========== EMOTES SYSTEM ==========
    Tabs.Fun:AddSection("Emotes & Animations")
    
    local emotesInitialized = Fun.InitializeEmotesSystem()
    
    if emotesInitialized then
        local emotesList = {}
        for _, emote in ipairs(Fun.AvailableEmotes) do
            table.insert(emotesList, emote)
        end
        
        if #emotesList > 0 then
            local SelectedEmote = Tabs.Fun:AddDropdown("SelectedEmote", {
                Title = "Select Emote", 
                Description = "Choose an emote to play", 
                Values = emotesList, 
                Multi = false, 
                Default = ""
            })
            
            SelectedEmote:OnChanged(function(value) 
                Nexus.SafeCallback(function()
                    if value and value ~= "" then 
                        Fun.PlayEmote(value)
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
                Title = "No Emotes Found",
                Content = "Emote system not available in this game"
            })
        end
    else
        Tabs.Fun:AddParagraph({
            Title = "Emotes System",
            Content = "Emote system not initialized"
        })
    end
    
    -- ========== TOOLS SECTION ==========
    Tabs.Fun:AddSection("Special Tools")
    
    local ToolsDropdown = Tabs.Fun:AddDropdown("ToolsDropdown", {
        Title = "Select Tool", 
        Description = "Choose a tool to add", 
        Values = {"Jerk Tool", "Dance Tool", "PropHunt Tool"}, 
        Multi = false, 
        Default = ""
    })
    
    ToolsDropdown:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value == "Jerk Tool" then
                Fun.AddJerkTool()
            elseif value == "Dance Tool" then
                Fun.AddDanceTool()
            elseif value == "PropHunt Tool" then
                Fun.AddPropHuntTool()
            end
        end)
    end)
    
    -- ========== CHARACTER MODIFICATIONS ==========
    Tabs.Fun:AddSection("Character Modifications")
    
    local CharSizeSection = Tabs.Fun:AddSection("Character Size")
    
    local SizeSlider = Tabs.Fun:AddSlider("CharacterSize", {
        Title = "Size Multiplier", 
        Description = "Adjust character size (0.1x - 5x)",
        Default = 1,
        Min = 0.1,
        Max = 5,
        Rounding = 1,
        Callback = function(value)
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(value)
            end)
        end
    })
    
    local SizeButtonsContainer = Tabs.Fun:AddSection("Quick Size Presets")
    
    local SizeButtons = Tabs.Fun:AddButton({
        Title = "Giant Mode (3x)", 
        Description = "Makes your character huge", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(3)
                SizeSlider:SetValue(3)
            end)
        end
    })
    
    local SizeButtons2 = Tabs.Fun:AddButton({
        Title = "Tiny Mode (0.3x)", 
        Description = "Makes your character tiny", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(0.3)
                SizeSlider:SetValue(0.3)
            end)
        end
    })
    
    local SizeButtons3 = Tabs.Fun:AddButton({
        Title = "Reset Size", 
        Description = "Resets character to normal size", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(1)
                SizeSlider:SetValue(1)
            end)
        end
    })
    
    -- ========== VISUAL EFFECTS ==========
    Tabs.Fun:AddSection("Visual Effects")
    
    local SpinToggle = Tabs.Fun:AddToggle("SpinCharacter", {
        Title = "Spin Character", 
        Description = "Makes your character spin", 
        Default = false
    })
    
    SpinToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleSpin(v)
        end)
    end)
    
    local FloatToggle = Tabs.Fun:AddToggle("FloatCharacter", {
        Title = "Float Character", 
        Description = "Makes your character float", 
        Default = false
    })
    
    FloatToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleFloat(v)
        end)
    end)
    
    local RainbowButton = Tabs.Fun:AddButton({
        Title = "Rainbow Effect", 
        Description = "Cycles character colors", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleRainbow)
        end
    })
    
    local TrailToggle = Tabs.Fun:AddToggle("CharacterTrail", {
        Title = "Character Trail", 
        Description = "Adds trail behind character", 
        Default = false
    })
    
    TrailToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleTrail(v)
        end)
    end)
    
    -- ========== GAME UTILITIES ==========
    Tabs.Fun:AddSection("Game Utilities")
    
    local GameUtilsDropdown = Tabs.Fun:AddDropdown("GameUtilsDropdown", {
        Title = "Game Utilities", 
        Description = "Select a utility function", 
        Values = {
            "Reset Character",
            "Suicide", 
            "God Mode",
            "Drop All Items",
            "Rejoin Game",
            "Server Hop"
        }, 
        Multi = false, 
        Default = ""
    })
    
    GameUtilsDropdown:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value == "Reset Character" then
                Fun.ResetCharacter()
            elseif value == "Suicide" then
                Fun.Suicide()
            elseif value == "God Mode" then
                Fun.ToggleGodMode()
            elseif value == "Drop All Items" then
                Fun.DropAllItems()
            elseif value == "Rejoin Game" then
                Fun.RejoinGame()
            elseif value == "Server Hop" then
                Fun.ServerHop()
            end
        end)
    end)
    
    -- ========== VISUAL EFFECTS ACTIONS ==========
    Tabs.Fun:AddSection("Quick Effects")
    
    local EffectsDropdown = Tabs.Fun:AddDropdown("EffectsDropdown", {
        Title = "Quick Effects", 
        Description = "Select a visual effect", 
        Values = {
            "Fireworks",
            "Confetti",
            "Light Show"
        }, 
        Multi = false, 
        Default = ""
    })
    
    EffectsDropdown:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value == "Fireworks" then
                Fun.SpawnFireworks()
            elseif value == "Confetti" then
                Fun.SpawnConfetti()
            elseif value == "Light Show" then
                Fun.StartLightShow()
            end
        end)
    end)
    
    -- ========== TELEPORT FUNCTIONS ==========
    Tabs.Fun:AddSection("Teleport Functions")
    
    local TeleportDropdown = Tabs.Fun:AddDropdown("TeleportDropdown", {
        Title = "Teleport Locations", 
        Description = "Select where to teleport", 
        Values = {
            "To Spawn",
            "To Map Center",
            "To Highest Point"
        }, 
        Multi = false, 
        Default = ""
    })
    
    TeleportDropdown:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value == "To Spawn" then
                Fun.TeleportToSpawn()
            elseif value == "To Map Center" then
                Fun.TeleportToMapCenter()
            elseif value == "To Highest Point" then
                Fun.TeleportToHighestPoint()
            end
        end)
    end)
    
    -- ========== MISC FUNCTIONS ==========
    Tabs.Fun:AddSection("Miscellaneous")
    
    local MiscDropdown = Tabs.Fun:AddDropdown("MiscDropdown", {
        Title = "Misc Functions", 
        Description = "Select a miscellaneous function", 
        Values = {
            "Sit Everywhere",
            "Anti-AFK",
            "Invisible Player"
        }, 
        Multi = false, 
        Default = ""
    })
    
    MiscDropdown:OnChanged(function(value)
        Nexus.SafeCallback(function()
            if value == "Sit Everywhere" then
                Fun.ToggleSitEverywhere()
            elseif value == "Anti-AFK" then
                Fun.ToggleAntiAFK()
            elseif value == "Invisible Player" then
                Fun.ToggleInvisibility()
            end
        end)
    end)

    print("✓ Fun module initialized")
end

-- ========== EMOTES FUNCTIONS ==========

function Fun.InitializeEmotesSystem()
    if not Nexus.Services.ReplicatedStorage:FindFirstChild("Emotes") then 
        print("Emotes system not found in ReplicatedStorage")
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
        print("No emotes found in Emotes folder")
        return false
    end
    
    table.sort(Fun.AvailableEmotes)
    print("Found " .. #Fun.AvailableEmotes .. " emotes")
    return true
end

function Fun.PlayEmote(emoteName)
    Fun.StopEmote()
    
    local emoteFolder = Fun.EmotesFolder:FindFirstChild(emoteName)
    if not emoteFolder then 
        Nexus.Fluent:Notify({
            Title = "Emote Error",
            Content = "Emote not found: " .. emoteName,
            Duration = 3
        })
        return false 
    end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    
    if not animationId then 
        Nexus.Fluent:Notify({
            Title = "Emote Error",
            Content = "No animation found for emote",
            Duration = 3
        })
        return false 
    end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if not character or not humanoid then 
        Nexus.Fluent:Notify({
            Title = "Emote Error",
            Content = "Character not found",
            Duration = 3
        })
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
    
    Nexus.Fluent:Notify({
        Title = "Emote",
        Content = "Playing: " .. emoteName,
        Duration = 2
    })
    
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

-- ========== TOOL FUNCTIONS ==========

function Fun.AddJerkTool()
    local humanoid = Nexus.getHumanoid()
    local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end
    
    local existing = backpack:FindFirstChild("Jerk Tool")
    if existing then existing:Destroy() end
    
    local tool = Instance.new("Tool")
    tool.Name = "Jerk Tool"
    tool.ToolTip = "Equip to use"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    local active = false
    
    tool.Equipped:Connect(function()
        active = true
    end)
    
    tool.Unequipped:Connect(function()
        active = false
    end)
    
    Nexus.Fluent:Notify({
        Title = "Jerk Tool",
        Content = "Tool added to backpack",
        Duration = 3
    })
end

function Fun.AddDanceTool()
    local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
    if not backpack then return end
    
    local existing = backpack:FindFirstChild("Dance Tool")
    if existing then existing:Destroy() end
    
    local tool = Instance.new("Tool")
    tool.Name = "Dance Tool"
    tool.ToolTip = "Click to dance"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    Nexus.Fluent:Notify({
        Title = "Dance Tool",
        Content = "Dance tool added to backpack",
        Duration = 3
    })
end

function Fun.AddPropHuntTool()
    local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
    if not backpack then return end
    
    local tool = Instance.new("Tool")
    tool.Name = "Prop Hunt Tool"
    tool.ToolTip = "Become various props"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    Nexus.Fluent:Notify({
        Title = "Prop Hunt Tool",
        Content = "Tool added to backpack",
        Duration = 3
    })
end

-- ========== CHARACTER MODIFICATION FUNCTIONS ==========

function Fun.SetCharacterSize(scale)
    local character = Nexus.getCharacter()
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scale
        end
    end
    
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.HipHeight = humanoid.HipHeight * scale
    end
    
    Nexus.Fluent:Notify({
        Title = "Character Size",
        Content = "Size set to: " .. scale .. "x",
        Duration = 2
    })
end

function Fun.ToggleSpin(enabled)
    if enabled then
        Fun.StartSpin()
    else
        Fun.StopSpin()
    end
end

function Fun.StartSpin()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    if Fun.Connections.spin then
        Fun.Connections.spin:Disconnect()
    end
    
    Fun.Connections.spin = Nexus.Services.RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
        else
            Fun.StopSpin()
        end
    end)
end

function Fun.StopSpin()
    if Fun.Connections.spin then
        Fun.Connections.spin:Disconnect()
        Fun.Connections.spin = nil
    end
end

function Fun.ToggleFloat(enabled)
    if enabled then
        Fun.StartFloat()
    else
        Fun.StopFloat()
    end
end

function Fun.StartFloat()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    if Fun.Connections.float then
        Fun.Connections.float:Disconnect()
    end
    
    Fun.Connections.float = Nexus.Services.RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = rootPart.CFrame + Vector3.new(0, math.sin(tick()) * 0.5, 0)
        else
            Fun.StopFloat()
        end
    end)
end

function Fun.StopFloat()
    if Fun.Connections.float then
        Fun.Connections.float:Disconnect()
        Fun.Connections.float = nil
    end
end

function Fun.ToggleRainbow()
    if Fun.Connections.rainbow then
        Fun.Connections.rainbow:Disconnect()
        Fun.Connections.rainbow = nil
        Nexus.Fluent:Notify({
            Title = "Rainbow",
            Content = "Rainbow effect stopped",
            Duration = 2
        })
    else
        Fun.Connections.rainbow = Nexus.Services.RunService.Heartbeat:Connect(function()
            local character = Nexus.getCharacter()
            if not character then return end
            
            local hue = (tick() * 60) % 360
            local color = Color3.fromHSV(hue / 360, 1, 1)
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
        end)
        Nexus.Fluent:Notify({
            Title = "Rainbow",
            Content = "Rainbow effect started",
            Duration = 2
        })
    end
end

function Fun.ToggleTrail(enabled)
    if enabled then
        Fun.AddTrail()
    else
        Fun.RemoveTrail()
    end
end

function Fun.AddTrail()
    local character = Nexus.getCharacter()
    if not character then return end
    
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = Instance.new("Attachment")
    trail.Attachment1 = Instance.new("Attachment")
    trail.Attachment0.Parent = rootPart
    trail.Attachment1.Parent = rootPart
    trail.Attachment1.Position = Vector3.new(0, -2, 0)
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255))
    trail.Lifetime = 1
    trail.Parent = rootPart
    
    Fun.Effects.trail = trail
end

function Fun.RemoveTrail()
    if Fun.Effects.trail then
        Fun.Effects.trail:Destroy()
        Fun.Effects.trail = nil
    end
end

-- ========== GAME UTILITY FUNCTIONS ==========

function Fun.ResetCharacter()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.Health = 0
        Nexus.Fluent:Notify({
            Title = "Reset",
            Content = "Character reset initiated",
            Duration = 2
        })
    end
end

function Fun.Suicide()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.Health = 0
        Nexus.Fluent:Notify({
            Title = "Suicide",
            Content = "Character killed",
            Duration = 2
        })
    end
end

function Fun.ToggleGodMode()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        if humanoid.MaxHealth == math.huge then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            Nexus.Fluent:Notify({
                Title = "God Mode",
                Content = "God mode disabled",
                Duration = 2
            })
        else
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            Nexus.Fluent:Notify({
                Title = "God Mode",
                Content = "God mode enabled",
                Duration = 2
            })
        end
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Nexus.Player)
    
    Nexus.Fluent:Notify({
        Title = "Rejoining",
        Content = "Rejoining game...",
        Duration = 3
    })
end

function Fun.ServerHop()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Nexus.Player)
    
    Nexus.Fluent:Notify({
        Title = "Server Hop",
        Content = "Joining new server...",
        Duration = 3
    })
end

function Fun.DropAllItems()
    local character = Nexus.getCharacter()
    if character then
        local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = character
                end
            end
            Nexus.Fluent:Notify({
                Title = "Items",
                Content = "All items dropped",
                Duration = 2
            })
        end
    end
end

-- ========== VISUAL EFFECTS FUNCTIONS ==========

function Fun.SpawnFireworks()
    for i = 1, 5 do
        task.spawn(function()
            task.wait(math.random() * 1)
            
            local rootPart = Nexus.getRootPart()
            if not rootPart then return end
            
            local firework = Instance.new("Part")
            firework.Size = Vector3.new(0.2, 0.2, 0.2)
            firework.Position = rootPart.Position + Vector3.new(
                math.random(-5, 5),
                math.random(5, 10),
                math.random(-5, 5)
            )
            firework.Color = Color3.fromHSV(math.random(), 1, 1)
            firework.Material = Enum.Material.Neon
            firework.Anchored = true
            firework.CanCollide = false
            firework.Parent = Nexus.Services.Workspace
            
            task.wait(0.5)
            firework:Destroy()
        end)
    end
    
    Nexus.Fluent:Notify({
        Title = "Fireworks",
        Content = "Fireworks spawned!",
        Duration = 2
    })
end

function Fun.SpawnConfetti()
    for i = 1, 20 do
        local confetti = Instance.new("Part")
        confetti.Size = Vector3.new(0.3, 0.3, 0.3)
        confetti.Color = Color3.fromHSV(math.random(), 1, 1)
        confetti.Material = Enum.Material.Plastic
        confetti.Parent = Nexus.Services.Workspace
        
        task.delay(2, function()
            confetti:Destroy()
        end)
    end
    
    Nexus.Fluent:Notify({
        Title = "Confetti",
        Content = "Confetti spawned!",
        Duration = 2
    })
end

function Fun.StartLightShow()
    if Fun.Connections.lightShow then
        Fun.Connections.lightShow:Disconnect()
        Fun.Connections.lightShow = nil
        Nexus.Fluent:Notify({
            Title = "Light Show",
            Content = "Light show stopped",
            Duration = 2
        })
    else
        Fun.Connections.lightShow = Nexus.Services.RunService.Heartbeat:Connect(function()
            Nexus.Services.Lighting.Ambient = Color3.fromHSV((tick() * 30) % 360 / 360, 1, 1)
        end)
        Nexus.Fluent:Notify({
            Title = "Light Show",
            Content = "Light show started",
            Duration = 2
        })
    end
end

-- ========== TELEPORT FUNCTIONS ==========

function Fun.TeleportToSpawn()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(0, 5, 0)
    Nexus.Fluent:Notify({
        Title = "Teleport",
        Content = "Teleported to spawn",
        Duration = 2
    })
end

function Fun.TeleportToMapCenter()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(0, 50, 0)
    Nexus.Fluent:Notify({
        Title = "Teleport",
        Content = "Teleported to map center",
        Duration = 2
    })
end

function Fun.TeleportToHighestPoint()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(0, 100, 0)
    Nexus.Fluent:Notify({
        Title = "Teleport",
        Content = "Teleported to high point",
        Duration = 2
    })
end

-- ========== MISC FUNCTIONS ==========

function Fun.ToggleSitEverywhere()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.Sit = true
        Nexus.Fluent:Notify({
            Title = "Sit Everywhere",
            Content = "Sitting enabled",
            Duration = 2
        })
    end
end

function Fun.ToggleAntiAFK()
    if Fun.Connections.antiAFK then
        Fun.Connections.antiAFK:Disconnect()
        Fun.Connections.antiAFK = nil
        Nexus.Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK disabled",
            Duration = 2
        })
    else
        Fun.Connections.antiAFK = Nexus.Services.RunService.Heartbeat:Connect(function()
            Nexus.Services.VirtualInputManager:SendKeyEvent(true, "W", false, nil)
            task.wait(0.1)
            Nexus.Services.VirtualInputManager:SendKeyEvent(false, "W", false, nil)
        end)
        Nexus.Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK enabled",
            Duration = 2
        })
    end
end

function Fun.ToggleInvisibility()
    local character = Nexus.getCharacter()
    if not character then return end
    
    local isInvisible = false
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency == 1 then
            isInvisible = true
            break
        end
    end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = isInvisible and 0 or 1
        end
    end
    
    Nexus.Fluent:Notify({
        Title = "Invisibility",
        Content = isInvisible and "Visible again" or "Now invisible",
        Duration = 2
    })
end

-- ========== CLEANUP ==========

function Fun.Cleanup()
    Fun.StopEmote()
    Fun.StopSpin()
    Fun.StopFloat()
    Fun.RemoveTrail()
    
    for name, connection in pairs(Fun.Connections) do
        Nexus.safeDisconnect(connection)
        Fun.Connections[name] = nil
    end
    
    for name, tool in pairs(Fun.Tools) do
        if tool and tool.Parent then
            tool:Destroy()
        end
        Fun.Tools[name] = nil
    end
    
    for name, effect in pairs(Fun.Effects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
        Fun.Effects[name] = nil
    end
    
    print("Fun module cleaned up")
end

return Fun
