-- FPS Booster v3

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local suppressNotify = false
local function notify(t, m)
    if suppressNotify then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=m, Duration=3})
    end)
end

local C = {
    bg     = Color3.fromRGB(10, 10, 16),
    panel  = Color3.fromRGB(16, 16, 26),
    row    = Color3.fromRGB(22, 22, 36),
    accent = Color3.fromRGB(80, 255, 160),
    red    = Color3.fromRGB(200, 45, 45),
    yellow = Color3.fromRGB(255, 200, 60),
    orange = Color3.fromRGB(255, 140, 40),
    text   = Color3.fromRGB(220, 220, 230),
    sub    = Color3.fromRGB(100, 100, 130),
    blue   = Color3.fromRGB(40, 100, 200),
}

local originals = {
    globalShadows = Lighting.GlobalShadows,
    fogEnd        = Lighting.FogEnd,
    fogStart      = Lighting.FogStart,
    partMaterials = {},
}
-- chunked across frames so it doesn't spike on load
task.spawn(function()
    local descendants = workspace:GetDescendants()
    for i, obj in ipairs(descendants) do
        if obj:IsA("BasePart") then
            originals.partMaterials[obj] = obj.Material
        end
        if i % 200 == 0 then task.wait() end
    end
end)

-- declared early so checkPerformance and the FPS counter share it
local fpsBuffer = {}

-- ===== BOOST FUNCTIONS =====

local shadowsOff = false
local function toggleShadows(on)
    shadowsOff = on
    Lighting.GlobalShadows = not on
    notify("FPS Boost", on and "Shadows OFF" or "Shadows restored")
end

local effectsOff = false
local function toggleEffects(on)
    effectsOff = on
    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then pcall(function() e.Enabled = not on end) end
    end
    for _, e in pairs(workspace:GetDescendants()) do
        if e:IsA("PostEffect") or e:IsA("ParticleEmitter") or e:IsA("Trail") or e:IsA("Beam") then
            pcall(function() e.Enabled = not on end)
        end
    end
    notify("FPS Boost", on and "Post Effects OFF" or "Post Effects restored")
end

local fogOff = false
local function toggleFog(on)
    fogOff = on
    if on then
        Lighting.FogEnd = 100000; Lighting.FogStart = 99999
    else
        Lighting.FogEnd = originals.fogEnd; Lighting.FogStart = originals.fogStart
    end
    notify("FPS Boost", on and "Fog OFF" or "Fog restored")
end

local atmosphereOff = false
local savedAtmosphere = nil
local function toggleAtmosphere(on)
    atmosphereOff = on
    if on then
        for _, e in pairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") then savedAtmosphere = e; e.Parent = nil end
        end
        notify("FPS Boost", "Atmosphere OFF")
    else
        if savedAtmosphere then savedAtmosphere.Parent = Lighting end
        notify("FPS Boost", "Atmosphere restored")
    end
end

local texturesOff = false
local function toggleTextures(on)
    texturesOff = on
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                if on then
                    obj.Material = Enum.Material.SmoothPlastic
                else
                    local s = originals.partMaterials[obj]
                    if s then obj.Material = s end
                end
            end)
        end
        if obj:IsA("Texture") or obj:IsA("Decal") then
            pcall(function() obj.Transparency = on and 1 or 0 end)
        end
    end
    notify("FPS Boost", on and "Textures OFF" or "Textures restored")
end

local playersHidden = false
local function togglePlayers(on)
    playersHidden = on
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                pcall(function()
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.LocalTransparencyModifier = on and 1 or 0
                    end
                end)
            end
        end
    end
    notify("FPS Boost", on and "Other players hidden" or "Players visible")
end
Players.PlayerAdded:Connect(function(player)
    if not playersHidden then return end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        for _, part in pairs(char:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.LocalTransparencyModifier = 1
                end
            end)
        end
    end)
end)

local decorationsOff = false
local function toggleDecorations(on)
    decorationsOff = on
    local localChar = LocalPlayer.Character or Instance.new("Model")
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) and not obj:IsDescendantOf(localChar) then
            pcall(function() obj.Enabled = not on end)
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = not on end)
        end
    end
    notify("FPS Boost", on and "Decorations/Particles OFF" or "Decorations restored")
