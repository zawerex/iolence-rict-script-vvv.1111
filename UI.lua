-- UI Module - Creates the main window and tabs
local Nexus = _G.Nexus

local UI = {}

function UI.Init(nxs)
    Nexus = nxs
    
    local windowSize = Nexus.IS_MOBILE and UDim2.fromOffset(350, 200) or UDim2.fromOffset(580,550)
    
    -- Создаем главное окно
    Nexus.Window = Nexus.Fluent:CreateWindow({
        Title = "NEXUS",
        SubTitle = "Violence District",
        Search = false,
        Icon = "",
        TabWidth = 120,
        Size = windowSize,  
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl,
        UserInfo = true,
        UserInfoTop = false,
        UserInfoTitle = Nexus.Player.DisplayName,
        UserInfoSubtitle = "user",
        UserInfoSubtitleColor = Color3.fromRGB(255, 250, 250)
    })
    
    -- Создаем вкладки
    Nexus.Tabs = {}
    Nexus.Tabs.Main = Nexus.Window:AddTab({ Title = "Survivor", Icon = "snowflake" })
    Nexus.Tabs.Killer = Nexus.Window:AddTab({ Title = "Killer", Icon = "snowflake" })
    Nexus.Tabs.Movement = Nexus.Window:AddTab({ Title = "Movement", Icon = "snowflake" })
    Nexus.Tabs.Fun = Nexus.Window:AddTab({ Title = "Other", Icon = "snowflake" })
    Nexus.Tabs.Visual = Nexus.Window:AddTab({ Title = "Visual & ESP", Icon = "snowflake" })
    
    if Nexus.IS_DESKTOP then
        Nexus.Tabs.Binds = Nexus.Window:AddTab({ Title = "Binds", Icon = "snowflake" })
    end
    
    -- Добавляем заголовок
    Nexus.Tabs.Main:AddParagraph({
        Title = "Hello, " .. Nexus.Player.Name .. "!",
        Content = "Enjoy using it ♡"
    })
    
    print("✓ UI initialized")
end

function UI.Cleanup()
    if Nexus.Window then
        -- Можно добавить очистку UI если нужно
    end
end

return UI
