--[[
    ╔══════════════════════════════════════════╗
    ║         UNIVERSAL HUB  |  WindUI         ║
    ║         Compatible: PC & Mobile          ║
    ╚══════════════════════════════════════════╝
]]

-- ════════════════════════════════
--  LOAD WindUI
-- ════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ════════════════════════════════
--  SERVICES
-- ════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")

local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

-- ════════════════════════════════
--  ESTADO GLOBAL
-- ════════════════════════════════
local State = {
    -- Troll
    TouchFling    = false,
    AntiFling     = false,

    -- Player
    WalkSpeed     = 16,
    JumpPower     = 50,
    InfiniteJump  = false,

    -- Aimbot
    AimbotEnabled = false,
    TeamCheck     = false,
    AimbotFOV     = 120,
    AimbotSmooth  = 5,

    -- ESP
    ESPEnabled    = false,
    ESPColor      = Color3.fromRGB(255, 50, 50),

    -- Hitbox
    HitboxEnabled = false,
    HitboxSize    = 5,
    HitboxAlpha   = 0.5,
}

-- ════════════════════════════════
--  WINDOW
-- ════════════════════════════════
local Window = WindUI:CreateWindow({
    Title  = "Universal Hub",
    Folder = "UniversalHub",
    Icon   = "solar:planet-bold",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title      = "Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled    = true,
        Draggable  = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#FF6B35"), Color3.fromHex("#F7C59F")),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- ════════════════════════════════
--  SEÇÕES / TABS
-- ════════════════════════════════
local TabTroll    = Window:Tab({ Title = "Troll/Useful", Icon = "solar:bomb-bold",          IconColor = Color3.fromHex("#FF4444") })
local TabScripts  = Window:Tab({ Title = "Scripts",      Icon = "solar:code-square-bold",    IconColor = Color3.fromHex("#44AAFF") })
local TabPlayer   = Window:Tab({ Title = "Player",       Icon = "solar:running-round-bold",  IconColor = Color3.fromHex("#44FF88") })
local TabCombat   = Window:Tab({ Title = "Combat",       Icon = "solar:target-bold",         IconColor = Color3.fromHex("#FFAA44") })
local TabSettings = Window:Tab({ Title = "Settings",     Icon = "solar:settings-bold",       IconColor = Color3.fromHex("#AAAAFF") })

-- ════════════════════════════════
--  HELPERS
-- ════════════════════════════════
local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local c = getCharacter()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildOfClass("Part"))
end

local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isEnemy(player)
    if not State.TeamCheck then return true end
    return player.Team ~= LocalPlayer.Team
end

local function getClosestPlayerInFOV()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end

        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < State.AimbotFOV and dist < closestDist then
            closest     = head
            closestDist = dist
        end
    end
    return closest
end

-- ════════════════════════════════
--  FOV CIRCLE (Drawing API)
-- ════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Radius    = State.AimbotFOV
fovCircle.Color     = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1.5
fovCircle.Filled    = false
fovCircle.Position  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ════════════════════════════════
--  ESP  (Drawing API)
-- ════════════════════════════════
local espLabels = {}

local function cleanESP(player)
    if espLabels[player] then
        espLabels[player]:Remove()
        espLabels[player] = nil
    end
end

local function createESPLabel(player)
    cleanESP(player)
    local label = Drawing.new("Text")
    label.Visible   = false
    label.Color     = State.ESPColor
    label.Size      = 16
    label.Outline   = true
    label.Text      = player.Name
    espLabels[player] = label
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPLabel(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    createESPLabel(player)
end)

Players.PlayerRemoving:Connect(function(player)
    cleanESP(player)
end)

-- ════════════════════════════════
--  HITBOX STORAGE
-- ════════════════════════════════
local hitboxParts = {}

local function removeHitbox(player)
    if hitboxParts[player] then
        pcall(function() hitboxParts[player]:Destroy() end)
        hitboxParts[player] = nil
    end
end

local function applyHitbox(player)
    removeHitbox(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local part = Instance.new("Part")
    part.Name      = "HitboxExpand"
    part.Size      = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
    part.Anchored  = false
    part.CanCollide = false
    part.Massless  = true
    part.Transparency = State.HitboxAlpha
    part.BrickColor  = BrickColor.new("Bright red")
    part.Material    = Enum.Material.ForceField
    part.Parent      = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = root
    weld.Part1  = part
    weld.Parent = part

    hitboxParts[player] = part
end

local function refreshHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if State.HitboxEnabled then
                applyHitbox(player)
            else
                removeHitbox(player)
            end
        end
    end
end

-- ════════════════════════════════
--  RUNSERVICE LOOP
-- ════════════════════════════════
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if State.AimbotEnabled then
        local target = getClosestPlayerInFOV()
        if target then
            local alpha = 1 / (State.AimbotSmooth + 1)
            local current = Camera.CFrame
            local lookAt  = CFrame.lookAt(current.Position, target.Position)
            Camera.CFrame = current:Lerp(lookAt, alpha)
        end
    end

    -- FOV Circle update
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius   = State.AimbotFOV
    fovCircle.Visible  = State.AimbotEnabled

    -- ESP Update
    for _, player in ipairs(Players:GetPlayers()) do
        local label = espLabels[player]
        if not label then continue end

        if not State.ESPEnabled then
            label.Visible = false
            continue
        end

        local char = player.Character
        if not char then label.Visible = false; continue end
        local head = char:FindFirstChild("Head")
        if not head then label.Visible = false; continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        if onScreen then
            label.Position = Vector2.new(screenPos.X, screenPos.Y)
            label.Color    = State.ESPColor
            label.Visible  = true
        else
            label.Visible = false
        end
    end
end)

-- ════════════════════════════════
--  TOUCH FLING
-- ════════════════════════════════
local touchFlingConn = nil

local function startTouchFling()
    if touchFlingConn then return end
    touchFlingConn = RunService.Heartbeat:Connect(function()
        local root = getRootPart()
        if not root then return end
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part ~= root then
                local dist = (part.Position - root.Position).Magnitude
                if dist < 5 then
                    local vel = Instance.new("BodyVelocity")
                    vel.Velocity    = (part.Position - root.Position).Unit * -500
                    vel.MaxForce    = Vector3.new(1e9, 1e9, 1e9)
                    vel.P           = 1e9
                    vel.Parent      = part
                    game:GetService("Debris"):AddItem(vel, 0.1)
                end
            end
        end
    end)
end

local function stopTouchFling()
    if touchFlingConn then
        touchFlingConn:Disconnect()
        touchFlingConn = nil
    end
end

-- ════════════════════════════════
--  ANTI-FLING
-- ════════════════════════════════
local antiFlingConn = nil

local function startAntiFling()
    if antiFlingConn then return end
    antiFlingConn = RunService.Heartbeat:Connect(function()
        local char = getCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local vel = part.AssemblyLinearVelocity
                if vel.Magnitude > 200 then
                    part.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function stopAntiFling()
    if antiFlingConn then
        antiFlingConn:Disconnect()
        antiFlingConn = nil
    end
end

-- ════════════════════════════════
--  INFINITE JUMP
-- ════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ════════════════════════════════
--  CHARACTER RESPAWN HANDLER
-- ════════════════════════════════
local function onCharacterAdded(char)
    char:WaitForChild("Humanoid", 5)

    -- Reaplica WalkSpeed/JumpPower
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end

    -- Reaplica hitbox para os outros
    if State.HitboxEnabled then
        refreshHitboxes()
    end

    -- Reinicia ESP labels para que picks up o novo estado
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not espLabels[player] then
            createESPLabel(player)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if State.HitboxEnabled then
            task.wait(1)
            applyHitbox(player)
        end
    end)
end)