end

local function setGraphicsLevel(level)
    pcall(function() settings().Rendering.QualityLevel = level end)
    notify("FPS Boost", "Graphics set to level "..level)
end

local skyOff = false
local savedSky = nil
local function toggleSky(on)
    skyOff = on
    if on then
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then savedSky = obj; obj.Parent = nil end
        end
        notify("FPS Boost", "Sky OFF")
    else
        if savedSky then savedSky.Parent = Lighting end
        notify("FPS Boost", "Sky restored")
    end
end

local function unlockFPS()
    if setfpscap then setfpscap(0)
    else pcall(function() settings().Rendering.FrameRateManager = 0 end) end
    notify("FPS Boost", "FPS unlocked!")
end

-- ===== PERFORMANCE CHECK =====
local function checkPerformance()
    local sum = 0
    for _, v in ipairs(fpsBuffer) do sum = sum + v end
    local avg = math.floor(sum / math.max(1, #fpsBuffer))
    if avg >= 55 then
        if math.random(100) == 1 then
            notify("Performance", "your computer is shit, brokie.")
        else
            notify("Performance", "Roblox is running fine! Might be something on your computer.")
        end
    elseif avg >= 30 then
        notify("Performance", "Moderate FPS ("..avg.."). Try enabling more boosts.")
    else
        notify("Performance", "Low FPS ("..avg.."). Enable all boosts or lower graphics.")
    end
    return avg
end

-- ===== LAG SPY =====
local function scanLag()
    local c = {parts=0, particles=0, lights=0, decals=0, meshes=0}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then c.parts += 1 end
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then c.particles += 1 end
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then c.lights += 1 end
        if obj:IsA("Decal") or obj:IsA("Texture") then c.decals += 1 end
        if obj:IsA("SpecialMesh") or obj:IsA("FileMesh") then c.meshes += 1 end
    end
    local function sev(v, med, high)
        if v >= high then return "HIGH", C.red
        elseif v >= med then return "MED", C.yellow
        else return "OK", C.accent end
    end
    local results = {}
    local function add(label, val, med, high, fix)
        local s, col = sev(val, med, high)
        table.insert(results, {label=label, count=val, severity=s, color=col, fix=fix})
    end
    add("Parts",             c.parts,     3000, 8000, nil)
    add("Particles/Effects", c.particles, 50,   200,  "particles")
    add("Dynamic Lights",    c.lights,    100,  300,  "lights")
    add("Decals/Textures",   c.decals,    200,  600,  "textures")
    add("Meshes",            c.meshes,    400,  1000, nil)
    return results
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "FPSBooster"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 50
pcall(function() gui.Parent = game:GetService("CoreGui") end)

local Pill = Instance.new("Frame")
Pill.Size = UDim2.new(0,160,0,36)
Pill.Position = UDim2.new(0,20,0,20)
Pill.BackgroundColor3 = C.bg
Pill.BorderSizePixel = 0
Pill.Active = true
Pill.ZIndex = 10
Pill.Parent = gui
Instance.new("UICorner",Pill).CornerRadius = UDim.new(0,10)
local pillS = Instance.new("UIStroke")
pillS.Color = Color3.fromRGB(50,50,70)
pillS.Parent = Pill

local PillBtn = Instance.new("TextButton")
PillBtn.Size = UDim2.new(1,0,1,0)
PillBtn.BackgroundTransparency = 1
PillBtn.TextColor3 = C.sub
PillBtn.Font = Enum.Font.GothamBold
PillBtn.TextSize = 12
PillBtn.Text = "⚡ FPS Booster"
PillBtn.ZIndex = 11
PillBtn.Parent = Pill

local pd,pds,pfs = false,nil,nil
Pill.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then pd=true; pds=i.Position; pfs=Pill.Position end
end)
Pill.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then pd=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if pd and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - pds
        Pill.Position = UDim2.new(pfs.X.Scale, pfs.X.Offset+d.X, pfs.Y.Scale, pfs.Y.Offset+d.Y)
    end
end)

