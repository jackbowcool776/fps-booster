-- FPS Booster v2
-- Removes unnecessary visual elements to improve performance
-- Control panel with toggles for each optimization

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local function notify(t, m)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=m, Duration=3})
    end)
end

-- =====================
-- COLORS
-- =====================
local C = {
    bg     = Color3.fromRGB(10, 10, 16),
    panel  = Color3.fromRGB(16, 16, 26),
    row    = Color3.fromRGB(22, 22, 36),
    accent = Color3.fromRGB(80, 255, 160),
    red    = Color3.fromRGB(200, 45, 45),
    yellow = Color3.fromRGB(255, 200, 60),
    text   = Color3.fromRGB(220, 220, 230),
    sub    = Color3.fromRGB(100, 100, 130),
    blue   = Color3.fromRGB(40, 100, 200),
}

-- =====================
-- SAVED ORIGINAL VALUES
-- =====================
local originals = {
    globalShadows  = Lighting.GlobalShadows,
    fogEnd         = Lighting.FogEnd,
    fogStart       = Lighting.FogStart,
    partMaterials  = {},
}

-- Save original part materials so textures can be restored
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        originals.partMaterials[obj] = obj.Material
    end
end

-- =====================
-- BOOST FUNCTIONS
-- =====================

-- 1. Shadows
local shadowsOff = false
local function toggleShadows(on)
    shadowsOff = on
    Lighting.GlobalShadows = not on
    notify("FPS Boost", on and "Shadows OFF" or "Shadows restored")
end

-- 2. Post effects (bloom, blur, color correction etc)
local effectsOff = false
local function toggleEffects(on)
    effectsOff = on
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            pcall(function() effect.Enabled = not on end)
        end
    end
    for _, effect in pairs(workspace:GetDescendants()) do
        if effect:IsA("PostEffect") or effect:IsA("ParticleEmitter") or effect:IsA("Trail") or effect:IsA("Beam") then
            pcall(function() effect.Enabled = not on end)
        end
    end
    notify("FPS Boost", on and "Post Effects OFF" or "Post Effects restored")
end

-- 3. Fog
local fogOff = false
local function toggleFog(on)
    fogOff = on
    if on then
        Lighting.FogEnd   = 100000
        Lighting.FogStart = 99999
    else
        Lighting.FogEnd   = originals.fogEnd
        Lighting.FogStart = originals.fogStart
    end
    notify("FPS Boost", on and "Fog OFF" or "Fog restored")
end

-- 4. Atmosphere
local atmosphereOff = false
local savedAtmosphere = nil
local function toggleAtmosphere(on)
    atmosphereOff = on
    if on then
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") then
                savedAtmosphere = effect
                effect.Parent = nil
            end
        end
        notify("FPS Boost", "Atmosphere OFF")
    else
        if savedAtmosphere then
            savedAtmosphere.Parent = Lighting
        end
        notify("FPS Boost", "Atmosphere restored")
    end
end

-- 5. Textures (set to smooth plastic)
local texturesOff = false
local function toggleTextures(on)
    texturesOff = on
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                if on then
                    obj.Material = Enum.Material.SmoothPlastic
                else
                    local saved = originals.partMaterials[obj]
                    if saved then obj.Material = saved end
                end
            end)
        end
        if obj:IsA("Texture") or obj:IsA("Decal") then
            pcall(function() obj.Transparency = on and 1 or 0 end)
        end
    end
    notify("FPS Boost", on and "Textures OFF" or "Textures restored")
end

-- 6. Other players visibility
local playersHidden = false
local function togglePlayers(on)
    playersHidden = on
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    pcall(function()
                        if part:IsA("BasePart") or part:IsA("Decal") then
                            part.LocalTransparencyModifier = on and 1 or 0
                        end
                    end)
                end
            end
        end
    end
    notify("FPS Boost", on and "Other players hidden" or "Players visible")
end

-- Keep players hidden when new ones join
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

-- 7. Decorations / particles
local decorationsOff = false
local function toggleDecorations(on)
    decorationsOff = on
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            if not obj:IsDescendantOf(LocalPlayer.Character or Instance.new("Model")) then
                pcall(function() obj.Enabled = not on end)
            end
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = not on end)
        end
    end
    notify("FPS Boost", on and "Decorations/Particles OFF" or "Decorations restored")
