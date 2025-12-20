-- Fun Module - Emotes and other fun functions for Violence District
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
    
    -- ========== EMOTES SYSTEM ==========
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
                    if value == "Jerk" then
                        Fun.StartJerk()
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
    
    -- ========== QUICK ACTIONS ==========
    Tabs.Fun:AddSection("Quick Actions")
    
    Tabs.Fun:AddButton({
        Title = "Suicide", 
        Description = "Instantly kills your character", 
        Callback = function()
            Nexus.SafeCallback(Fun.Suicide)
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Drop All Items", 
        Description = "Drops all items from your inventory", 
        Callback = function()
            Nexus.SafeCallback(Fun.DropAllItems)
        end
    })
    
    -- ========== MISC FUNCTIONS ==========
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

    print("✓ Fun module initialized")
end

-- ========== EMOTES FUNCTIONS ==========

function Fun.InitializeEmotesSystem()
    -- Проверяем наличие системы эмоций в игре
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
    -- Останавливаем предыдущий эмот
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
    
    -- Создаем анимацию
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    Fun.CurrentAnimation = animation
    
    -- Загружаем и воспроизводим трек
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play(0.1, 1, 1)
    Fun.CurrentEmoteTrack = animationTrack
    
    -- Воспроизводим звук если есть
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
    
    -- Автоматическая остановка при смерти
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

-- ========== JERK FUNCTION ==========

function Fun.StartJerk()
    Nexus.SafeCallback(function()
        local humanoid = Nexus.getHumanoid()
        local backpack = Nexus.Player:FindFirstChildWhichIsA("Backpack")
        if not humanoid or not backpack then 
            Nexus.Fluent:Notify({
                Title = "Error",
                Content = "Character or backpack not found",
                Duration = 3
            })
            return 
        end

        -- Удаляем старый инструмент если есть
        if Fun.JerkTool.tool then
            Fun.StopJerk()
        end

        -- Создаем новый инструмент
        local tool = Instance.new("Tool")
        tool.Name = "Jerk Off"
        tool.ToolTip = "Use tool to jerk off"
        tool.RequiresHandle = false
        tool.Parent = backpack

        Fun.JerkTool.tool = tool
        Fun.JerkTool.active = true

        -- Функция для остановки
        local function stopTomfoolery()
            Fun.JerkTool.active = false
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
                Fun.JerkTool.track = nil
            end
        end

        -- Подключаем события
        tool.Equipped:Connect(function() 
            Fun.JerkTool.active = true 
        end)
        
        tool.Unequipped:Connect(stopTomfoolery)
        
        humanoid.Died:Connect(stopTomfoolery)

        -- Определяем тип рига (R6 или R15)
        local function isR15()
            local character = Nexus.getCharacter()
            if not character then return false end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum then return false end
            return hum.RigType == Enum.HumanoidRigType.R15
        end
        
        -- Основной цикл
        task.spawn(function()
            while task.wait() do
                if not Fun.JerkTool.active then continue end
                
                local r15 = isR15()
                
                if not Fun.JerkTool.track then
                    local anim = Instance.new("Animation")
                    -- Разные анимации для R6 и R15
                    anim.AnimationId = not r15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                    Fun.JerkTool.track = humanoid:LoadAnimation(anim)
                end

                Fun.JerkTool.track:Play()
                Fun.JerkTool.track:AdjustSpeed(r15 and 0.7 or 0.65)
                Fun.JerkTool.track.TimePosition = 0.6
                
                task.wait(0.1)
                
                while Fun.JerkTool.track and Fun.JerkTool.track.TimePosition < (not r15 and 0.65 or 0.7) do 
                    task.wait(0.1) 
                end
                
                if Fun.JerkTool.track then
                    Fun.JerkTool.track:Stop()
                    Fun.JerkTool.track = nil
                end
            end
        end)
        
        Nexus.Fluent:Notify({
            Title = "Jerk Tool",
            Content = "Tool added to backpack. Equip to use.",
            Duration = 3
        })
    end)
end

function Fun.StopJerk()
    if Fun.JerkTool.track then
        Fun.JerkTool.track:Stop()
        Fun.JerkTool.track = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.JerkTool.tool:Destroy()
        Fun.JerkTool.tool = nil
    end
    
    Fun.JerkTool.active = false
    
    Nexus.Fluent:Notify({
        Title = "Jerk Tool",
        Content = "Tool removed",
        Duration = 2
    })
end

-- ========== GAME UTILITY FUNCTIONS ==========

function Fun.ResetCharacter()
    local character = Nexus.getCharacter()
    if character then
        local humanoid = Nexus.getHumanoid()
        if humanoid then
            humanoid.Health = 0
            Nexus.Fluent:Notify({
                Title = "Reset",
                Content = "Character reset initiated",
                Duration = 2
            })
        else
            Nexus.Fluent:Notify({
                Title = "Error",
                Content = "Humanoid not found",
                Duration = 2
            })
        end
    else
        Nexus.Fluent:Notify({
            Title = "Error",
            Content = "Character not found",
            Duration = 2
        })
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local jobId = game.JobId
    
    if placeId and jobId then
        Nexus.Fluent:Notify({
            Title = "Rejoining",
            Content = "Rejoining game...",
            Duration = 3
        })
        
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Nexus.Player)
    else
        Nexus.Fluent:Notify({
            Title = "Error",
            Content = "Could not get game information",
            Duration = 3
        })
    end
end

function Fun.ServerHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    
    Nexus.Fluent:Notify({
        Title = "Server Hop",
        Content = "Looking for new server...",
        Duration = 3
    })
    
    -- Используем стандартный метод поиска серверов
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
            Nexus.Fluent:Notify({
                Title = "Suicide",
                Content = "Character killed",
                Duration = 2
            })
        end
    end
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

-- ========== SPIN FUNCTION ==========

function Fun.ToggleSpin(enabled)
    if enabled then
        Fun.StartSpin()
        Nexus.Fluent:Notify({
            Title = "Spin",
            Content = "Character spin enabled",
            Duration = 2
        })
    else
        Fun.StopSpin()
        Nexus.Fluent:Notify({
            Title = "Spin",
            Content = "Character spin disabled",
            Duration = 2
        })
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

-- ========== CLEANUP ==========

function Fun.Cleanup()
    Fun.StopEmote()
    Fun.StopJerk()
    Fun.StopSpin()
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
    
    print("Fun module cleaned up")
end

return Fun