local Win = Instance.new("Frame")
Win.Size = UDim2.new(0,300,0,520)
Win.Position = UDim2.new(0,20,0,62)
Win.BackgroundColor3 = C.bg
Win.BorderSizePixel = 0
Win.Active = true
Win.Visible = false
Win.ZIndex = 10
Win.Parent = gui
Instance.new("UICorner",Win).CornerRadius = UDim.new(0,14)
local winS = Instance.new("UIStroke")
winS.Color = C.accent; winS.Thickness = 1.5; winS.Parent = Win

local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1,0,0,38)
TBar.BackgroundColor3 = C.panel
TBar.BorderSizePixel = 0; TBar.ZIndex = 11; TBar.Parent = Win
Instance.new("UICorner",TBar).CornerRadius = UDim.new(0,14)
local TFix = Instance.new("Frame")
TFix.Size = UDim2.new(1,0,0.5,0); TFix.Position = UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3 = C.panel; TFix.BorderSizePixel = 0; TFix.ZIndex = 11; TFix.Parent = TBar

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1,-100,1,0); TTitle.Position = UDim2.new(0,12,0,0)
TTitle.BackgroundTransparency = 1; TTitle.TextColor3 = C.accent
TTitle.Font = Enum.Font.GothamBlack; TTitle.TextSize = 14
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Text = "⚡ FPS Booster"; TTitle.ZIndex = 12; TTitle.Parent = TBar

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0,50,1,0); FPSLabel.Position = UDim2.new(1,-84,0,0)
FPSLabel.BackgroundTransparency = 1; FPSLabel.TextColor3 = C.accent
FPSLabel.Font = Enum.Font.GothamBold; FPSLabel.TextSize = 11
FPSLabel.Text = "-- FPS"; FPSLabel.ZIndex = 12; FPSLabel.Parent = TBar

-- settings gear in title bar
local GearBtn = Instance.new("TextButton")
GearBtn.Size = UDim2.new(0,28,0,28); GearBtn.Position = UDim2.new(1,-32,0.5,-14)
GearBtn.BackgroundTransparency = 1
GearBtn.TextColor3 = C.sub; GearBtn.Font = Enum.Font.GothamBold
GearBtn.TextSize = 16; GearBtn.Text = "⚙"
GearBtn.ZIndex = 12; GearBtn.Parent = TBar

-- main scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,-38); Scroll.Position = UDim2.new(0,0,0,38)
Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3; Scroll.ScrollBarImageColor3 = C.accent
Scroll.CanvasSize = UDim2.new(0,0,0,0); Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ZIndex = 11; Scroll.Parent = Win
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,4); Layout.Parent = Scroll
local scrollPad = Instance.new("UIPadding", Scroll)
scrollPad.PaddingTop = UDim.new(0,8); scrollPad.PaddingLeft = UDim.new(0,8)
scrollPad.PaddingRight = UDim.new(0,8); scrollPad.PaddingBottom = UDim.new(0,8)

-- settings overlay (same size as scroll area, sits on top)
local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Size = UDim2.new(1,0,1,-38); SettingsPage.Position = UDim2.new(0,0,0,38)
SettingsPage.BackgroundColor3 = C.bg; SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 3; SettingsPage.ScrollBarImageColor3 = C.accent
SettingsPage.CanvasSize = UDim2.new(0,0,0,0); SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsPage.Visible = false; SettingsPage.ZIndex = 14; SettingsPage.Parent = Win
local SPLayout = Instance.new("UIListLayout")
SPLayout.Padding = UDim.new(0,6); SPLayout.Parent = SettingsPage
local spPad = Instance.new("UIPadding", SettingsPage)
spPad.PaddingTop = UDim.new(0,10); spPad.PaddingLeft = UDim.new(0,10)
spPad.PaddingRight = UDim.new(0,10); spPad.PaddingBottom = UDim.new(0,10)

