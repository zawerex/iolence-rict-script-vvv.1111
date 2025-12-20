-- Visual.lua - Модуль для визуальных функций и ESP
local Nexus = require(script.Parent.NexusMain)

local VisualModule = {}

function VisualModule.Initialize(nexus)
    local Tabs = nexus.Tabs
    local Options = nexus.Options
    local SafeCallback = nexus.SafeCallback
    
    local player = nexus.Player
    local Lighting = nexus.Services.Lighting
    local RunService = nexus.Services.RunService
    local Workspace = nexus.Services.Workspace
    local Players = nexus.Services.Players
    
    -- ========== FULLBRIGHT ФУНКЦИЯ ==========
    local function ToggleFullBright(enabled)
        nexus.FunctionStates.fullbrightEnabled = enabled
        if enabled then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
        else
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
            Lighting.Brightness = 1
        end
    end
    
    -- ========== NO SHADOW И NO FOG ==========
    local noShadowEnabled, noFogEnabled = false, false
    local originalFogEnd, originalFogStart, originalFogColor = Lighting.FogEnd, Lighting.FogStart, Lighting.FogColor
    
    -- ========== TIME CHANGER ==========
    local originalClockTime = Lighting.ClockTime
    
    -- ========== SIMPLE ESP SYSTEM ==========
    local ESPSystem = (function()
        local lastUpdate = 0
        local UPDATE_INTERVAL = 0.10 
        
        local espSettings = {
            Survivors  = {Enabled=false, Color=Color3.fromRGB(100,255,100), Colorpicker = nil},
            Killers    = {Enabled=false, Color=Color3.fromRGB(255,100,100), Colorpicker = nil},
            Generators = {Enabled=false, Color=Color3.fromRGB(100,170,255)},
            Pallets    = {Enabled=false, Color=Color3.fromRGB(120,80,40), Colorpicker = nil},
            ExitGates  = {Enabled=false, Color=Color3.fromRGB(200,200,100), Colorpicker = nil},
            Windows    = {Enabled=false, Color=Color3.fromRGB(100,200,200), Colorpicker = nil},
            Hooks      = {Enabled=false, Color=Color3.fromRGB(100, 50, 150), Colorpicker = nil}
        }

        local trackedObjects = {}
        local espConnections = {}
        local espLoopRunning = false
        local showGeneratorPercent = true

        local function getRole(targetPlayer)
            if targetPlayer.Team and targetPlayer.Team.Name then
                local n = targetPlayer.Team.Name:lower()
                if n:find("killer") then return "Killer" end
                if n:find("survivor") then return "Survivor" end
            end
            return "Survivor"
        end

        local function ensureHighlight(model, color, isObject)
            if not model then return end
            local hl = model:FindFirstChild("VD_HL")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "VD_HL"
                hl.Adornee = model
                hl.FillColor = color
                hl.FillTransparency = 0.8
                hl.OutlineColor = Color3.fromRGB(0,0,0)
                hl.OutlineTransparency = 0.1
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = model
            else
                hl.FillColor = color
                if isObject then
                    hl.OutlineColor = Color3.fromRGB(0,0,0)
                    hl.FillTransparency = 0.7
                    hl.OutlineTransparency = 0.1
                else
                    hl.OutlineColor = Color3.fromRGB(0,0,0)
                    hl.FillTransparency = 0.7
                    hl.OutlineTransparency = 0.1
                end
            end
        end

        local function clearHighlight(model)
            if model and model:FindFirstChild("VD_HL") then
                SafeCallback(function() model.VD_HL:Destroy() end)
            end
        end

        local function ensureLabel(model, text, isGenerator, textColor)
            if not model then return end
            local lbl = model:FindFirstChild("VD_Label")
            if not lbl then
                lbl = Instance.new("BillboardGui")
                lbl.Name = "VD_Label"
                if isGenerator then
                    lbl.Size = UDim2.new(0,100,0,25)
                    lbl.StudsOffset = Vector3.new(0,2.5,0)
                else
                    lbl.Size = UDim2.new(0,120,0,20)
                    lbl.StudsOffset = Vector3.new(0,3,0)
                end
                lbl.AlwaysOnTop = true
                lbl.MaxDistance = 1000
                lbl.Parent = model
                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "TextLabel"
                textLabel.Size = UDim2.new(1,0,1,0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextScaled = false
                if isGenerator then
                    textLabel.TextSize = 10
                else
                    textLabel.TextSize = 10
                end
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.RichText = true
                textLabel.TextStrokeTransparency = 0.1
                textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
                textLabel.Text = text
                textLabel.Parent = lbl
            else
                local textLabel = lbl:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.RichText = true
                    textLabel.Text = text
                    if isGenerator then
                        textLabel.TextSize = 14
                        lbl.StudsOffset = Vector3.new(0,2.5,0)
                    else
                        textLabel.TextSize = 12
                        lbl.StudsOffset = Vector3.new(0,3,0)
                    end
                    textLabel.TextStrokeTransparency = 0.1
                    textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
                end
            end
        end

        local function clearLabel(model)
            if model and model:FindFirstChild("VD_Label") then
                SafeCallback(function() model.VD_Label:Destroy() end)
            end
        end

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

        local function getGeneratorColor(percent)
            if percent >= 0.999 then
                return Color3.fromRGB(100, 255, 100)
            elseif percent >= 0.5 then
                local factor = (percent - 0.5) * 2
                return Color3.fromRGB(255, 200 + 55 * factor, 100 - 100 * factor)
            else
                local factor = percent * 2
                return Color3.fromRGB(255 - 155 * factor, 100 - 100 * factor, 100 - 100 * factor)
            end
        end

        local function ensureGeneratorESP(generator, progress)
            if not generator then return end
            
            local color = getGeneratorColor(progress)
            local percentText = showGeneratorPercent and string.format("%d%%", math.floor(progress * 100)) or ""
            
            local hl = generator:FindFirstChild("VD_HL")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "VD_HL"
                hl.Adornee = generator
                hl.FillColor = color
                hl.FillTransparency = 0.7
                hl.OutlineColor = Color3.fromRGB(0,0,0)
                hl.OutlineTransparency = 0.1
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = generator
            else
                hl.FillColor = color
                hl.OutlineColor = Color3.fromRGB(0,0,0)
                hl.FillTransparency = 0.7
                hl.OutlineTransparency = 0.1
            end
            
            if showGeneratorPercent then
                ensureLabel(generator, percentText, true, color)
            else
                clearLabel(generator)
            end
        end

        local function updatePlayersESP()
            local currentTime = tick()
            if currentTime - lastUpdate < UPDATE_INTERVAL then return end
            lastUpdate = currentTime
            
            local LPPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position

            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local role = getRole(targetPlayer)
                        local set = (role=="Killer") and espSettings.Killers or espSettings.Survivors
                        if set and set.Enabled then
                            local color = set.Colorpicker and set.Colorpicker.Value or set.Color

                            ensureHighlight(targetPlayer.Character, color, false)
                        else
                            clearHighlight(targetPlayer.Character)
                            clearLabel(targetPlayer.Character)
                        end
                    end
                end
            end
        end

        local function clearAllESP()
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer.Character then
                    clearHighlight(targetPlayer.Character)
                    clearLabel(targetPlayer.Character)
                end
            end
            
            for obj, _ in pairs(trackedObjects) do
                if obj and obj.Parent then
                    clearHighlight(obj)
                    clearLabel(obj)
                end
            end
        end

        local function trackObject(obj)
            local n = obj.Name:lower()
            if n:find("generator") then trackedObjects[obj] = "Generators"
            elseif n:find("pallet") then trackedObjects[obj] = "Pallets"
            elseif n:find("gate") then trackedObjects[obj] = "ExitGates"
            elseif n:find("window") then trackedObjects[obj] = "Windows"
            elseif n:find("hook") then trackedObjects[obj] = "Hooks" end
        end

        local function ESPLoop()
            while espLoopRunning do
                local LPPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
                
                for obj, typeName in pairs(trackedObjects) do
                    if obj and obj.Parent then
                        local set = espSettings[typeName]
                        if set and set.Enabled then
                            if typeName=="Generators" then
                                local progress = getGeneratorProgress(obj)
                                ensureGeneratorESP(obj, progress)
                            else
                                local color = set.Colorpicker and set.Colorpicker.Value or set.Color
                                local hl = obj:FindFirstChild("VD_HL")
                                if not hl then
                                    hl = Instance.new("Highlight")
                                    hl.Name = "VD_HL"
                                    hl.Adornee = obj
                                    hl.FillColor = color
                                    hl.FillTransparency = 0.7
                                    hl.OutlineColor = Color3.fromRGB(0,0,0)
                                    hl.OutlineTransparency = 0.1
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.Parent = obj
                                else
                                    hl.FillColor = color
                                    hl.FillTransparency = 0.7
                                    hl.OutlineColor = Color3.fromRGB(0,0,0)
                                    hl.OutlineTransparency = 0.1
                                end
                                clearLabel(obj)
                            end
                        else
                            clearHighlight(obj)
                            clearLabel(obj)
                        end
                    end
                end

                updatePlayersESP()
                
                task.wait(UPDATE_INTERVAL)
            end
        end

        local function StartESP()
            for _,v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Model") then trackObject(v) end
            end
            
            espConnections.descendantAdded = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("Model") then trackObject(obj) end
            end)
            
            espLoopRunning = true
            espConnections.mainLoop = task.spawn(ESPLoop)
        end

        local function StopESP()
            espLoopRunning = false
            
            for _, connection in pairs(espConnections) do
                if typeof(connection) == "RBXScriptConnection" then
                    SafeCallback(function() connection:Disconnect() end)
                end
            end
            espConnections = {}
            
            clearAllESP()
        end

        local function UpdateSetting(settingName, value)
            if espSettings[settingName] then
                espSettings[settingName].Enabled = value
                
                local anyEnabled = false
                for _, setting in pairs(espSettings) do
                    if setting.Enabled then
                        anyEnabled = true
                        break
                    end
                end
                
                if anyEnabled and not espLoopRunning then
                    StartESP()
                elseif not anyEnabled and espLoopRunning then
                    StopESP()
                end
            end
        end
        
        task.spawn(function()
            task.wait(2)
            for _,v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Model") then trackObject(v) end
            end
            
            Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("Model") then trackObject(obj) end
            end)
        end)

        return {
            UpdateSetting = UpdateSetting,
            GetSettings = function() return espSettings end,
            SetShowGeneratorPercent = function(value) showGeneratorPercent = value end,
            StopESP = StopESP,
            ClearAllESP = clearAllESP,
            StartESP = StartESP
        }
    end)()
    
    -- ========== ADVANCED ESP SYSTEM ==========
    local NewESPSystem = (function()
        local settings = {
            enabled = false,
            name = true,
            distance = true,
            healthbar = true,
            box = true,
            boxType = "full",
            bones = true,
            boneColorName = "White",
            tracers = true,
            tracerColorName = "White",
            scale = 1.5,
            healthBarTopColorName = "DarkGreen",
            healthBarMidColorName = "DarkOrange",
            healthBarBottomColorName = "DarkRed",
            stateColorName = "Orange",
            boxOutline = true,
            boxOutlineColorName = "Black",
            boxOutlineThickness = 0.4,
            boxColorName = "White",
            boxFill = true,
            boxFillColorName = "White",
            boxFillTransparency = 0.9,
            healthBarLeftOffset = 10
        }

        local colorMap = {
            Red = Color3.fromRGB(255,0,0),
            DarkRed = Color3.fromRGB(100,0,0),
            Green = Color3.fromRGB(0,255,0),
            DarkGreen = Color3.fromRGB(0,80,0),
            Blue = Color3.fromRGB(0,0,255),
            LightBlue = Color3.fromRGB(200,200,255),
            Yellow = Color3.fromRGB(255,255,0),
            Orange = Color3.fromRGB(255,165,0),
            DarkOrange = Color3.fromRGB(140,70,0),
            Purple = Color3.fromRGB(128,0,128),
            White = Color3.fromRGB(255,255,255),
            Black = Color3.fromRGB(0,0,0)
        }

        local boneColor = colorMap[settings.boneColorName] or colorMap.White
        local tracerColor = colorMap[settings.tracerColorName] or colorMap.White
        local healthBarTopColor = colorMap[settings.healthBarTopColorName] or colorMap.DarkGreen
        local healthBarMidColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        local healthBarBottomColor = colorMap[settings.healthBarBottomColorName] or colorMap.DarkRed
        local boxColor = colorMap[settings.boxColorName] or colorMap.White
        local boxOutlineColor = colorMap[settings.boxOutlineColorName] or colorMap.Black
        local boxOutlineThickness = settings.boxOutlineThickness or 1
        local boxFillColor = colorMap[settings.boxFillColorName] or colorMap.White
        local boxFillTransparency = math.clamp(settings.boxFillTransparency or 0, 0, 1)
        local healthBarLeftOffset = settings.healthBarLeftOffset or 15

        local LocalPlayer = Players.LocalPlayer
        local Camera = Workspace.CurrentCamera

        local function create(tp, props)
            local o = Drawing.new(tp)
            for i,v in pairs(props) do o[i]=v end
            return o
        end

        local ESP = {}
        local playerConnections = {}
        local espLoopConnection = nil

        local function clearESP(plr)
            local d = ESP[plr]
            if d then
                local drawingObjects = {
                    d.BoxFill, d.Name, d.Distance, d.Tracer, d.HealthBg, 
                    d.HealthBar, d.HealthMask, d.HealthText, d.Box, d.BoxOutline
                }
                
                for _, obj in ipairs(drawingObjects) do
                    if obj and typeof(obj) == "userdata" and obj.Remove then
                        SafeCallback(function() obj:Remove() end)
                    end
                end
                
                for i=1,24 do
                    if d["HealthStripe"..i] then
                        SafeCallback(function() d["HealthStripe"..i]:Remove() end)
                    end
                end
                
                if d.Bones then
                    for _, bone in ipairs(d.Bones) do
                        if bone and typeof(bone) == "userdata" and bone.Remove then
                            SafeCallback(function() bone:Remove() end)
                        end
                    end
                end
                
                ESP[plr] = nil
            end
            
            if playerConnections[plr] then
                for _, connection in pairs(playerConnections[plr]) do
                    SafeCallback(function() connection:Disconnect() end)
                end
                playerConnections[plr] = nil
            end
        end

        local function createESP(plr)
            if ESP[plr] then
                clearESP(plr)
            end
            
            local d = {
                Bones = {},
                BoxFill = nil,
                Name = nil,
                Distance = nil,
                Tracer = nil,
                HealthBg = nil,
                HealthBar = nil,
                HealthMask = nil,
                HealthText = nil,
                Box = nil,
                BoxOutline = nil
            }
            
            d.BoxFill = create("Square",{Thickness=0,Color=boxFillColor,Visible=false,Filled=true,Transparency=1-boxFillTransparency})
            d.Name = create("Text",{Size=20,Center=true,Outline=true,Color=Color3.new(1,1,1),Visible=false})
            d.Distance = create("Text",{Size=16,Center=true,Outline=true,Color=Color3.new(0.8,0.8,0.8),Visible=false})
            d.Tracer = create("Line",{Thickness=1.5,Color=tracerColor,Visible=false})
            
            d.HealthBg = Drawing.new("Square")
            d.HealthBg.Visible = false
            d.HealthBg.Filled = true
            d.HealthBg.Color = Color3.new(0,0,0)
            d.HealthBg.Transparency = 1
            
            d.HealthBar = Drawing.new("Square")
            d.HealthBar.Visible = false
            d.HealthBar.Filled = true
            d.HealthBar.Transparency = 1
            
            d.HealthMask = Drawing.new("Square")
            d.HealthMask.Visible = false
            d.HealthMask.Filled = true
            d.HealthMask.Color = Color3.new(0,0,0)
            d.HealthMask.Transparency = 0.3
            
            d.HealthText = create("Text",{Size=14,Center=true,Outline=true,Color=Color3.new(1,1,1),Visible=false})
            
            d.Box = create("Square", {
                Thickness = 1.7,
                Color = boxColor,
                Visible = false,
                Filled = false
            })
            
            d.BoxOutline = create("Square", {
                Thickness = 1.7 + boxOutlineThickness * 2,
                Color = boxOutlineColor,
                Visible = false,
                Filled = false
            })
            
            for i=1,14 do
                d.Bones[i]=create("Line",{Thickness=1.5,Color=boneColor,Visible=false})
            end
            
            ESP[plr] = d
            
            if not playerConnections[plr] then
                playerConnections[plr] = {}
            end
            
            return d
        end

        local function setupPlayer(plr)
            if plr == LocalPlayer then return end
            
            createESP(plr)
            
            local charAddedConnection = plr.CharacterAdded:Connect(function(char)
                wait(0.5)
                
                if not ESP[plr] then
                    createESP(plr)
                end
                
                local humanoid = char:WaitForChild("Humanoid", 5)
                if humanoid then
                    if playerConnections[plr] then
                        if playerConnections[plr].died then
                            playerConnections[plr].died:Disconnect()
                        end
                        
                        playerConnections[plr].died = humanoid.Died:Connect(function()
                            clearESP(plr)
                        end)
                    end
                end
            end)
            
            local charRemovingConnection = plr.CharacterRemoving:Connect(function()
                clearESP(plr)
            end)
            
            if playerConnections[plr] then
                playerConnections[plr].charAdded = charAddedConnection
                playerConnections[plr].charRemoving = charRemovingConnection
            end
            
            if plr.Character then
                task.spawn(function()
                    local char = plr.Character
                    wait(0.5)
                    
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        if playerConnections[plr] then
                            playerConnections[plr].died = humanoid.Died:Connect(function()
                                clearESP(plr)
                            end)
                        end
                    end
                end)
            end
        end

        local function cleanupPlayer(plr)
            clearESP(plr)
        end

        local function getHealthGradientColor(y, h)
            local t = 1-(y/math.max(h,1))
            if t>=0.5 then
                local s = (t-0.5)*2
                return healthBarMidColor:Lerp(healthBarTopColor,s)
            else
                local s = t*2
                return healthBarBottomColor:Lerp(healthBarMidColor,s)
            end
        end

        local function isR6(char)
            return char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso")
        end

        local NAME_TEXT_SIZE = 10
        local DISTANCE_TEXT_SIZE = 16
        local HEALTH_TEXT_SIZE = 14
        local NAME_OFFSET = 22
        local DISTANCE_OFFSET = 6

        local function updateESP()
            if not settings.enabled then return end
            
            local camPos = Camera.CFrame.Position
            local screenCenter = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
            
            for plr, d in pairs(ESP) do
                if not plr or not plr.Parent then
                    clearESP(plr)
                    continue
                end
                
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if hum and hum.Health <= 0 then
                        if d.BoxFill then d.BoxFill.Visible = false end
                        if d.Box then d.Box.Visible = false end
                        if d.BoxOutline then d.BoxOutline.Visible = false end
                        if d.Name then d.Name.Visible = false end
                        if d.Distance then d.Distance.Visible = false end
                        if d.HealthBg then d.HealthBg.Visible = false end
                        if d.HealthText then d.HealthText.Visible = false end
                        for i=1,24 do
                            if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                        end
                        if d.Bones then for _,line in ipairs(d.Bones) do line.Visible = false end end
                        if d.Tracer then d.Tracer.Visible = false end
                        continue
                    end
                    
                    local root = char.HumanoidRootPart
                    local head = char.Head

                    local function screenPosOrNil(part)
                        if part then
                            local pos,onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen and pos.Z>0 then return Vector2.new(pos.X,pos.Y) end
                        end
                        return nil
                    end

                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
                    local footPos = Camera:WorldToViewportPoint(root.Position-Vector3.new(0,2.5,0))

                    if onScreen then
                        local rawHeight = footPos.Y - headPos.Y
                        local height = rawHeight * settings.scale
                        local width = (height/2) * settings.scale
                        local x = headPos.X - width/2
                        local y = headPos.Y - (height-rawHeight)/2

                        if d.BoxFill then
                            d.BoxFill.Position = Vector2.new(x,y)
                            d.BoxFill.Size = Vector2.new(width,height)
                            d.BoxFill.Color = boxFillColor
                            d.BoxFill.Filled = true
                            d.BoxFill.Transparency = 1 - boxFillTransparency
                            d.BoxFill.Visible = settings.boxFill
                        end

                        if d.Box then
                            d.Box.Position = Vector2.new(x, y)
                            d.Box.Size = Vector2.new(width, height)
                            d.Box.Color = boxColor
                            d.Box.Thickness = 1.7
                            d.Box.Visible = settings.box
                        end
                        
                        if d.BoxOutline then
                            d.BoxOutline.Position = Vector2.new(x - boxOutlineThickness, y - boxOutlineThickness)
                            d.BoxOutline.Size = Vector2.new(width + boxOutlineThickness * 2, height + boxOutlineThickness * 2)
                            d.BoxOutline.Color = boxOutlineColor
                            d.BoxOutline.Thickness = boxOutlineThickness
                            d.BoxOutline.Visible = settings.box and settings.boxOutline
                        end

                        if d.Name then
                            d.Name.Text = plr.Name
                            d.Name.Size = NAME_TEXT_SIZE
                            d.Name.Position = Vector2.new(headPos.X, y - NAME_OFFSET)
                            d.Name.Visible = settings.name
                        end

                        if d.Distance then
                            local dist = math.floor((root.Position - camPos).Magnitude)
                            d.Distance.Text = dist.."m"
                            d.Distance.Size = DISTANCE_TEXT_SIZE
                            d.Distance.Position = Vector2.new(headPos.X, y + height + DISTANCE_OFFSET)
                            d.Distance.Visible = settings.distance
                        end

                        if d.HealthBg and d.HealthBar and d.HealthText then
                            local barX = x - healthBarLeftOffset
                            local barY = y
                            local barWidth = 6
                            local barHeight = height
                            
                            d.HealthBg.Position = Vector2.new(barX, barY)
                            d.HealthBg.Size = Vector2.new(barWidth, barHeight)
                            d.HealthBg.Visible = settings.healthbar
                            
                            if settings.healthbar then
                                local HEALTH_STRIPES = 24
                                local hpPerc = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                                for i=1,HEALTH_STRIPES do
                                    local stripeY = barY + barHeight * (i-1) / HEALTH_STRIPES
                                    local stripeH = barHeight / HEALTH_STRIPES
                                    local stripeColor = getHealthGradientColor(stripeY-barY, barHeight)
                                    if not d["HealthStripe"..i] then
                                        d["HealthStripe"..i] = Drawing.new("Square")
                                        d["HealthStripe"..i].Filled = true
                                    end
                                    local stripe = d["HealthStripe"..i]
                                    stripe.Color = stripeColor
                                    stripe.Position = Vector2.new(barX, stripeY)
                                    stripe.Size = Vector2.new(barWidth, stripeH)
                                    stripe.Visible = (i-1) / HEALTH_STRIPES < hpPerc
                                    stripe.Transparency = 1
                                end
                                
                                d.HealthText.Text = tostring(math.floor(hum.Health))
                                d.HealthText.Size = HEALTH_TEXT_SIZE
                                d.HealthText.Position = Vector2.new(x - healthBarLeftOffset - 14, y + height/2)
                                d.HealthText.Visible = true
                            else
                                for i=1,24 do
                                    if d["HealthStripe"..i] then
                                        d["HealthStripe"..i].Visible = false
                                    end
                                end
                                d.HealthText.Visible = false
                            end
                        end

                        if d.Bones then
                            local bonesVisible = settings.bones
                            
                            local bones
                            if isR6(char) then
                                bones={
                                    {char:FindFirstChild("Head"),char:FindFirstChild("Torso")},
                                    {char:FindFirstChild("Torso"),char:FindFirstChild("Left Arm")},
                                    {char:FindFirstChild("Left Arm"),char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("Torso"),char:FindFirstChild("Right Arm")},
                                    {char:FindFirstChild("Right Arm"),char:FindFirstChild("Right Leg")},
                                    {char:FindFirstChild("Torso"),char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("Torso"),char:FindFirstChild("Right Leg")}
                                }
                                for i=1,14 do
                                    local line = d.Bones[i]
                                    if bones[i] and bones[i][1] and bones[i][2] then
                                        local p1 = screenPosOrNil(bones[i][1])
                                        local p2 = screenPosOrNil(bones[i][2])
                                        if p1 and p2 then
                                            line.From = p1
                                            line.To = p2
                                            line.Color = boneColor
                                            line.Visible = bonesVisible
                                        else
                                            line.Visible = false
                                        end
                                    else
                                        line.Visible = false
                                    end
                                end
                            else
                                bones={
                                    {char:FindFirstChild("Head"),char:FindFirstChild("Neck")},
                                    {char:FindFirstChild("Neck"),char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")},
                                    {char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm")},
                                    {char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm"),char:FindFirstChild("LeftHand") or char:FindFirstChild("Left hand")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")},
                                    {char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm")},
                                    {char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm"),char:FindFirstChild("RightHand") or char:FindFirstChild("Right hand")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")},
                                    {char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin")},
                                    {char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin"),char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left foot")},
                                    {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")},
                                    {char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"),char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin")},
                                    {char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin"),char:FindFirstChild("RightFoot") or char:FindFirstChild("Right foot")}
                                }
                                for i=1,14 do
                                    local line = d.Bones[i]
                                    if bones[i] and bones[i][1] and bones[i][2] then
                                        local p1 = screenPosOrNil(bones[i][1])
                                        local p2 = screenPosOrNil(bones[i][2])
                                        if p1 and p2 then
                                            line.From = p1
                                            line.To = p2
                                            line.Color = boneColor
                                            line.Visible = bonesVisible
                                        else
                                            line.Visible = false
                                        end
                                    else
                                        line.Visible = false
                                    end
                                end
                            end
                        end

                        if d.Tracer then
                            local rootPos2D = Vector2.new(headPos.X, headPos.Y)
                            d.Tracer.From = screenCenter
                            d.Tracer.To = rootPos2D
                            d.Tracer.Color = tracerColor
                            d.Tracer.Visible = settings.tracers
                        end

                    else
                        if d.BoxFill then d.BoxFill.Visible = false end
                        if d.Box then d.Box.Visible = false end
                        if d.BoxOutline then d.BoxOutline.Visible = false end
                        if d.Name then d.Name.Visible = false end
                        if d.Distance then d.Distance.Visible = false end
                        if d.HealthBg then d.HealthBg.Visible = false end
                        if d.HealthText then d.HealthText.Visible = false end
                        for i=1,24 do
                            if d["HealthStripe"..i] then d["HealthStripe"..i].Visible = false end
                        end
                        if d.Bones then for _,line in ipairs(d.Bones) do line.Visible = false end end
                        if d.Tracer then d.Tracer.Visible = false end
                    end
                else
                    clearESP(plr)
                end
            end
        end

        local function startESP()
            if espLoopConnection then
                espLoopConnection:Disconnect()
            end
            
            settings.enabled = true
            
            Players.PlayerAdded:Connect(function(plr)
                setupPlayer(plr)
            end)
            
            Players.PlayerRemoving:Connect(function(plr)
                cleanupPlayer(plr)
            end)
            
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    setupPlayer(plr)
                end
            end
            
            espLoopConnection = RunService.RenderStepped:Connect(updateESP)
        end

        local function stopESP()
            settings.enabled = false
            
            if espLoopConnection then
                espLoopConnection:Disconnect()
                espLoopConnection = nil
            end
            
            for plr, _ in pairs(ESP) do
                clearESP(plr)
            end
            ESP = {}
            playerConnections = {}
        end

        local function toggleESP()
            if settings.enabled then
                stopESP()
            else
                startESP()
            end
        end

        local function updateSetting(key, value)
            settings[key] = value
            
            if key == "enabled" then
                if value then
                    startESP()
                else
                    stopESP()
                end
            end
        end

        return {
            Settings = settings,
            ColorMap = colorMap,
            Toggle = toggleESP,
            Start = startESP,
            Stop = stopESP,
            UpdateSetting = updateSetting,
            GetSetting = function(key) return settings[key] end
        }
    end)()
    
    -- ========== СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА ==========
    
    -- No Shadow Toggle
    local NoShadowToggle = Tabs.Visual:AddToggle("NoShadow", {
        Title = "No Shadow", 
        Description = "", 
        Default = false
    })

    NoShadowToggle:OnChanged(function(v)
        SafeCallback(function()
            noShadowEnabled = v
            for _, light in ipairs(Lighting:GetDescendants()) do if light:IsA("Light") then light.Shadows = not v end end
            Lighting.GlobalShadows = not v
        end)
    end)

    -- No Fog Toggle
    local NoFogToggle = Tabs.Visual:AddToggle("NoFog", {
        Title = "No Fog", 
        Description = "", 
        Default = false
    })

    NoFogToggle:OnChanged(function(v)
        SafeCallback(function()
            noFogEnabled = v
            if v then 
                if not originalFogEnd then
                    originalFogEnd = Lighting.FogEnd
                    originalFogStart = Lighting.FogStart
                    originalFogColor = Lighting.FogColor
                end
                
                Lighting.FogEnd = 1000000
                Lighting.FogStart = 1000000
                Lighting.FogDensity = 0
                
                if Lighting:FindFirstChild("Atmosphere") then
                    Lighting.Atmosphere.Density = 0
                end
                
                if nexus.Connections.noFog then
                    nexus.Connections.noFog:Disconnect()
                end
                
                nexus.Connections.noFog = RunService.Heartbeat:Connect(function()
                    if noFogEnabled then
                        Lighting.FogEnd = 1000000
                        Lighting.FogStart = 1000000
                        Lighting.FogDensity = 0
                        
                        if Lighting:FindFirstChild("Atmosphere") then
                            Lighting.Atmosphere.Density = 0
                        end
                    else
                        if nexus.Connections.noFog then
                            nexus.Connections.noFog:Disconnect()
                            nexus.Connections.noFog = nil
                        end
                    end
                end)
            else
                if originalFogEnd then
                    Lighting.FogEnd = originalFogEnd
                    Lighting.FogStart = originalFogStart
                    Lighting.FogColor = originalFogColor
                    Lighting.FogDensity = 0.01
                end
                
                if Lighting:FindFirstChild("Atmosphere") then
                    Lighting.Atmosphere.Density = 0.3
                end
                
                if nexus.Connections.noFog then
                    nexus.Connections.noFog:Disconnect()
                    nexus.Connections.noFog = nil
                end
            end
        end)
    end)

    -- FullBright Toggle
    local FullBrightToggle = Tabs.Visual:AddToggle("FullBright", {
        Title = "FullBright", 
        Description = "", 
        Default = false
    })

    FullBrightToggle:OnChanged(function(v)
        SafeCallback(function()
            ToggleFullBright(v)
        end)
    end)

    -- Time Changer
    local TimeChangerToggle = Tabs.Visual:AddToggle("TimeChanger", {
        Title = "Time Changer", 
        Description = "", 
        Default = false
    })

    local TimeSlider = Tabs.Visual:AddSlider("TimeValue", {
        Title = "Time of Day", 
        Description = "",
        Default = 14,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(value)
            SafeCallback(function()
                if Options.TimeChanger.Value then
                    Lighting.ClockTime = value
                end
            end)
        end
    })

    TimeChangerToggle:OnChanged(function(v)
        SafeCallback(function()
            if v then
                local currentTime = Options.TimeValue.Value
                Lighting.ClockTime = currentTime
                
                if not originalClockTime then
                    originalClockTime = Lighting.ClockTime
                end
            else
                if originalClockTime then
                    Lighting.ClockTime = originalClockTime
                end
            end
        end)
    end)

    -- Автоматическое обновление времени
    task.spawn(function()
        while true do
            task.wait(1)
            if Options.TimeChanger and Options.TimeChanger.Value then
                local currentTime = Options.TimeValue.Value
                Lighting.ClockTime = currentTime
            end
        end
    end)
    
    -- ========== ESP SETTINGS ==========
    Tabs.Visual:AddSection("Advanced ESP Settings")

    local AdvancedESPToggle = Tabs.Visual:AddToggle("AdvancedESP", {
        Title = "Advanced ESP", 
        Description = "Enable advanced player ESP system", 
        Default = false
    })

    AdvancedESPToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("enabled", v)
        end)
    end)

    Tabs.Visual:AddSection("ESP Components")

    local ESPBoxToggle = Tabs.Visual:AddToggle("ESPBox", {
        Title = "Player Boxes", 
        Description = "Show/hide player boxes", 
        Default = true
    })

    ESPBoxToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("box", v)
        end)
    end)

    local ESPNamesToggle = Tabs.Visual:AddToggle("ESPNames", {
        Title = "Player Names", 
        Description = "Show/hide player names", 
        Default = true
    })

    ESPNamesToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("name", v)
        end)
    end)

    local ESPHealthBarToggle = Tabs.Visual:AddToggle("ESPHealthBar", {
        Title = "Health Bar", 
        Description = "Show/hide health bar", 
        Default = true
    })

    ESPHealthBarToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("healthbar", v)
        end)
    end)

    local ESPDistanceToggle = Tabs.Visual:AddToggle("ESPDistance", {
        Title = "Distance", 
        Description = "Show/hide distance to players", 
        Default = true
    })

    ESPDistanceToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("distance", v)
        end)
    end)

    local ESPBoxFillToggle = Tabs.Visual:AddToggle("ESPBoxFill", {
        Title = "Filled Box", 
        Description = "Show/hide filled boxes", 
        Default = true
    })

    ESPBoxFillToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("boxFill", v)
        end)
    end)

    local ESPTracersToggle = Tabs.Visual:AddToggle("ESPTracers", {
        Title = "Tracers", 
        Description = "Show/hide tracers to players", 
        Default = true
    })

    ESPTracersToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("tracers", v)
        end)
    end)

    local ESPBonesToggle = Tabs.Visual:AddToggle("ESPBones", {
        Title = "Player Bones", 
        Description = "Show/hide player bones", 
        Default = true
    })

    ESPBonesToggle:OnChanged(function(v)
        SafeCallback(function()
            NewESPSystem.UpdateSetting("bones", v)
        end)
    end)
    
    -- ========== SIMPLE ESP SETTINGS ==========
    local ESP_Section = Tabs.Visual:AddSection("ESP Settings")

    local ShowGeneratorPercentToggle = Tabs.Visual:AddToggle("ESPShowGenPercent", {
        Title = "Show Generator %", 
        Description = "Toggle display of generator percentages", 
        Default = true
    })

    ShowGeneratorPercentToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.SetShowGeneratorPercent(v)
        end)
    end)

    -- Survivors ESP с Colorpicker
    local ESPSurvivorsToggle = Tabs.Visual:AddToggle("ESPSurvivors", {
        Title = "Survivors ESP", 
        Description = "", 
        Default = false
    })

    ESPSurvivorsToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Survivors", v)
        end)
    end)

    local SurvivorColorpicker = Tabs.Visual:AddColorpicker("SurvivorColorpicker", {
        Title = "Survivor Color",
        Default = Color3.fromRGB(100, 255, 100)
    })

    SurvivorColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.Survivors.Colorpicker = SurvivorColorpicker
            if espSettings.Survivors.Enabled then
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if targetPlayer ~= player and targetPlayer.Character then
                        local role = espSettings.Survivors
                        local color = role.Colorpicker.Value
                        local hl = targetPlayer.Character:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = color
                        end
                    end
                end
            end
        end)
    end)

    SurvivorColorpicker:SetValueRGB(Color3.fromRGB(100, 255, 100))

    -- Killers ESP с Colorpicker
    local ESPKillersToggle = Tabs.Visual:AddToggle("ESPKillers", {
        Title = "Killers ESP", 
        Description = "", 
        Default = false
    })

    ESPKillersToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Killers", v)
        end)
    end)

    local KillerColorpicker = Tabs.Visual:AddColorpicker("KillerColorpicker", {
        Title = "Killer Color",
        Default = Color3.fromRGB(255, 100, 100)
    })

    KillerColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.Killers.Colorpicker = KillerColorpicker
            if espSettings.Killers.Enabled then
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if targetPlayer ~= player and targetPlayer.Character then
                        local role = espSettings.Killers
                        local color = role.Colorpicker.Value
                        local hl = targetPlayer.Character:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = color
                        end
                    end
                end
            end
        end)
    end)

    KillerColorpicker:SetValueRGB(Color3.fromRGB(255, 100, 100))

    -- Hooks ESP с Colorpicker
    local ESPHooksToggle = Tabs.Visual:AddToggle("ESPHooks", {
        Title = "Hooks ESP", 
        Description = "", 
        Default = false
    })

    ESPHooksToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Hooks", v)
        end)
    end)

    local HookColorpicker = Tabs.Visual:AddColorpicker("HookColorpicker", {
        Title = "Hook Color",
        Default = Color3.fromRGB(100, 50, 150)
    })

    HookColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.Hooks.Colorpicker = HookColorpicker
            if espSettings.Hooks.Enabled then
                for obj, typeName in pairs(ESPSystem.GetSettings()) do
                    if typeName == "Hooks" then
                        local hl = obj:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = espSettings.Hooks.Colorpicker.Value
                        end
                    end
                end
            end
        end)
    end)

    HookColorpicker:SetValueRGB(Color3.fromRGB(100, 50, 150))

    -- Generators ESP
    local ESPGeneratorsToggle = Tabs.Visual:AddToggle("ESPGenerators", {
        Title = "Generators ESP", 
        Description = "", 
        Default = false
    })

    ESPGeneratorsToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Generators", v)
        end)
    end)

    -- Pallets ESP с Colorpicker
    local ESPPalletsToggle = Tabs.Visual:AddToggle("ESPPallets", {
        Title = "Pallets ESP", 
        Description = "", 
        Default = false
    })

    ESPPalletsToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Pallets", v)
        end)
    end)

    local PalletColorpicker = Tabs.Visual:AddColorpicker("PalletColorpicker", {
        Title = "Pallet Color",
        Default = Color3.fromRGB(120, 80, 40)
    })

    PalletColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.Pallets.Colorpicker = PalletColorpicker
            if espSettings.Pallets.Enabled then
                for obj, typeName in pairs(ESPSystem.GetSettings()) do
                    if typeName == "Pallets" then
                        local hl = obj:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = espSettings.Pallets.Colorpicker.Value
                        end
                    end
                end
            end
        end)
    end)

    PalletColorpicker:SetValueRGB(Color3.fromRGB(120, 80, 40))

    -- Exit Gates ESP с Colorpicker
    local ESPGatesToggle = Tabs.Visual:AddToggle("ESPGates", {
        Title = "Exit Gates ESP", 
        Description = "", 
        Default = false
    })

    ESPGatesToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("ExitGates", v)
        end)
    end)

    local GateColorpicker = Tabs.Visual:AddColorpicker("GateColorpicker", {
        Title = "Gate Color",
        Default = Color3.fromRGB(200, 200, 100)
    })

    GateColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.ExitGates.Colorpicker = GateColorpicker
            if espSettings.ExitGates.Enabled then
                for obj, typeName in pairs(ESPSystem.GetSettings()) do
                    if typeName == "ExitGates" then
                        local hl = obj:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = espSettings.ExitGates.Colorpicker.Value
                        end
                    end
                end
            end
        end)
    end)

    GateColorpicker:SetValueRGB(Color3.fromRGB(200, 200, 100))

    -- Windows ESP с Colorpicker
    local ESPWindowsToggle = Tabs.Visual:AddToggle("ESPWindows", {
        Title = "Windows ESP", 
        Description = "", 
        Default = false
    })

    ESPWindowsToggle:OnChanged(function(v)
        SafeCallback(function()
            ESPSystem.UpdateSetting("Windows", v)
        end)
    end)

    local WindowColorpicker = Tabs.Visual:AddColorpicker("WindowColorpicker", {
        Title = "Window Color",
        Default = Color3.fromRGB(100, 200, 200)
    })

    WindowColorpicker:OnChanged(function()
        SafeCallback(function()
            local espSettings = ESPSystem.GetSettings()
            espSettings.Windows.Colorpicker = WindowColorpicker
            if espSettings.Windows.Enabled then
                for obj, typeName in pairs(ESPSystem.GetSettings()) do
                    if typeName == "Windows" then
                        local hl = obj:FindFirstChild("VD_HL")
                        if hl then
                            hl.FillColor = espSettings.Windows.Colorpicker.Value
                        end
                    end
                end
            end
        end)
    end)

    WindowColorpicker:SetValueRGB(Color3.fromRGB(100, 200, 200))

    -- Initialize ESP colorpickers
    local espSettings = ESPSystem.GetSettings()
    espSettings.Survivors.Colorpicker = SurvivorColorpicker
    espSettings.Killers.Colorpicker = KillerColorpicker
    espSettings.Hooks.Colorpicker = HookColorpicker
    espSettings.Pallets.Colorpicker = PalletColorpicker
    espSettings.ExitGates.Colorpicker = GateColorpicker
    espSettings.Windows.Colorpicker = WindowColorpicker
    
    -- Сохраняем функции в Nexus
    nexus.Functions.ToggleFullBright = ToggleFullBright
    nexus.Functions.ESPSystem = ESPSystem
    nexus.Functions.NewESPSystem = NewESPSystem
    
    return VisualModule
end

return VisualModule
