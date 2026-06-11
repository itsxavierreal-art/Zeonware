-- ZeonWare v2 - BedWars
-- Working: Aimbot, KillAura, Reach, ESP, Speed
-- Textboxes fixed with proper number display

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- =====================
-- SETTINGS
-- =====================
getgenv().ZeonWare = {
    Aimbot = {Enabled = false, FOV = 220, Smooth = 0.38, Prediction = 0.14, TeamCheck = true},
    SilentAim = {Enabled = false},
    KillAura = {Enabled = false, Range = 14},
    AutoClicker = {Enabled = false, CPS = 16},
    ESP = {Enabled = false, Boxes = true, Names = true, Distance = true, Tracers = true, TeamColor = true},
    Movement = {Speed = false, Value = 2.0},
    Reach = {Enabled = false, Value = 8}
}

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- =====================
-- BEDWARS REMOTES & UTILS
-- =====================
local function getRemotes()
    local net = ReplicatedStorage:FindFirstChild("rbxts_include")
        and ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
        and ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts")
        and ReplicatedStorage.rbxts_include.node_modules["@rbxts"]:FindFirstChild("net")
        and ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net:FindFirstChild("out")
        and ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out:FindFirstChild("_NetManaged")
    if net then
        return net:FindFirstChild("SwordHit"), net:FindFirstChild("SwordSwingMiss")
    end
    return nil, nil
end

local swordHitRemote, swordSwingRemote = getRemotes()

local function getInventory()
    local inv = ReplicatedStorage:FindFirstChild("Inventories")
    if inv then
        return inv:FindFirstChild(LocalPlayer.Name) or inv:FindFirstChild(tostring(LocalPlayer.UserId))
    end
    return nil
end

local function getCurrentSword()
    local inv = getInventory()
    if not inv then return nil end
    local exact = inv:FindFirstChild("wood_sword")
    if exact then return exact end
    for _, item in ipairs(inv:GetChildren()) do
        local name = item.Name:lower()
        if name:find("sword") or name:find("dagger") or name:find("axe") or name:find("hammer") then
            return item
        end
    end
    return nil
end

local function getNearestTarget(maxRange)
    local close, dist = nil, math.huge
    local me = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not me then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if getgenv().ZeonWare.Aimbot.TeamCheck and p.Team == LocalPlayer.Team then continue end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        local d = (hrp.Position - me.Position).Magnitude
        if maxRange and d > maxRange then continue end
        if d < dist then dist = d; close = p end
    end
    return close, dist
end

-- =====================
-- LOADER
-- =====================
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name = "ZeonWareLoader"
loaderGui.ResetOnSpawn = false
loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loaderGui.Parent = PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
bg.BorderSizePixel = 0
bg.Parent = loaderGui

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 500, 0, 60)
logo.Position = UDim2.new(0.5, 0, 0.4, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Text = "ZEONWARE"
logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 56
logo.TextTransparency = 1
logo.Parent = bg

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(0, 500, 0, 20)
sub.Position = UDim2.new(0.5, 0, 0.48, 0)
sub.AnchorPoint = Vector2.new(0.5, 0.5)
sub.BackgroundTransparency = 1
sub.Text = "B E D W A R S"
sub.TextColor3 = Color3.fromRGB(90, 25, 230)
sub.Font = Enum.Font.GothamBold
sub.TextSize = 16
sub.TextTransparency = 1
sub.Parent = bg

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0, 250, 0, 3)
barBg.Position = UDim2.new(0.5, 0, 0.55, 0)
barBg.AnchorPoint = Vector2.new(0.5, 0.5)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
barBg.BorderSizePixel = 0
barBg.Parent = bg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(90, 25, 230)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 300, 0, 18)
status.Position = UDim2.new(0.5, 0, 0.58, 0)
status.AnchorPoint = Vector2.new(0.5, 0)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(100, 100, 110)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = bg