-- ════════════════════════════════════════════════
--  ABA: TROLL / USEFUL
-- ════════════════════════════════════════════════
do
    local SecTroll = TabTroll:Section({ Title = "Fling" })

    SecTroll:Toggle({
        Title    = "Touch Fling",
        Desc     = "Aplica força nos objetos próximos ao tocar",
        Value    = false,
        Callback = function(v)
            State.TouchFling = v
            if v then startTouchFling() else stopTouchFling() end
        end
    })

    TabTroll:Space()

    local SecAnti = TabTroll:Section({ Title = "Proteção" })

    SecAnti:Button({
        Title    = "Anti-Fling",
        Icon     = "shield",
        Desc     = "Ativa proteção contra velocity anormal",
        Justify  = "Center",
        Callback = function()
            State.AntiFling = not State.AntiFling
            if State.AntiFling then
                startAntiFling()
                WindUI:Notify({ Title = "Anti-Fling", Content = "Ativado!", Icon = "shield" })
            else
                stopAntiFling()
                WindUI:Notify({ Title = "Anti-Fling", Content = "Desativado!", Icon = "shield-off" })
            end
        end
    })

    TabTroll:Space()

    local SecTools = TabTroll:Section({ Title = "Tools" })

    SecTools:Button({
        Title    = "Instant Interact",
        Icon     = "zap",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://pastefy.app/vg1Ap8MO/raw"))()
        end
    })

    TabTroll:Space()

    SecTools:Button({
        Title    = "Destroy Tool",
        Icon     = "trash-2",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-destroy-tool-31432"))()
        end
    })

    TabTroll:Space()

    SecTools:Button({
        Title    = "Fly Tool",
        Icon     = "wind",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Fly-tween-CoiledTom-/refs/heads/main/fly%20tween"))()
        end
    })

    TabTroll:Space()

    SecTools:Button({
        Title    = "F3X Tool",
        Icon     = "box",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-F3X-Tool-44387"))()
        end
    })

    TabTroll:Space()

    SecTools:Button({
        Title    = "Shift Lock",
        Icon     = "lock",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Shift-Lock-CoiledTom-/refs/heads/main/shift%20Lock%20CoiledTom"))()
        end
    })