end

-- 8. Graphics quality
local function setGraphicsLevel(level)
    pcall(function()
        settings().Rendering.QualityLevel = level
    end)
    notify("FPS Boost", "Graphics set to level "..level)
end

-- 9. Sky
local skyOff = false
local savedSky = nil
local function toggleSky(on)
    skyOff = on
    if on then
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                savedSky = obj
                obj.Parent = nil
            end
        end
        notify("FPS Boost", "Sky OFF")
    else
        if savedSky then
            savedSky.Parent = Lighting
        end
        notify("FPS Boost", "Sky restored")
    end
end

-- 10. Max FPS unlock
local function unlockFPS()
    -- setfpscap is exposed by most executors including MacSploit; 0 = unlimited
    if setfpscap then
        setfpscap(0)
    else
        pcall(function()
            settings().Rendering.FrameRateManager = 0
        end)
    end
    notify("FPS Boost", "FPS unlocked!")
end

-- =====================
-- GUI
-- =====================
local gui = Instance.new("ScreenGui")
gui.Name = "FPSBooster"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 50
pcall(function() gui.Parent = game:GetService("CoreGui") end)

-- Toggle pill
local Pill = Instance.new("Frame")
Pill.Size = UDim2.new(0,160,0,36)
Pill.Position = UDim2.new(0,20,0,20)
Pill.BackgroundColor3 = C.bg
Pill.BorderSizePixel = 0
Pill.Active = true  -- required for InputBegan/InputEnded to fire
Pill.ZIndex = 10
Pill.Parent = gui
Instance.new("UICorner",Pill).CornerRadius = UDim.new(0,10)
local pillS = Instance.new("UIStroke")
pillS.Color = Color3.fromRGB(50,50,70) pillS.Parent = Pill

local PillBtn = Instance.new("TextButton")
PillBtn.Size = UDim2.new(1,0,1,0) PillBtn.BackgroundTransparency = 1
PillBtn.TextColor3 = C.sub PillBtn.Font = Enum.Font.GothamBold
PillBtn.TextSize = 12 PillBtn.Text = "⚡ FPS Booster"
PillBtn.ZIndex = 11 PillBtn.Parent = Pill

-- Drag pill
local pd,pds,pfs = false,nil,nil
Pill.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then pd=true pds=i.Position pfs=Pill.Position end
end)
Pill.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then pd=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if pd and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d=i.Position-pds
        Pill.Position=UDim2.new(pfs.X.Scale,pfs.X.Offset+d.X,pfs.Y.Scale,pfs.Y.Offset+d.Y)
    end
end)

-- Main panel
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0,300,0,520)
Win.Position = UDim2.new(0,20,0,62)
Win.BackgroundColor3 = C.bg
Win.BorderSizePixel = 0
Win.Active = true
Win.Visible = false
Win.ZIndex = 10 Win.Parent = gui
Instance.new("UICorner",Win).CornerRadius = UDim.new(0,14)
local winS = Instance.new("UIStroke")
winS.Color = C.accent winS.Thickness = 1.5 winS.Parent = Win

-- Title bar
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1,0,0,38)
TBar.BackgroundColor3 = C.panel
TBar.BorderSizePixel = 0 TBar.ZIndex = 11 TBar.Parent = Win
Instance.new("UICorner",TBar).CornerRadius = UDim.new(0,14)
local TFix = Instance.new("Frame")
TFix.Size = UDim2.new(1,0,0.5,0) TFix.Position = UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3 = C.panel TFix.BorderSizePixel = 0 TFix.ZIndex = 11 TFix.Parent = TBar

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1,-50,1,0) TTitle.Position = UDim2.new(0,12,0,0)
TTitle.BackgroundTransparency = 1 TTitle.TextColor3 = C.accent
TTitle.Font = Enum.Font.GothamBlack TTitle.TextSize = 14
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Text = "⚡ FPS Booster" TTitle.ZIndex = 12 TTitle.Parent = TBar