-- ===== UI BUILDERS =====
local function sectionLabel(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,16)
    l.BackgroundTransparency = 1; l.TextColor3 = C.sub
    l.Font = Enum.Font.GothamBold; l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "── "..text:upper().." ──"
    l.ZIndex = 15; l.Parent = parent
    return l
end

local function makeToggleRow(icon, label, desc, onFn, offFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,52); row.BackgroundColor3 = C.row
    row.BorderSizePixel = 0; row.ZIndex = 12; row.Parent = Scroll
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

    local ico = Instance.new("TextLabel")
    ico.Size = UDim2.new(0,30,1,0); ico.Position = UDim2.new(0,4,0,0)
    ico.BackgroundTransparency = 1; ico.TextSize = 18
    ico.Font = Enum.Font.GothamBold; ico.Text = icon
    ico.ZIndex = 13; ico.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-90,0,22); lbl.Position = UDim2.new(0,36,0,4)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.ZIndex = 13; lbl.Parent = row

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1,-90,0,16); descLbl.Position = UDim2.new(0,36,0,28)
    descLbl.BackgroundTransparency = 1; descLbl.TextColor3 = C.sub
    descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 9
    descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextWrapped = true
    descLbl.Text = desc; descLbl.ZIndex = 13; descLbl.Parent = row

    local isOn = false
    local togBtn = Instance.new("TextButton")
    togBtn.Size = UDim2.new(0,54,0,26); togBtn.Position = UDim2.new(1,-60,0.5,-13)
    togBtn.BackgroundColor3 = C.row; togBtn.TextColor3 = C.sub
    togBtn.Font = Enum.Font.GothamBold; togBtn.TextSize = 10
    togBtn.Text = "OFF"; togBtn.BorderSizePixel = 0; togBtn.ZIndex = 13; togBtn.Parent = row
    Instance.new("UICorner",togBtn).CornerRadius = UDim.new(0,6)
    local togStroke = Instance.new("UIStroke")
    togStroke.Color = C.sub; togStroke.Thickness = 1; togStroke.Parent = togBtn

    local function setOn(state)
        isOn = state
        if state then
            togBtn.Text = "ON"; togBtn.TextColor3 = C.accent
            togBtn.BackgroundColor3 = Color3.fromRGB(20,50,35)
            togStroke.Color = C.accent
            onFn()
        else
            togBtn.Text = "OFF"; togBtn.TextColor3 = C.sub
            togBtn.BackgroundColor3 = C.row; togStroke.Color = C.sub
            offFn()
        end
    end

    togBtn.MouseButton1Click:Connect(function() setOn(not isOn) end)
    return row, setOn
end

local function makeBtn(parent, text, color, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,30); b.BackgroundColor3 = color or C.blue
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
    b.TextSize = 12; b.Text = text; b.BorderSizePixel = 0
    b.ZIndex = 15; b.Parent = parent
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,7)
    if fn then b.MouseButton1Click:Connect(fn) end
    return b
end

-- ===== BUILD MAIN UI =====
sectionLabel(Scroll, "Visual Boosts")

local _, setShadows    = makeToggleRow("🌑","Shadows","Removes all shadows from the game",               function() toggleShadows(true)     end, function() toggleShadows(false)     end)
local _, setEffects    = makeToggleRow("✨","Post Effects","Removes bloom, blur, color correction",       function() toggleEffects(true)     end, function() toggleEffects(false)     end)
local _, setFog        = makeToggleRow("🌫️","Fog","Removes distance fog",                               function() toggleFog(true)         end, function() toggleFog(false)         end)
local _, setAtmosphere = makeToggleRow("🌤️","Atmosphere","Removes sky atmosphere effects",              function() toggleAtmosphere(true)  end, function() toggleAtmosphere(false)  end)
local _, setSky        = makeToggleRow("🌌","Sky","Removes sky box",                                    function() toggleSky(true)         end, function() toggleSky(false)         end)
local _, setTextures   = makeToggleRow("🖼️","Textures","Makes all parts smooth plastic, hides decals", function() toggleTextures(true)    end, function() toggleTextures(false)    end)
local _, setParticles  = makeToggleRow("🎆","Particles","Removes fire, smoke, sparkles, trails",        function() toggleDecorations(true) end, function() toggleDecorations(false) end)
local _, setPlayers    = makeToggleRow("👥","Other Players","Hides other player characters",            function() togglePlayers(true)     end, function() togglePlayers(false)     end)