end

-- ════════════════════════════════════════════════
--  ABA: SCRIPTS (GUIs)
-- ════════════════════════════════════════════════
do
    local SecGUI = TabScripts:Section({ Title = "GUIs Externas" })

    SecGUI:Button({
        Title    = "Fly GUI",
        Icon     = "airplay",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Fly-gui/refs/heads/main/%25"))()
        end
    })

    TabScripts:Space()

    SecGUI:Button({
        Title    = "Refast GUI",
        Icon     = "activity",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Refast-CoiledTom-/refs/heads/main/refast%20CoiledTom"))()
        end
    })

    TabScripts:Space()

    SecGUI:Button({
        Title    = "Speed GUI",
        Icon     = "zap",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Speed-CoiledTom-/refs/heads/main/speed%20CoiledTom"))()
        end
    })

    TabScripts:Space()

    SecGUI:Button({
        Title    = "Waypoint GUI",
        Icon     = "map-pin",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/CoiledTom/Way-point-universal-/refs/heads/main/Teleport%2Btween"))()
        end
    })

    TabScripts:Space()

    SecGUI:Button({
        Title    = "Speed X Hub",
        Icon     = "rocket",
        Justify  = "Center",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua"))()
        end
    })
end

-- ════════════════════════════════════════════════
--  ABA: PLAYER
-- ════════════════════════════════════════════════
do
    local SecPlayer = TabPlayer:Section({ Title = "Movimento" })

    SecPlayer:Slider({
        Flag     = "WalkSpeed",
        Title    = "WalkSpeed",
        Desc     = "Velocidade de caminhada",
        Step     = 1,
        Value    = { Min = 0, Max = 500, Default = 16 },
        Callback = function(v)
            State.WalkSpeed = v
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = v end
        end
    })

    TabPlayer:Space()

    SecPlayer:Slider({
        Flag     = "JumpPower",
        Title    = "JumpPower",
        Desc     = "Altura do pulo",
        Step     = 1,
        Value    = { Min = 0, Max = 500, Default = 50 },
        Callback = function(v)
            State.JumpPower = v
            local hum = getHumanoid()
            if hum then hum.JumpPower = v end
        end
    })

    TabPlayer:Space()

    local SecJump = TabPlayer:Section({ Title = "Pulo" })

    SecJump:Toggle({
        Flag     = "InfiniteJump",
        Title    = "Infinite Jump",
        Desc     = "Pula no ar indefinidamente",
        Value    = false,
        Callback = function(v)
            State.InfiniteJump = v
        end
    })
end