-- FPS counter in title
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0,60,1,0) FPSLabel.Position = UDim2.new(1,-62,0,0)
FPSLabel.BackgroundTransparency = 1 FPSLabel.TextColor3 = C.accent
FPSLabel.Font = Enum.Font.GothamBold FPSLabel.TextSize = 11
FPSLabel.Text = "-- FPS" FPSLabel.ZIndex = 12 FPSLabel.Parent = TBar

-- Live FPS counter
local fpsBuffer = {}
RunService.RenderStepped:Connect(function(dt)
    table.insert(fpsBuffer, 1/dt)
    if #fpsBuffer > 20 then table.remove(fpsBuffer,1) end
    local avg = 0
    for _, v in ipairs(fpsBuffer) do avg = avg + v end
    avg = math.floor(avg / #fpsBuffer)
    local col = avg >= 50 and C.accent or avg >= 30 and C.yellow or C.red
    FPSLabel.TextColor3 = col
    FPSLabel.Text = avg.." FPS"
end)

-- Scroll content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,-38)
Scroll.Position = UDim2.new(0,0,0,38)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.accent
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ZIndex = 11 Scroll.Parent = Win

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,4)
Layout.Parent = Scroll

-- Single UIPadding instance with all four sides set
local scrollPad = Instance.new("UIPadding", Scroll)
scrollPad.PaddingTop    = UDim.new(0,8)
scrollPad.PaddingLeft   = UDim.new(0,8)
scrollPad.PaddingRight  = UDim.new(0,8)
scrollPad.PaddingBottom = UDim.new(0,8)

-- =====================
-- UI BUILDERS
-- =====================
local function sectionLabel(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,16)
    l.BackgroundTransparency = 1 l.TextColor3 = C.sub
    l.Font = Enum.Font.GothamBold l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "── "..text:upper().." ──"
    l.ZIndex = 12 l.Parent = Scroll
    return l
end

local function makeToggleRow(icon, label, desc, onFn, offFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,52)
    row.BackgroundColor3 = C.row
    row.BorderSizePixel = 0 row.ZIndex = 12 row.Parent = Scroll
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

    local ico = Instance.new("TextLabel")
    ico.Size = UDim2.new(0,30,1,0) ico.Position = UDim2.new(0,4,0,0)
    ico.BackgroundTransparency = 1 ico.TextSize = 18
    ico.Font = Enum.Font.GothamBold ico.Text = icon
    ico.ZIndex = 13 ico.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-90,0,22) lbl.Position = UDim2.new(0,36,0,4)
    lbl.BackgroundTransparency = 1 lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label lbl.ZIndex = 13 lbl.Parent = row

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1,-90,0,16) descLbl.Position = UDim2.new(0,36,0,28)
    descLbl.BackgroundTransparency = 1 descLbl.TextColor3 = C.sub
    descLbl.Font = Enum.Font.Gotham descLbl.TextSize = 9
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextWrapped = true
    descLbl.Text = desc descLbl.ZIndex = 13 descLbl.Parent = row

    local isOn = false
    local togBtn = Instance.new("TextButton")
    togBtn.Size = UDim2.new(0,54,0,26) togBtn.Position = UDim2.new(1,-60,0.5,-13)
    togBtn.BackgroundColor3 = C.row togBtn.TextColor3 = C.sub
    togBtn.Font = Enum.Font.GothamBold togBtn.TextSize = 10
    togBtn.Text = "OFF" togBtn.BorderSizePixel = 0 togBtn.ZIndex = 13 togBtn.Parent = row
    Instance.new("UICorner",togBtn).CornerRadius = UDim.new(0,6)
    local togStroke = Instance.new("UIStroke")
    togStroke.Color = C.sub togStroke.Thickness = 1 togStroke.Parent = togBtn

    togBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            togBtn.Text = "ON"
            togBtn.TextColor3 = C.accent
            togBtn.BackgroundColor3 = Color3.fromRGB(20,50,35)
            togStroke.Color = C.accent
            onFn()
        else
            togBtn.Text = "OFF"
            togBtn.TextColor3 = C.sub
            togBtn.BackgroundColor3 = C.row
            togStroke.Color = C.sub
            offFn()
        end
    end)

    return row, togBtn
end