sectionLabel(Scroll, "Graphics Level")

local gfxRow = Instance.new("Frame")
gfxRow.Size = UDim2.new(1,0,0,30); gfxRow.BackgroundTransparency = 1
gfxRow.ZIndex = 12; gfxRow.Parent = Scroll
local gfxLayout = Instance.new("UIListLayout")
gfxLayout.FillDirection = Enum.FillDirection.Horizontal
gfxLayout.Padding = UDim.new(0,4); gfxLayout.Parent = gfxRow

local levels = {1,2,3,5,10,21}
local levelLabels = {"1","2","3","5","10","Max"}
for i, level in ipairs(levels) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,40,1,0); b.BackgroundColor3 = C.row; b.TextColor3 = C.text
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Text = levelLabels[i]
    b.BorderSizePixel = 0; b.ZIndex = 13; b.Parent = gfxRow
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        setGraphicsLevel(level)
        for _, child in pairs(gfxRow:GetChildren()) do
            if child:IsA("TextButton") then child.BackgroundColor3 = C.row; child.TextColor3 = C.text end
        end
        b.BackgroundColor3 = C.blue; b.TextColor3 = Color3.new(1,1,1)
    end)
end

sectionLabel(Scroll, "Quick Actions")

makeBtn(Scroll, "⚡ Unlock FPS Cap", C.accent:Lerp(Color3.new(0,0,0),0.3), unlockFPS)

makeBtn(Scroll, "🔥 Apply ALL Boosts", C.accent:Lerp(Color3.new(0,0,0),0.4), function()
    suppressNotify = true
    setShadows(true); setEffects(true); setFog(true); setAtmosphere(true)
    setSky(true); setTextures(true); setParticles(true); setPlayers(true)
    setGraphicsLevel(1); unlockFPS()
    suppressNotify = false
    notify("FPS Boost", "All boosts applied!")
end)

makeBtn(Scroll, "↩️ Restore Everything", C.red, function()
    suppressNotify = true
    setShadows(false); setEffects(false); setFog(false); setAtmosphere(false)
    setSky(false); setTextures(false); setParticles(false); setPlayers(false)
    setGraphicsLevel(21)
    suppressNotify = false
    notify("FPS Boost", "Everything restored!")
end)

-- ===== SETTINGS PAGE =====
sectionLabel(SettingsPage, "Lag Spy")

-- results list, populated after scan
local lagResultsFrame = Instance.new("Frame")
lagResultsFrame.Size = UDim2.new(1,0,0,0)
lagResultsFrame.AutomaticSize = Enum.AutomaticSize.Y
lagResultsFrame.BackgroundTransparency = 1
lagResultsFrame.ZIndex = 15; lagResultsFrame.Parent = SettingsPage
local lrLayout = Instance.new("UIListLayout")
lrLayout.Padding = UDim.new(0,3); lrLayout.Parent = lagResultsFrame

local function buildLagResultsUI(results)
    for _, child in pairs(lagResultsFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, r in ipairs(results) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,28); row.BackgroundColor3 = C.row
        row.BorderSizePixel = 0; row.ZIndex = 16; row.Parent = lagResultsFrame
        Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.6,0,1,0); nameLbl.Position = UDim2.new(0,8,0,0)
        nameLbl.BackgroundTransparency = 1; nameLbl.TextColor3 = C.text
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 10
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Text = r.label; nameLbl.ZIndex = 17; nameLbl.Parent = row

        local countLbl = Instance.new("TextLabel")
        countLbl.Size = UDim2.new(0.2,0,1,0); countLbl.Position = UDim2.new(0.6,0,0,0)
        countLbl.BackgroundTransparency = 1; countLbl.TextColor3 = C.sub
        countLbl.Font = Enum.Font.Gotham; countLbl.TextSize = 10
        countLbl.Text = tostring(r.count); countLbl.ZIndex = 17; countLbl.Parent = row

        local sevLbl = Instance.new("TextLabel")
        sevLbl.Size = UDim2.new(0.2,0,1,0); sevLbl.Position = UDim2.new(0.8,0,0,0)
        sevLbl.BackgroundTransparency = 1; sevLbl.TextColor3 = r.color
        sevLbl.Font = Enum.Font.GothamBold; sevLbl.TextSize = 9
        sevLbl.Text = r.severity; sevLbl.ZIndex = 17; sevLbl.Parent = row
    end