-- ════════════════════════════════════════════════
--  ABA: COMBAT
-- ════════════════════════════════════════════════
do
    -- ── AIMBOT ──────────────────────────────────
    local SecAimbot = TabCombat:Section({ Title = "Aimbot" })

    SecAimbot:Toggle({
        Flag     = "AimbotEnabled",
        Title    = "Aimbot",
        Desc     = "Mira automática no jogador mais próximo",
        Value    = false,
        Callback = function(v)
            State.AimbotEnabled = v
        end
    })

    TabCombat:Space()

    SecAimbot:Toggle({
        Flag     = "TeamCheck",
        Title    = "Team Check",
        Desc     = "Não mira em aliados",
        Value    = false,
        Callback = function(v)
            State.TeamCheck = v
        end
    })

    TabCombat:Space()

    SecAimbot:Slider({
        Flag     = "AimbotFOV",
        Title    = "FOV",
        Desc     = "Raio de alcance do aimbot (pixels)",
        Step     = 1,
        Value    = { Min = 10, Max = 500, Default = 120 },
        Callback = function(v)
            State.AimbotFOV = v
            fovCircle.Radius = v
        end
    })

    TabCombat:Space()

    SecAimbot:Slider({
        Flag     = "AimbotSmooth",
        Title    = "Smoothness",
        Desc     = "Suavidade da mira (maior = mais suave)",
        Step     = 1,
        Value    = { Min = 1, Max = 20, Default = 5 },
        Callback = function(v)
            State.AimbotSmooth = v
        end
    })

    TabCombat:Space()

    -- ── ESP ─────────────────────────────────────
    local SecESP = TabCombat:Section({ Title = "ESP" })

    SecESP:Toggle({
        Flag     = "ESPEnabled",
        Title    = "ESP",
        Desc     = "Mostra nome dos jogadores através das paredes",
        Value    = false,
        Callback = function(v)
            State.ESPEnabled = v
            if not v then
                for _, label in pairs(espLabels) do
                    label.Visible = false
                end
            end
        end
    })

    TabCombat:Space()

    SecESP:Colorpicker({
        Flag     = "ESPColor",
        Title    = "Cor do ESP",
        Default  = Color3.fromRGB(255, 50, 50),
        Callback = function(color)
            State.ESPColor = color
        end
    })

    TabCombat:Space()

    -- ── HITBOX ──────────────────────────────────
    local SecHitbox = TabCombat:Section({ Title = "Hitbox Expander" })

    SecHitbox:Toggle({
        Flag     = "HitboxEnabled",
        Title    = "Hitbox Expander",
        Desc     = "Aumenta a hitbox dos jogadores",
        Value    = false,
        Callback = function(v)
            State.HitboxEnabled = v
            refreshHitboxes()
        end
    })

    TabCombat:Space()

    SecHitbox:Slider({
        Flag     = "HitboxSize",
        Title    = "Tamanho",
        Desc     = "Tamanho da hitbox expandida",
        Step     = 0.5,
        Value    = { Min = 1, Max = 30, Default = 5 },
        Callback = function(v)
            State.HitboxSize = v
            if State.HitboxEnabled then refreshHitboxes() end
        end
    })

    TabCombat:Space()

    SecHitbox:Slider({
        Flag     = "HitboxAlpha",
        Title    = "Transparência",
        Desc     = "Transparência da hitbox (0 = sólida, 1 = invisível)",
        Step     = 0.05,
        Value    = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v)
            State.HitboxAlpha = v
            for _, part in pairs(hitboxParts) do
                part.Transparency = v
            end
        end
    })
end

-- ════════════════════════════════════════════════
--  ABA: SETTINGS
-- ════════════════════════════════════════════════
do
    local SecSave = TabSettings:Section({ Title = "Configuração" })

    SecSave:Button({
        Title    = "Salvar Config",
        Icon     = "save",
        Justify  = "Center",
        Desc     = "Salva todas as configurações em arquivo local",
        Callback = function()
            local ok, err = pcall(function()
                local data = {
                    WalkSpeed     = State.WalkSpeed,
                    JumpPower     = State.JumpPower,
                    InfiniteJump  = State.InfiniteJump,
                    AimbotEnabled = State.AimbotEnabled,
                    TeamCheck     = State.TeamCheck,
                    AimbotFOV     = State.AimbotFOV,
                    AimbotSmooth  = State.AimbotSmooth,
                    ESPEnabled    = State.ESPEnabled,
                    HitboxEnabled = State.HitboxEnabled,
                    HitboxSize    = State.HitboxSize,
                    HitboxAlpha   = State.HitboxAlpha,
                    ESPColor      = { State.ESPColor.R, State.ESPColor.G, State.ESPColor.B },
                }
                local json = HttpService:JSONEncode(data)
                writefile("UniversalHub_Config.json", json)
            end)

            if ok then
                WindUI:Notify({
                    Title   = "Config Salva",
                    Content = "Configurações salvas em 'UniversalHub_Config.json'",
                    Icon    = "check-circle",
                    Duration = 4,
                })
            else
                WindUI:Notify({
                    Title   = "Erro ao Salvar",
                    Content = tostring(err),
                    Icon    = "alert-triangle",
                    Duration = 5,
                })
            end
        end
    })

    TabSettings:Space()

    local SecKeybind = TabSettings:Section({ Title = "Atalhos" })

    SecKeybind:Keybind({
        Flag     = "ToggleUI",
        Title    = "Toggle UI",
        Desc     = "Tecla para abrir/fechar o hub",
        Value    = "RightShift",
        Callback = function(v)
            local ok = pcall(function()
                Window:SetToggleKey(Enum.KeyCode[v])
            end)
        end
    })

    TabSettings:Space()

    local SecInfo = TabSettings:Section({ Title = "Informações" })

    SecInfo:Section({
        Title = "Universal Hub  |  WindUI\nFeito com WindUI por Footagesus\nCompatível com PC e Mobile",
        TextSize = 14,
        TextTransparency = 0.3,
    })
end

-- ════════════════════════════════
--  NOTIFICAÇÃO INICIAL
-- ════════════════════════════════
WindUI:Notify({
    Title    = "Universal Hub",
    Content  = "Hub carregado com sucesso! Bem-vindo.",
    Icon     = "solar:planet-bold",
    Duration = 5,
})