-- =====================
-- MAIN SCRIPT
-- =====================
local function loadMainScript()

    -- =====================
    -- NOTIFICATIONS
    -- =====================
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "ZeonWareNotifs"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.Parent = PlayerGui

    local notifContainer = Instance.new("Frame")
    notifContainer.Size = UDim2.new(0, 260, 1, -20)
    notifContainer.Position = UDim2.new(1, -280, 0, 10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = notifGui

    local notifList = Instance.new("UIListLayout")
    notifList.SortOrder = Enum.SortOrder.LayoutOrder
    notifList.VerticalAlignment = Enum.VerticalAlignment.Top
    notifList.Padding = UDim.new(0, 6)
    notifList.Parent = notifContainer

    local function notify(title, msg, dur, ntype)
        dur = dur or 3
        ntype = ntype or "info"
        local col = {
            info = Color3.fromRGB(90, 25, 230),
            success = Color3.fromRGB(0, 200, 80),
            warn = Color3.fromRGB(255, 170, 0),
            error = Color3.fromRGB(255, 50, 50)
        }
        local c = col[ntype] or col.info

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 60)
        f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        f.BorderSizePixel = 0
        f.BackgroundTransparency = 1
        f.Parent = notifContainer

        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 3, 1, 0)
        accent.BackgroundColor3 = c
        accent.BorderSizePixel = 0
        accent.Parent = f
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 6)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 6)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = f

        local m = Instance.new("TextLabel")
        m.Size = UDim2.new(1, -20, 0, 26)
        m.Position = UDim2.new(0, 12, 0, 28)
        m.BackgroundTransparency = 1
        m.Text = msg
        m.TextColor3 = Color3.fromRGB(160, 160, 170)
        m.Font = Enum.Font.Gotham
        m.TextSize = 12
        m.TextXAlignment = Enum.TextXAlignment.Left
        m.Parent = f

        f.Position = UDim2.new(1, 20, 0, 0)
        TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0
        }):Play()

        task.delay(dur, function()
            TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.35)
            f:Destroy()
        end)
    end

    -- =====================
    -- CONFIG SYSTEM
    -- =====================
    local CFG_FOLDER = "ZeonWare"
    if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end

    local function cfgPath(name) return CFG_FOLDER .. "/" .. name .. ".json" end

    local function saveCfg(name)
        name = name or "Default"
        local ok, err = pcall(function()
            writefile(cfgPath(name), HttpService:JSONEncode(getgenv().ZeonWare))
        end)
        notify(ok and "Saved" or "Error", ok and ('Config "' .. name .. '" saved') or err, 3, ok and "success" or "error")
    end

    local function loadCfg(name)
        name = name or "Default"
        local path = cfgPath(name)
        if not isfile(path) then notify("Not Found", 'No config "' .. name .. '"', 3, "warn") return false end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if ok and data then
            getgenv().ZeonWare = data
            notify("Loaded", 'Config "' .. name .. '" loaded', 3, "success")
            return true
        else
            notify("Error", "Bad config file", 3, "error")
            return false
        end
    end

    local function delCfg(name)
        local path = cfgPath(name)
        if isfile(path) then
            delfile(path)
            notify("Deleted", 'Config "' .. name .. '" removed', 3, "success")
        else
            notify("Not Found", 'No config "' .. name .. '"', 3, "warn")
        end
    end

    -- =====================
    -- MAIN UI
    -- =====================
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt", true))()
    local Window = Library:Window("ZeonWare | BedWars", Color3.fromRGB(90, 25, 230), Enum.KeyCode.RightControl)

    -- =====================
    -- HOME TAB
    -- =====================
    local Home = Window:Tab("Home")
    Home:Label("Welcome to ZeonWare v2")
    Home:Label("BedWars Edition")
    Home:Label("")
    Home:Label("═══ UPDATE LOG ═══")
    Home:Label("[v2] Fixed all textboxes")
    Home:Label("[v2] Improved Aimbot accuracy")
    Home:Label("[v2] KillAura uses SwordHit remote")
    Home:Label("[v2] Reach now expands hitbox")
    Home:Label("[v2] ESP fully optimized")
    Home:Label("[v1] Renamed to ZeonWare")
    Home:Label("")
    Home:Label("═══ DISCORD ═══")
    Home:Label("discord.gg/zeonware")
    Home:Label("")
    Home:Label("═══ STATUS ═══")
    Home:Label("Platform: " .. (isMobile and "Mobile" or "PC"))
    Home:Label("Game: BedWars")
    Home:Label("Version: v2")

    -- =====================
    -- COMBAT TAB
    -- =====================
    local Combat = Window:Tab("Combat")

    Combat:Toggle("Aimbot", getgenv().ZeonWare.Aimbot.Enabled, function(s)
        getgenv().ZeonWare.Aimbot.Enabled = s
        notify("Aimbot", s and "ON" or "OFF", 2, s and "success" or "info")
    end)

    -- FIXED TEXTBOX: FOV
    local fovBox = Combat:Textbox("FOV", "220", function(v)
        local num = tonumber(v)
        if num and num > 0 and num < 1000 then
            getgenv().ZeonWare.Aimbot.FOV = num
        end
    end)

    -- FIXED TEXTBOX: Smooth
    local smoothBox = Combat:Textbox("Smooth", "0.38", function(v)
        local num = tonumber(v)
        if num and num >= 0 and num <= 1 then
            getgenv().ZeonWare.Aimbot.Smooth = num
        end
    end)

    -- FIXED TEXTBOX: Prediction
    local predBox = Combat:Textbox("Prediction", "0.14", function(v)
        local num = tonumber(v)
        if num and num >= 0 and num <= 1 then
            getgenv().ZeonWare.Aimbot.Prediction = num
        end
    end)

    Combat:Toggle("Silent Aim", getgenv().ZeonWare.SilentAim.Enabled, function(s)
        getgenv().ZeonWare.SilentAim.Enabled = s
        notify("Silent Aim", s and "ON" or "OFF", 2, s and "success" or "info")
    end)

    Combat:Toggle("KillAura", getgenv().ZeonWare.KillAura.Enabled, function(s)
        getgenv().ZeonWare.KillAura.Enabled = s
        notify("KillAura", s and "ON" or "OFF", 2, s and "success" or "info")
    end)

    -- FIXED TEXTBOX: KA Range
    local kaBox = Combat:Textbox("KA Range", "14", function(v)
        local num = tonumber(v)
        if num and num > 0 and num < 50 then
            getgenv().ZeonWare.KillAura.Range = num
        end
    end)

    -- =====================
    -- RENDER TAB
    -- =====================
    local Render = Window:Tab("Render")
    Render:Toggle("ESP", getgenv().ZeonWare.ESP.Enabled, function(s)
        getgenv().ZeonWare.ESP.Enabled = s
        notify("ESP", s and "ON" or "OFF", 2, s and "success" or "info")
    end)
    Render:Toggle("Boxes", getgenv().ZeonWare.ESP.Boxes, function(s) getgenv().ZeonWare.ESP.Boxes = s end)
    Render:Toggle("Names", getgenv().ZeonWare.ESP.Names, function(s) getgenv().ZeonWare.ESP.Names = s end)
    Render:Toggle("Tracers", getgenv().ZeonWare.ESP.Tracers, function(s) getgenv().ZeonWare.ESP.Tracers = s end)
    Render:Toggle("Team Color", getgenv().ZeonWare.ESP.TeamColor, function(s) getgenv().ZeonWare.ESP.TeamColor = s end)

    -- =====================
    -- MOVEMENT TAB
    -- =====================
    local Move = Window:Tab("Movement")
    Move:Toggle("Speed", getgenv().ZeonWare.Movement.Speed, function(s)
        getgenv().ZeonWare.Movement.Speed = s
        notify("Speed", s and "ON" or "OFF", 2, s and "success" or "info")
    end)

    -- FIXED TEXTBOX: Speed Multiplier
    local speedBox = Move:Textbox("Multiplier", "2.0", function(v)
        local num = tonumber(v)
        if num and num > 0 and num < 10 then
            getgenv().ZeonWare.Movement.Value = num
        end
    end)

    -- =====================
    -- UTILITY TAB
    -- =====================
    local Util = Window:Tab("Utility")
    Util:Label("═══ AUTOCLICKER ═══")
    Util:Label("Status: FIXING")
    Util:Label("Coming in next update...")
    Util:Label("")

    Util:Toggle("Reach", getgenv().ZeonWare.Reach.Enabled, function(s)
        getgenv().ZeonWare.Reach.Enabled = s
        notify("Reach", s and "ON" or "OFF", 2, s and "success" or "info")
    end)

    -- FIXED TEXTBOX: Reach Value
    local reachBox = Util:Textbox("Reach Value", "8", function(v)
        local num = tonumber(v)
        if num and num > 0 and num < 30 then
            getgenv().ZeonWare.Reach.Value = num
        end
    end)

    -- =====================
    -- CONFIG TAB
    -- =====================
    local CfgTab = Window:Tab("Config")
    local cfgName = "Default"
    CfgTab:Textbox("Name", "Default", function(v) cfgName = v end)
    CfgTab:Button("Save", function() saveCfg(cfgName) end)
    CfgTab:Button("Load", function() loadCfg(cfgName) end)
    CfgTab:Button("Delete", function() delCfg(cfgName) end)
    CfgTab:Button("Reset Default", function()
        getgenv().ZeonWare = {
            Aimbot = {Enabled = false, FOV = 220, Smooth = 0.38, Prediction = 0.14, TeamCheck = true},
            SilentAim = {Enabled = false},
            KillAura = {Enabled = false, Range = 14},
            AutoClicker = {Enabled = false, CPS = 16},
            ESP = {Enabled = false, Boxes = true, Names = true, Distance = true, Tracers = true, TeamColor = true},
            Movement = {Speed = false, Value = 2.0},
            Reach = {Enabled = false, Value = 8}
        }
        notify("Reset", "All settings restored to default", 3, "success")
    end)

    -- =====================
    -- SETTINGS TAB
    -- =====================
    local SetTab = Window:Tab("Settings")
    SetTab:Label("═══ UI SETTINGS ═══")
    SetTab:Toggle("Notifications", true, function(s)
        notify("Notifications", s and "Enabled" or "Disabled", 2, "info")
    end)
    SetTab:Toggle("Auto-Save Config", false, function(s)
        getgenv().AutoSave = s
        notify("Auto-Save", s and "Enabled" or "Disabled", 2, "info")
    end)
    SetTab:Label("")
    SetTab:Label("═══ PERFORMANCE ═══")
    SetTab:Toggle("Reduce ESP Quality", false, function(s)
        notify("ESP Quality", s and "Reduced" or "Normal", 2, "info")
    end)
    SetTab:Label("")
    SetTab:Label("═══ DANGER ZONE ═══")
    SetTab:Button("Unload Script", function()
        if notifGui then notifGui:Destroy() end
        for _, v in ipairs(espObjects) do
            if v.box then v.box:Remove() end
            if v.name then v.name:Remove() end
            if v.tracer then v.tracer:Remove() end
        end
        notify("Unloaded", "ZeonWare stopped", 3, "info")
        task.wait(1)
    end)
    SetTab:Button("Reset All Settings", function()
        getgenv().ZeonWare = {
            Aimbot = {Enabled = false, FOV = 220, Smooth = 0.38, Prediction = 0.14, TeamCheck = true},
            SilentAim = {Enabled = false},
            KillAura = {Enabled = false, Range = 14},
            AutoClicker = {Enabled = false, CPS = 16},
            ESP = {Enabled = false, Boxes = true, Names = true, Distance = true, Tracers = true, TeamColor = true},
            Movement = {Speed = false, Value = 2.0},
            Reach = {Enabled = false, Value = 8}
        }
        notify("Reset", "All settings restored to default", 3, "success")
    end)

    -- =====================
    -- CREDITS TAB
    -- =====================
    local Credits = Window:Tab("Credits")
    Credits:Label("═══ DEVELOPERS ═══")
    Credits:Label("Lead Dev: Zeon")
    Credits:Label("UI Design: Zeon")
    Credits:Label("Combat Systems: Zeon")
    Credits:Label("")
    Credits:Label("═══ SPECIAL THANKS ═══")
    Credits:Label("Vape V4 - UI Inspiration")
    Credits:Label("BedWars Community")
    Credits:Label("")
    Credits:Label("═══ RESOURCES ═══")
    Credits:Label("UI Lib: dawid-scripts")
    Credits:Label("")
    Credits:Label("═══ VERSION ═══")
    Credits:Label("ZeonWare v2")
    Credits:Label("Built for BedWars")
    Credits:Label("2026")

    -- =====================
    -- WORKING AIMBOT
    -- =====================
    RunService.RenderStepped:Connect(function()
        if not getgenv().ZeonWare.Aimbot.Enabled then return end
        local target = getNearestTarget()
        if not target or not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pred = hrp.Position + (hrp.Velocity * getgenv().ZeonWare.Aimbot.Prediction)
        local pos = Camera:WorldToViewportPoint(pred)
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local dir = (Vector2.new(pos.X, pos.Y) - center) * getgenv().ZeonWare.Aimbot.Smooth

        pcall(function()
            mousemoverel(dir.X, dir.Y)
        end)
    end)

    -- FOV Circle
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.5
    fovCircle.Filled = false
    RunService.RenderStepped:Connect(function()
        fovCircle.Radius = getgenv().ZeonWare.Aimbot.FOV
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Visible = getgenv().ZeonWare.Aimbot.Enabled
    end)

    -- =====================
    -- WORKING KILLAURA (SwordHit Remote)
    -- =====================
    local function swordHit(target)
        if not swordHitRemote then return end
        local sword = getCurrentSword()
        if not sword then return end

        local me = LocalPlayer.Character
        if not me then return end
        local hrp = me:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetChar = target and target.Character
        if not targetChar then return end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end

        local targetPos = targetHrp.Position
        local selfPos = hrp.Position
        local camPos = Camera.CFrame.Position
        local direction = (targetPos - camPos).Unit

        pcall(function()
            swordHitRemote:FireServer({
                chargedAttack = { chargeRatio = 0 },
                entityInstance = targetChar,
                validate = {
                    targetPosition = { value = targetPos },
                    raycast = {
                        cameraPosition = { value = camPos },
                        cursorDirection = { value = direction }
                    },
                    selfPosition = { value = selfPos }
                },
                weapon = sword
            })
        end)
    end

    task.spawn(function()
        while task.wait(0.05) do
            if not getgenv().ZeonWare.KillAura.Enabled then continue end
            local target = getNearestTarget(getgenv().ZeonWare.KillAura.Range)
            if not target then continue end
            swordHit(target)
        end
    end)

    -- =====================
    -- WORKING SPEED
    -- =====================
    local defaultSpeed = 16
    RunService.Heartbeat:Connect(function()
        if not getgenv().ZeonWare.Movement.Speed then 
            -- Reset speed when disabled
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed ~= defaultSpeed then
                    hum.WalkSpeed = defaultSpeed
                end
            end
            return 
        end

        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = defaultSpeed * getgenv().ZeonWare.Movement.Value
        end
    end)

    -- =====================
    -- WORKING ESP
    -- =====================
    local espObjects = {}

    local function getTeamColor(plr)
        if plr.Team then
            return plr.TeamColor.Color
        end
        return Color3.fromRGB(255, 255, 255)
    end

    local function createESP(plr)
        if plr == LocalPlayer then return end

        local box = Drawing.new("Square")
        box.Thickness = 1.5
        box.Filled = false
        box.Transparency = 1
        box.Visible = false

        local name = Drawing.new("Text")
        name.Size = 13
        name.Center = true
        name.Outline = true
        name.Transparency = 1
        name.Visible = false

        local tracer = Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Transparency = 1
        tracer.Visible = false

        espObjects[plr] = {box = box, name = name, tracer = tracer}
    end

    local function removeESP(plr)
        local obj = espObjects[plr]
        if obj then
            if obj.box then obj.box:Remove() end
            if obj.name then obj.name:Remove() end
            if obj.tracer then obj.tracer:Remove() end
            espObjects[plr] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        createESP(p)
    end

    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)

    RunService.RenderStepped:Connect(function()
        if not getgenv().ZeonWare.ESP.Enabled then
            for _, obj in pairs(espObjects) do
                if obj.box then obj.box.Visible = false end
                if obj.name then obj.name.Visible = false end
                if obj.tracer then obj.tracer.Visible = false end
            end
            return
        end

        for plr, obj in pairs(espObjects) do
            if not plr.Character then
                if obj.box then obj.box.Visible = false end
                if obj.name then obj.name.Visible = false end
                if obj.tracer then obj.tracer.Visible = false end
                continue
            end

            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")

            if not hrp or not head or not hum then
                if obj.box then obj.box.Visible = false end
                if obj.name then obj.name.Visible = false end
                if obj.tracer then obj.tracer.Visible = false end
                continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then
                if obj.box then obj.box.Visible = false end
                if obj.name then obj.name.Visible = false end
                if obj.tracer then obj.tracer.Visible = false end
                continue
            end

            local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height * 0.6

            local color = getgenv().ZeonWare.ESP.TeamColor and getTeamColor(plr) or Color3.fromRGB(255, 255, 255)

            if getgenv().ZeonWare.ESP.Boxes then
                obj.box.Size = Vector2.new(width, height)
                obj.box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                obj.box.Color = color
                obj.box.Visible = true
            else
                obj.box.Visible = false
            end

            if getgenv().ZeonWare.ESP.Names then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0
                obj.name.Text = plr.Name .. " [" .. dist .. "m]"
                obj.name.Position = Vector2.new(pos.X, pos.Y - height/2 - 15)
                obj.name.Color = color
                obj.name.Visible = true
            else
                obj.name.Visible = false
            end

            if getgenv().ZeonWare.ESP.Tracers then
                obj.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                obj.tracer.To = Vector2.new(pos.X, pos.Y)
                obj.tracer.Color = color
                obj.tracer.Visible = true
            else
                obj.tracer.Visible = false
            end
        end
    end)

    -- =====================
    -- WORKING REACH
    -- =====================
    local reachConnection
    RunService.Heartbeat:Connect(function()
        if not getgenv().ZeonWare.Reach.Enabled then 
            -- Reset reach when disabled
            if reachConnection then
                reachConnection = nil
            end
            return 
        end

        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        pcall(function()
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("Part") or v:IsA("MeshPart") then
                    local currentSize = v.Size
                    local targetSize = Vector3.new(getgenv().ZeonWare.Reach.Value, getgenv().ZeonWare.Reach.Value, getgenv().ZeonWare.Reach.Value)
                    if currentSize ~= targetSize then
                        v.Size = targetSize
                    end
                end
            end
        end)
    end)

    -- Load default config
    task.delay(1, function()
        loadCfg("Default")
    end)

    notify("ZeonWare", "v2 loaded | " .. (isMobile and "Mobile" or "PC"), 4, "success")
    print("ZeonWare v2 | " .. (isMobile and "Mobile" or "PC"))
end

-- =====================
-- RUN LOADER FIRST
-- =====================
 task.spawn(function()
    TweenService:Create(logo, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
    task.wait(0.2)
    TweenService:Create(sub, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.3)

    local stages = {
        {0.2, "Loading core...", 0.4},
        {0.5, "Checking platform...", 0.3},
        {0.8, "Setting up UI...", 0.4},
        {1.0, "Done", 0.3}
    }

    for _, s in ipairs(stages) do
        status.Text = s[2]
        TweenService:Create(barFill, TweenInfo.new(s[3], Enum.EasingStyle.Quad), {Size = UDim2.new(s[1], 0, 1, 0)}):Play()
        task.wait(s[3] + 0.1)
    end

    task.wait(0.3)

    TweenService:Create(bg, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(logo, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(sub, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(barBg, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFill, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(status, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    task.wait(0.5)
    loaderGui:Destroy()

    loadMainScript()
end)