local function makeBtn(text, color, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,30)
    b.BackgroundColor3 = color or C.blue
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold b.TextSize = 12
    b.Text = text b.BorderSizePixel = 0 b.ZIndex = 12 b.Parent = Scroll
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,7)
    if fn then b.MouseButton1Click:Connect(fn) end
    return b
end

-- =====================
-- BUILD UI
-- =====================
sectionLabel("Visual Boosts")

makeToggleRow("🌑","Shadows","Removes all shadows from the game",
    function() toggleShadows(true) end,
    function() toggleShadows(false) end)

makeToggleRow("✨","Post Effects","Removes bloom, blur, color correction",
    function() toggleEffects(true) end,
    function() toggleEffects(false) end)

makeToggleRow("🌫️","Fog","Removes distance fog",
    function() toggleFog(true) end,
    function() toggleFog(false) end)

makeToggleRow("🌤️","Atmosphere","Removes sky atmosphere effects",
    function() toggleAtmosphere(true) end,
    function() toggleAtmosphere(false) end)

makeToggleRow("🌌","Sky","Removes sky box",
    function() toggleSky(true) end,
    function() toggleSky(false) end)

makeToggleRow("🖼️","Textures","Makes all parts smooth plastic, hides decals",
    function() toggleTextures(true) end,
    function() toggleTextures(false) end)

makeToggleRow("🎆","Particles","Removes fire, smoke, sparkles, trails",
    function() toggleDecorations(true) end,
    function() toggleDecorations(false) end)

makeToggleRow("👥","Other Players","Hides other player characters",
    function() togglePlayers(true) end,
    function() togglePlayers(false) end)

sectionLabel("Graphics Level")

local gfxRow = Instance.new("Frame")
gfxRow.Size = UDim2.new(1,0,0,30)
gfxRow.BackgroundTransparency = 1 gfxRow.ZIndex = 12 gfxRow.Parent = Scroll
local gfxLayout = Instance.new("UIListLayout")
gfxLayout.FillDirection = Enum.FillDirection.Horizontal
gfxLayout.Padding = UDim.new(0,4) gfxLayout.Parent = gfxRow

local levels = {1,2,3,5,10,21}
local labels = {"1","2","3","5","10","Max"}
for i, level in ipairs(levels) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,40,1,0)
    b.BackgroundColor3 = C.row b.TextColor3 = C.text
    b.Font = Enum.Font.GothamBold b.TextSize = 10
    b.Text = labels[i] b.BorderSizePixel = 0 b.ZIndex = 13 b.Parent = gfxRow
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        setGraphicsLevel(level)
        for _, child in pairs(gfxRow:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = C.row child.TextColor3 = C.text
            end
        end
        b.BackgroundColor3 = C.blue b.TextColor3 = Color3.new(1,1,1)
    end)
end

sectionLabel("Quick Actions")

makeBtn("⚡ Unlock FPS Cap", C.accent:Lerp(Color3.new(0,0,0),0.3), unlockFPS)

makeBtn("🔥 Apply ALL Boosts", C.accent:Lerp(Color3.new(0,0,0),0.4), function()
    toggleShadows(true)
    toggleEffects(true)
    toggleFog(true)
    toggleAtmosphere(true)
    toggleSky(true)
    toggleTextures(true)
    toggleDecorations(true)
    togglePlayers(true)
    setGraphicsLevel(1)
    unlockFPS()
    notify("FPS Boost", "All boosts applied!")
end)

makeBtn("↩️ Restore Everything", C.red, function()
    toggleShadows(false)
    toggleEffects(false)
    toggleFog(false)
    toggleAtmosphere(false)
    toggleSky(false)
    toggleTextures(false)
    toggleDecorations(false)
    togglePlayers(false)
    setGraphicsLevel(21)
    notify("FPS Boost", "Everything restored!")
end)

-- =====================
-- PILL TOGGLE
-- =====================
PillBtn.MouseButton1Click:Connect(function()
    Win.Visible = not Win.Visible
    if Win.Visible then
        PillBtn.TextColor3 = C.accent
        pillS.Color = C.accent
    else
        PillBtn.TextColor3 = C.sub
        pillS.Color = Color3.fromRGB(50,50,70)
    end
end)

notify("FPS Booster", "Loaded! Click the pill to open.")
print("[FPS Booster] Loaded!")