end

makeBtn(SettingsPage, "🔍 Scan for Lag Sources", C.blue, function()
    local results = scanLag()
    buildLagResultsUI(results)
    notify("Lag Spy", "Scan complete!")
end)

makeBtn(SettingsPage, "⚡ Auto-Limit Lag Sources", C.orange, function()
    local results = scanLag()
    local fixed = 0
    for _, r in ipairs(results) do
        if r.severity ~= "OK" then
            if r.fix == "particles" then setParticles(true); fixed += 1
            elseif r.fix == "textures" then setTextures(true); fixed += 1
            elseif r.fix == "lights" then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                        pcall(function() obj.Enabled = false end)
                    end
                end
                fixed += 1
            end
        end
    end
    notify("Lag Spy", fixed > 0 and (fixed.." source(s) limited!") or "No major lag sources found.")
end)

sectionLabel(SettingsPage, "Performance")

-- inline result label updated by the check button
local perfLbl = Instance.new("TextLabel")
perfLbl.Size = UDim2.new(1,0,0,26); perfLbl.BackgroundColor3 = C.row
perfLbl.TextColor3 = C.sub; perfLbl.Font = Enum.Font.GothamBold; perfLbl.TextSize = 10
perfLbl.Text = "Press check to analyze"; perfLbl.ZIndex = 15; perfLbl.Parent = SettingsPage
Instance.new("UICorner",perfLbl).CornerRadius = UDim.new(0,6)

makeBtn(SettingsPage, "📊 Check Performance", C.blue, function()
    local avg = checkPerformance()
    if avg >= 55 then
        perfLbl.TextColor3 = C.accent
        perfLbl.Text = "Good ("..avg.." FPS) — check your PC"
    elseif avg >= 30 then
        perfLbl.TextColor3 = C.yellow
        perfLbl.Text = "Moderate ("..avg.." FPS) — enable boosts"
    else
        perfLbl.TextColor3 = C.red
        perfLbl.Text = "Low ("..avg.." FPS) — enable all boosts"
    end
end)

-- ===== SETTINGS TOGGLE =====
local settingsOpen = false
GearBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    SettingsPage.Visible = settingsOpen
    Scroll.Visible = not settingsOpen
    GearBtn.TextColor3 = settingsOpen and C.accent or C.sub
    TTitle.Text = settingsOpen and "⚙ Settings" or "⚡ FPS Booster"
end)

-- ===== FPS COUNTER =====
RunService.RenderStepped:Connect(function(dt)
    table.insert(fpsBuffer, 1/dt)
    if #fpsBuffer > 60 then table.remove(fpsBuffer, 1) end
    local sum = 0
    for _, v in ipairs(fpsBuffer) do sum = sum + v end
    local avg = math.floor(sum / #fpsBuffer)
    local col = avg >= 50 and C.accent or avg >= 30 and C.yellow or C.red
    FPSLabel.TextColor3 = col
    FPSLabel.Text = avg.." FPS"
end)

-- ===== PILL TOGGLE =====
PillBtn.MouseButton1Click:Connect(function()
    Win.Visible = not Win.Visible
    if Win.Visible then
        PillBtn.TextColor3 = C.accent; pillS.Color = C.accent
    else
        PillBtn.TextColor3 = C.sub; pillS.Color = Color3.fromRGB(50,50,70)
    end
end)

notify("FPS Booster", "Loaded! Click the pill to open.")
print("[FPS Booster] Loaded!")
