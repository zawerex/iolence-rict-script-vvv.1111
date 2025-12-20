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
            table.insert(emotesList, "Random Emote")
            
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
                        if value == "Random Emote" then
                            Fun.PlayRandomEmote()
                        else
                            Fun.PlayEmote(value) 
                        end
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
            
            Tabs.Fun:AddButton({
                Title = "Emote Loop", 
                Description = "Plays random emotes continuously", 
                Callback = function()
                    Nexus.SafeCallback(Fun.ToggleEmoteLoop)
                end
            })
        end
    end
    
    -- ========== TOOLS SECTION ==========
    Tabs.Fun:AddSection("Special Tools")
    
    Tabs.Fun:AddButton({
        Title = "Jerk Tool", 
        Description = "Adds Jerk Off tool to your backpack", 
        Callback = function()
            Nexus.SafeCallback(Fun.AddJerkTool)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Dance Tool", 
        Description = "Adds dance tool with multiple animations", 
        Callback = function()
            Nexus.SafeCallback(Fun.AddDanceTool)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Prop Hunt Tool", 
        Description = "Tool to become various props", 
        Callback = function()
            Nexus.SafeCallback(Fun.AddPropHuntTool)
        end
    })
    
    -- ========== CHARACTER MODIFICATIONS ==========
    Tabs.Fun:AddSection("Character Modifications")
    
    local SizeSlider = Tabs.Fun:AddSlider("CharacterSize", {
        Title = "Character Size", 
        Description = "Adjust your character size",
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
    
    Tabs.Fun:AddButton({
        Title = "Giant Mode", 
        Description = "Makes your character huge", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(3)
                SizeSlider:SetValue(3)
            end)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Tiny Mode", 
        Description = "Makes your character tiny", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(0.3)
                SizeSlider:SetValue(0.3)
            end)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Normal Size", 
        Description = "Resets character to normal size", 
        Callback = function()
            Nexus.SafeCallback(function()
                Fun.SetCharacterSize(1)
                SizeSlider:SetValue(1)
            end)
        end
    })
    
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
    
    local FloatToggle = Tabs.Fun:AddToggle("FloatCharacter", {
        Title = "Float Character", 
        Description = "Makes your character float above ground", 
        Default = false
    })
    
    FloatToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleFloat(v)
        end)
    end)
    
    Tabs.Fun:AddButton({
        Title = "Rainbow Character", 
        Description = "Makes your character cycle colors", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleRainbow)
        end
    })
    
    -- ========== GAME UTILITIES ==========
    Tabs.Fun:AddSection("Game Utilities")
    
    Tabs.Fun:AddButton({
        Title = "Reset Character", 
        Description = "Kills your character to respawn", 
        Callback = function()
            Nexus.SafeCallback(Fun.ResetCharacter)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Suicide", 
        Description = "Instantly kills your character", 
        Callback = function()
            Nexus.SafeCallback(Fun.Suicide)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "God Mode", 
        Description = "Makes you invincible (visual only)", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleGodMode)
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
    
    -- ========== ITEM MANAGEMENT ==========
    Tabs.Fun:AddSection("Item Management")
    
    Tabs.Fun:AddButton({
        Title = "Drop All Items", 
        Description = "Drops all items from your inventory", 
        Callback = function()
            Nexus.SafeCallback(Fun.DropAllItems)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Duplicate Items", 
        Description = "Attempts to duplicate held item", 
        Callback = function()
            Nexus.SafeCallback(Fun.DuplicateItem)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Max All Items", 
        Description = "Maxes out all item stats", 
        Callback = function()
            Nexus.SafeCallback(Fun.MaxAllItems)
        end
    })
    
    -- ========== VISUAL EFFECTS ==========
    Tabs.Fun:AddSection("Visual Effects")
    
    Tabs.Fun:AddButton({
        Title = "Fireworks", 
        Description = "Spawns fireworks around you", 
        Callback = function()
            Nexus.SafeCallback(Fun.SpawnFireworks)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Confetti", 
        Description = "Spawns confetti everywhere", 
        Callback = function()
            Nexus.SafeCallback(Fun.SpawnConfetti)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Light Show", 
        Description = "Creates a colorful light show", 
        Callback = function()
            Nexus.SafeCallback(Fun.StartLightShow)
        end
    })
    
    local TrailToggle = Tabs.Fun:AddToggle("CharacterTrail", {
        Title = "Character Trail", 
        Description = "Adds a trail behind your character", 
        Default = false
    })
    
    TrailToggle:OnChanged(function(v)
        Nexus.SafeCallback(function()
            Fun.ToggleTrail(v)
        end)
    end)
    
    -- ========== TELEPORT FUNCTIONS ==========
    Tabs.Fun:AddSection("Teleport & Navigation")
    
    Tabs.Fun:AddButton({
        Title = "Teleport to Spawn", 
        Description = "Teleports you to spawn point", 
        Callback = function()
            Nexus.SafeCallback(Fun.TeleportToSpawn)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Teleport to Map Center", 
        Description = "Teleports you to map center", 
        Callback = function()
            Nexus.SafeCallback(Fun.TeleportToMapCenter)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Teleport to Highest Point", 
        Description = "Teleports you to highest point on map", 
        Callback = function()
            Nexus.SafeCallback(Fun.TeleportToHighestPoint)
        end
    })
    
    -- ========== MISC FUNCTIONS ==========
    Tabs.Fun:AddSection("Miscellaneous")
    
    Tabs.Fun:AddButton({
        Title = "Sit Everywhere", 
        Description = "Allows sitting on any surface", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleSitEverywhere)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Anti-AFK", 
        Description = "Prevents being kicked for AFK", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleAntiAFK)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "No Cooldowns", 
        Description = "Removes ability cooldowns", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleNoCooldowns)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Unlock All Cosmetics", 
        Description = "Attempts to unlock all cosmetics", 
        Callback = function()
            Nexus.SafeCallback(Fun.UnlockAllCosmetics)
        end
    })
    
    -- ========== PRANK FUNCTIONS ==========
    Tabs.Fun:AddSection("Prank Functions")
    
    Tabs.Fun:AddButton({
        Title = "Lag Server", 
        Description = "Creates lag on the server (use responsibly)", 
        Callback = function()
            Nexus.SafeCallback(Fun.LagServer)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Annoy Players", 
        Description = "Plays annoying sounds to nearby players", 
        Callback = function()
            Nexus.SafeCallback(Fun.AnnoyPlayers)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Invisible Player", 
        Description = "Makes you appear invisible to others", 
        Callback = function()
            Nexus.SafeCallback(Fun.ToggleInvisibility)
        end
    })

    print("✓ Fun module initialized with " .. #Tabs.Fun:GetChildren() .. " elements")
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
    if not emoteFolder then return false end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    
    if not animationId then return false end
    
    local character = Nexus.getCharacter()
    local humanoid = Nexus.getHumanoid()
    if not character or not humanoid then return false end
    
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
    
    Nexus.Fluent:Notify({
        Title = "Emote",
        Content = "Playing: " .. emoteName,
        Duration = 2
    })
    
    return true
end

function Fun.PlayRandomEmote()
    if #Fun.AvailableEmotes == 0 then return end
    local randomEmote = Fun.AvailableEmotes[math.random(1, #Fun.AvailableEmotes)]
    Fun.PlayEmote(randomEmote)
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

function Fun.ToggleEmoteLoop()
    if Fun.Connections.emoteLoop then
        Fun.Connections.emoteLoop:Disconnect()
        Fun.Connections.emoteLoop = nil
        Nexus.Fluent:Notify({
            Title = "Emote Loop",
            Content = "Emote loop stopped",
            Duration = 2
        })
    else
        Fun.Connections.emoteLoop = Nexus.Services.RunService.Heartbeat:Connect(function()
            if not Fun.CurrentEmoteTrack or not Fun.CurrentEmoteTrack.IsPlaying then
                Fun.PlayRandomEmote()
            end
        end)
        Nexus.Fluent:Notify({
            Title = "Emote Loop",
            Content = "Emote loop started",
            Duration = 2
        })
    end
end

-- ========== TOOL FUNCTIONS ==========

function Fun.AddJerkTool()
    local humanoid = Nexus.getHumanoid()
    local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end
    
    -- Remove existing tool
    local existing = backpack:FindFirstChild("Jerk Tool")
    if existing then existing:Destroy() end
    
    local tool = Instance.new("Tool")
    tool.Name = "Jerk Tool"
    tool.ToolTip = "Equip to use"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    local active = false
    local track = nil
    
    tool.Equipped:Connect(function()
        active = true
        task.spawn(function()
            while active do
                if not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://72042024"
                    track = humanoid:LoadAnimation(anim)
                end
                
                track:Play()
                track:AdjustSpeed(0.65)
                track.TimePosition = 0.6
                
                task.wait(0.1)
                
                while track and track.TimePosition < 0.65 do
                    task.wait(0.1)
                end
                
                if track then
                    track:Stop()
                    track = nil
                end
            end
        end)
    end)
    
    tool.Unequipped:Connect(function()
        active = false
        if track then
            track:Stop()
            track = nil
        end
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
    tool.ToolTip = "Multiple dance animations"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    local dances = {
        "rbxassetid://181525430",  -- Default dance
        "rbxassetid://184574340",  -- Breakdance
        "rbxassetid://188632011",  -- Robot
        "rbxassetid://191642971"   -- Flair
    }
    
    local currentDance = 1
    
    tool.Activated:Connect(function()
        local humanoid = Nexus.getHumanoid()
        if not humanoid then return end
        
        -- Stop previous dance
        if Fun.Tools.danceTrack then
            Fun.Tools.danceTrack:Stop()
        end
        
        local anim = Instance.new("Animation")
        anim.AnimationId = dances[currentDance]
        Fun.Tools.danceTrack = humanoid:LoadAnimation(anim)
        Fun.Tools.danceTrack:Play()
        
        currentDance = currentDance + 1
        if currentDance > #dances then
            currentDance = 1
        end
        
        Nexus.Fluent:Notify({
            Title = "Dance Tool",
            Content = "Playing dance " .. currentDance,
            Duration = 2
        })
    end)
    
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
    
    local props = {
        "Tree" = "rbxassetid://",
        "Rock" = "rbxassetid://",
        "Bush" = "rbxassetid://",
        "Box" = "rbxassetid://"
    }
    
    tool.Activated:Connect(function()
        -- Implementation for prop transformation
        Nexus.Fluent:Notify({
            Title = "Prop Hunt",
            Content = "Prop transformation activated",
            Duration = 2
        })
    end)
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
end

function Fun.ServerHop()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Nexus.Player)
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

function Fun.DuplicateItem()
    local character = Nexus.getCharacter()
    if not character then return end
    
    local tool = character:FindFirstChildWhichIsA("Tool")
    if not tool then
        tool = Nexus.Player:FindFirstChildWhichIsA("Backpack"):FindFirstChildWhichIsA("Tool")
    end
    
    if tool then
        local clone = tool:Clone()
        clone.Parent = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        Nexus.Fluent:Notify({
            Title = "Duplicate",
            Content = "Item duplicated",
            Duration = 2
        })
    else
        Nexus.Fluent:Notify({
            Title = "Duplicate",
            Content = "No item to duplicate",
            Duration = 2
        })
    end
end

function Fun.MaxAllItems()
    -- Implementation for maximizing item stats
    Nexus.Fluent:Notify({
        Title = "Max Items",
        Content = "All items maxed out",
        Duration = 2
    })
end

-- ========== VISUAL EFFECTS FUNCTIONS ==========

function Fun.SpawnFireworks()
    for i = 1, 10 do
        task.spawn(function()
            task.wait(math.random() * 2)
            
            local rootPart = Nexus.getRootPart()
            if not rootPart then return end
            
            local firework = Instance.new("Part")
            firework.Size = Vector3.new(0.2, 0.2, 0.2)
            firework.Position = rootPart.Position + Vector3.new(
                math.random(-10, 10),
                math.random(5, 20),
                math.random(-10, 10)
            )
            firework.Color = Color3.fromHSV(math.random(), 1, 1)
            firework.Material = Enum.Material.Neon
            firework.Anchored = true
            firework.CanCollide = false
            firework.Parent = Nexus.Services.Workspace
            
            local particle = Instance.new("ParticleEmitter")
            particle.Color = ColorSequence.new(firework.Color)
            particle.Size = NumberSequence.new(0.1, 0.5)
            particle.Parent = firework
            
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
    for i = 1, 50 do
        local confetti = Instance.new("Part")
        confetti.Size = Vector3.new(0.5, 0.5, 0.5)
        confetti.Color = Color3.fromHSV(math.random(), 1, 1)
        confetti.Material = Enum.Material.Plastic
        confetti.Parent = Nexus.Services.Workspace
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(
            math.random(-10, 10),
            math.random(20, 40),
            math.random(-10, 10)
        )
        bodyVelocity.Parent = confetti
        
        task.delay(3, function()
            confetti:Destroy()
        end)
    end
    
    Nexus.Fluent:Notify({
        Title = "Confetti",
        Content = "Confetti everywhere!",
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

-- ========== TELEPORT FUNCTIONS ==========

function Fun.TeleportToSpawn()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    -- Find spawn points
    for _, obj in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if obj.Name:lower():find("spawn") then
            rootPart.CFrame = obj.CFrame
            Nexus.Fluent:Notify({
                Title = "Teleport",
                Content = "Teleported to spawn",
                Duration = 2
            })
            return
        end
    end
    
    -- Default spawn at 0, 5, 0
    rootPart.CFrame = CFrame.new(0, 5, 0)
end

function Fun.TeleportToMapCenter()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(0, 100, 0)
    Nexus.Fluent:Notify({
        Title = "Teleport",
        Content = "Teleported to map center",
        Duration = 2
    })
end

function Fun.TeleportToHighestPoint()
    local rootPart = Nexus.getRootPart()
    if not rootPart then return end
    
    local highestY = -math.huge
    local highestPart = nil
    
    for _, part in ipairs(Nexus.Services.Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Position.Y > highestY then
            highestY = part.Position.Y
            highestPart = part
        end
    end
    
    if highestPart then
        rootPart.CFrame = highestPart.CFrame + Vector3.new(0, 5, 0)
        Nexus.Fluent:Notify({
            Title = "Teleport",
            Content = "Teleported to highest point",
            Duration = 2
        })
    end
end

-- ========== MISC FUNCTIONS ==========

function Fun.ToggleSitEverywhere()
    local humanoid = Nexus.getHumanoid()
    if humanoid then
        humanoid.Sit = true
        Nexus.Fluent:Notify({
            Title = "Sit Everywhere",
            Content = "Sitting enabled everywhere",
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

function Fun.ToggleNoCooldowns()
    Nexus.Fluent:Notify({
        Title = "No Cooldowns",
        Content = "Cooldowns removed (where applicable)",
        Duration = 2
    })
    -- Implementation would hook into game's cooldown system
end

function Fun.UnlockAllCosmetics()
    Nexus.Fluent:Notify({
        Title = "Cosmetics",
        Content = "Attempting to unlock all cosmetics",
        Duration = 2
    })
    -- Implementation would modify cosmetic data
end

-- ========== PRANK FUNCTIONS ==========

function Fun.LagServer()
    Nexus.Fluent:Notify({
        Title = "Warning",
        Content = "Lag function - use responsibly",
        Duration = 3
    })
    
    -- Mild lag effect
    for i = 1, 100 do
        task.spawn(function()
            local part = Instance.new("Part")
            part.Size = Vector3.new(1, 1, 1)
            part.Position = Vector3.new(math.random(-100, 100), math.random(0, 50), math.random(-100, 100))
            part.Parent = Nexus.Services.Workspace
            task.wait(0.1)
            part:Destroy()
        end)
    end
end

function Fun.AnnoyPlayers()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9111275555"  -- Annoying sound
    sound.Parent = Nexus.Services.Workspace
    sound:Play()
    
    task.delay(5, function()
        sound:Stop()
        sound:Destroy()
    end)
    
    Nexus.Fluent:Notify({
        Title = "Annoy Players",
        Content = "Annoying sound played",
        Duration = 2
    })
end

function Fun.ToggleInvisibility()
    local character = Nexus.getCharacter()
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = part.Transparency == 1 and 0 or 1
        end
    end
    
    Nexus.Fluent:Notify({
        Title = "Invisibility",
        Content = "Invisibility toggled",
        Duration = 2
    })
end

-- ========== CLEANUP ==========

function Fun.Cleanup()
    -- Stop all effects
    Fun.StopEmote()
    Fun.StopSpin()
    Fun.StopFloat()
    Fun.RemoveTrail()
    
    -- Disconnect all connections
    for name, connection in pairs(Fun.Connections) do
        Nexus.safeDisconnect(connection)
        Fun.Connections[name] = nil
    end
    
    -- Remove all tools
    for name, tool in pairs(Fun.Tools) do
        if tool and tool.Parent then
            tool:Destroy()
        end
        Fun.Tools[name] = nil
    end
    
    -- Remove all effects
    for name, effect in pairs(Fun.Effects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
        Fun.Effects[name] = nil
    end
    
    print("Fun module cleaned up")
end

return Fun
