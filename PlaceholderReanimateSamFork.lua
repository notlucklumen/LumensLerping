repeat task.wait(0.05) until game:IsLoaded()
setfpscap(240)

if shared.garbage then
    for _, v in next, shared.garbage do
        pcall(function() v:Disconnect() end)
        pcall(function() v:Destroy() end)
        pcall(function() v = nil end)
    end
end
shared.garbage = {}
local session = shared.garbage
local function addGarbage(obj)
    table.insert(shared.garbage, obj)
    return obj
end

local cloneref = cloneref or function(...)
    return ...
end
local playersService = cloneref(game:GetService('Players'))
local userInputService = cloneref(game:GetService('UserInputService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local starterGui = cloneref(game:GetService('StarterGui'))
local httpService = cloneref(game:GetService('HttpService'))

local lplr = playersService.LocalPlayer
local char = lplr.Character or lplr.CharacterAdded:Wait()
local humanoid = char:FindFirstChild('Humanoid')
local rootPart = humanoid:FindFirstChild('RootPart')

if table.find({'delta', 'cryptic', 'vega x', 'codex'}, ({identifyexecutor()})[1]) or userInputService.TouchEnabled then
    starterGui:SetCore('SendNotification', {
        Title = 'Not supported',
        Text = 'Mobile isn\'t supported for Placeholder Reanimator.'
    })
    return
end

local ver = game:HttpGet('https://raw.githubusercontent.com/kwipflyx/Placeholder/refs/heads/main/placeholderver.txt'):gsub('\n', '')

pcall(function() game:GetService("CoreGui").TopBarApp.TopBarApp.UnibarLeftFrame.HealthBar.HealthBar:Destroy() end)
pcall(function() game:GetService("CoreGui").TopBarApp.TopBarApp.FullScreenFrame.HurtOverlay:Destroy() end)

if not char:FindFirstChild('MoonConvertRealChar') then
    loadstring(game:HttpGet('https://raw.githubusercontent.com/kwipflyx/Placeholder/refs/heads/main/MyWorld.lua'))()
    repeat task.wait() until char:FindFirstChild('MoonConvertRealChar')
end

local lplrGui = lplr.PlayerGui
local gameCamera = workspace.CurrentCamera

local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/kwipflyx/Placeholder/refs/heads/main/library.lua'))()
if not isfile('placeholder_keybind.txt') then
    writefile('placeholder_keybind.txt', 'R')
end
local keybind = readfile('placeholder_keybind.txt')

addGarbage(userInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode[keybind] then
        library.getGui().Enabled = not library.getGui().Enabled
    end
end))

local ind = 0
local offsets = {
    ["Left Hip"] = Vector3.new(-1, -1, 0),
    ["Left Shoulder"] = Vector3.new(-1, 0.5, 0),
    ["Neck"] = Vector3.new(0, 1, 0),
    ["Right Hip"] = Vector3.new(1, -1, 0),
    ["Right Shoulder"] = Vector3.new(1, 0.5, 0),
    ["RootJoint"] = Vector3.new(0, 0, 0)
}
local torso = char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
local timeElapsed = 0

local function parseInput(str)
    local amp, speed = str:match("([%-%.%d]+)%s*,%s*([%-%.%d]+)")
    amp = tonumber(amp) or 0
    speed = tonumber(speed) or 1
    return amp, speed
end

local phases = {}
local smoothed = {}
local lerp = 9
local character = lplr.Character
local jointData = {}

local lastC0 = {}

local dc0map = {
    ["Neck"] = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
    ["Right Shoulder"] = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
    ["Left Shoulder"] = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    ["Right Hip"] = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
    ["Left Hip"] = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    ["RootJoint"] = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
}

local exportOrder = {
    {'Neck', 'head'},
    {'RootJoint', 'torso'},
    {'Left Shoulder', 'leftArm'},
    {'Right Shoulder', 'rightArm'},
    {'Left Hip', 'leftLeg'},
    {'Right Hip', 'rightLeg'},
}

local defaults = {'0 , 2', '0 , 2', '0 , 2', '0', '0', '0', '0 , 2', '0 , 2', '0 , 2', '0', '0', '0'}
local saveFile = 'placeholder_progress.json'
local saved = {}
pcall(function()
    if isfile(saveFile) then
        saved = httpService:JSONDecode(readfile(saveFile))
    end
end)

local function savedText(name, i)
    local s = saved[name]
    if type(s) == 'table' and type(s[i]) == 'string' then
        return s[i]
    end
    return defaults[i]
end

local function saveProgress()
    local data = {}
    for name, info in pairs(jointData) do
        local list = {}
        for i, box in ipairs(info.boxes) do
            list[i] = tostring(box.Value())
        end
        data[name] = list
    end
    pcall(function()
        writefile(saveFile, httpService:JSONEncode(data))
    end)
end

local function fmt(n)
    local s = string.format('%.4f', n)
    s = s:gsub('0+$', ''):gsub('%.$', '')
    if s == '-0' or s == '' then
        s = '0'
    end
    return s
end

local function term(offText, sineText, fn)
    local off = tonumber(offText) or 0
    local amp, speed = parseInput(sineText)
    if amp ~= 0 then
        local s = string.format('%s(%s, %s)', fn, fmt(amp), fmt(speed))
        if off ~= 0 then
            return fmt(off) .. ' + ' .. s
        end
        return s
    end
    return fmt(off)
end

local function buildExportTable(animName)
    local lines = {}
    for _, pair in ipairs(exportOrder) do
        local info = jointData[pair[1]]
        if info then
            local b = info.boxes
            local px = term(b[4].Value(), b[1].Value(), 'cos')
            local py = term(b[5].Value(), b[2].Value(), 'sin')
            local pz = term(b[6].Value(), b[3].Value(), 'cos')
            local rx = term(b[10].Value(), b[7].Value(), 'sin')
            local ry = term(b[11].Value(), b[8].Value(), 'sin')
            local rz = term(b[12].Value(), b[9].Value(), 'cos')
            lines[#lines+1] = string.format(
                "setOffset('%s', CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%s), math.rad(%s), math.rad(%s)))",
                pair[2], px, py, pz, rx, ry, rz
            )
        end
    end
    return table.concat(lines, '\n')
end

for _, obj in next, character:GetDescendants() do
    if obj:IsA('Motor6D') then
        ind = ind + 1
        local col = (ind - 1) % 3
        local row = math.floor((ind - 1) / 3)
        local wind = library.newWindow({Name = obj.Name, TypeoutSpeed = 0.015, Position = UDim2.new(0, 155 + col * 602.5, 0, 82 + row * 169)})
        local xBox = wind.addTextbox({Name = 'x sine', Placeholder = 'amp,speed', Text = savedText(obj.Name, 1)})
        local yBox = wind.addTextbox({Name = 'y sine', Placeholder = 'amp,speed', Text = savedText(obj.Name, 2)})
        local zBox = wind.addTextbox({Name = 'z sine', Placeholder = 'amp,speed', Text = savedText(obj.Name, 3)})
        local xOffBox = wind.addTextbox({Name = 'x offset', Placeholder = 'offset', Text = savedText(obj.Name, 4), Side = 'middleleft'})
        local yOffBox = wind.addTextbox({Name = 'y offset', Placeholder = 'offset', Text = savedText(obj.Name, 5), Side = 'middleleft'})
        local zOffBox = wind.addTextbox({Name = 'z offset', Placeholder = 'offset', Text = savedText(obj.Name, 6), Side = 'middleleft'})
        local xrBox = wind.addTextbox({Name = 'x sine rot', Placeholder = 'amp,speed', Text = savedText(obj.Name, 7), Side = 'middleright'})
        local yrBox = wind.addTextbox({Name = 'y sine rot', Placeholder = 'amp,speed', Text = savedText(obj.Name, 8), Side = 'middleright'})
        local zrBox = wind.addTextbox({Name = 'z sine rot', Placeholder = 'amp,speed', Text = savedText(obj.Name, 9), Side = 'middleright'})
        local xrOffBox = wind.addTextbox({Name = 'x rot off', Placeholder = 'degrees', Text = savedText(obj.Name, 10), Side = 'right'})
        local yrOffBox = wind.addTextbox({Name = 'y rot off', Placeholder = 'degrees', Text = savedText(obj.Name, 11), Side = 'right'})
        local zrOffBox = wind.addTextbox({Name = 'z rot off', Placeholder = 'degrees', Text = savedText(obj.Name, 12), Side = 'right'})
        local baseOffset = offsets[obj.Name] or Vector3.new(0, 0, 0)
        local baseC0 = dc0map[obj.Name] or obj.C0
        phases[obj] = {px=0, py=0, pz=0, prx=0, pry=0, prz=0}
        smoothed[obj] = {dx=0, dy=0, dz=0, rx=0, ry=0, rz=0}
        jointData[obj.Name] = {
            obj = obj,
            boxes = {xBox, yBox, zBox, xOffBox, yOffBox, zOffBox, xrBox, yrBox, zrBox, xrOffBox, yrOffBox, zrOffBox}
        }
        lastC0[obj] = baseC0

        addGarbage(runService.RenderStepped:Connect(function(delta)
            local ph = phases[obj]
            local sm = smoothed[obj]
            local ampX, speedX = parseInput(xBox.Value())
            local ampY, speedY = parseInput(yBox.Value())
            local ampZ, speedZ = parseInput(zBox.Value())
            local ampXR, speedXR = parseInput(xrBox.Value())
            local ampYR, speedYR = parseInput(yrBox.Value())
            local ampZR, speedZR = parseInput(zrBox.Value())
            if ampX ~= 0 then ph.px = ph.px + delta * speedX end
            if ampY ~= 0 then ph.py = ph.py + delta * speedY end
            if ampZ ~= 0 then ph.pz = ph.pz + delta * speedZ end
            if ampXR ~= 0 then ph.prx = ph.prx + delta * speedXR end
            if ampYR ~= 0 then ph.pry = ph.pry + delta * speedYR end
            if ampZR ~= 0 then ph.prz = ph.prz + delta * speedZR end
            local targetDx = ampX ~= 0 and math.cos(ph.px) * ampX or 0
            local targetDy = ampY ~= 0 and math.sin(ph.py) * ampY or 0
            local targetDz = ampZ ~= 0 and math.cos(ph.pz) * ampZ or 0
            local targetRx = ampXR ~= 0 and math.sin(ph.prx) * ampXR or 0
            local targetRy = ampYR ~= 0 and math.sin(ph.pry) * ampYR or 0
            local targetRz = ampZR ~= 0 and math.cos(ph.prz) * ampZR or 0
            local t = 1 - math.exp(-lerp * delta)
            sm.dx = sm.dx + (targetDx - sm.dx) * t
            sm.dy = sm.dy + (targetDy - sm.dy) * t
            sm.dz = sm.dz + (targetDz - sm.dz) * t
            sm.rx = sm.rx + (targetRx - sm.rx) * t
            sm.ry = sm.ry + (targetRy - sm.ry) * t
            sm.rz = sm.rz + (targetRz - sm.rz) * t
            local ox = tonumber(xOffBox.Value()) or 0
            local oy = tonumber(yOffBox.Value()) or 0
            local oz = tonumber(zOffBox.Value()) or 0
            local orx = math.rad(tonumber(xrOffBox.Value()) or 0)
            local ory = math.rad(tonumber(yrOffBox.Value()) or 0)
            local orz = math.rad(tonumber(zrOffBox.Value()) or 0)
            local finalX = baseOffset.X + ox + sm.dx
            local finalY = baseOffset.Y + oy + sm.dy
            local finalZ = baseOffset.Z + oz + sm.dz
            local finalRx = orx + math.rad(sm.rx)
            local finalRy = ory + math.rad(sm.ry)
            local finalRz = orz + math.rad(sm.rz)
            local finalC0 = CFrame.new(finalX, finalY, finalZ) * baseC0.Rotation * CFrame.Angles(finalRx, finalRy, finalRz)
            obj.C0 = finalC0
            lastC0[obj] = finalC0
        end))

        task.wait(0.07)
    end
end

task.spawn(function()
    while task.wait(2) and shared.garbage == session do
        saveProgress()
    end
end)

local Patchma = library.newWindow({
    Name = 'Placeholder '..ver or 'ver IDK',
    TypeoutSpeed = 0.03,
    Position = UDim2.new(0.8, 0, 0.88, 0)
})

Patchma.addButton({
    Name = 'no anim',
    Function = function()
        pcall(function()
            for _,anim in humanoid.Animator:GetPlayingAnimationTracks() do
                anim:Stop()
            end
        end)
        pcall(function() char.Animate:Destroy() end)
        pcall(function()
            while task.wait(0.1) do
                humanoid.Animator:Destroy()
            end
        end)
        library.notify({
            Title = 'no anim',
            Description = 'stopped animations'
        })
    end,
    Side = 'Left'
})

local animNameBox = Patchma.addTextbox({
    Name = 'anim name',
    Placeholder = 'animation1',
    Text = 'animation1',
    Side = 'Left'
})

Patchma.addButton({
    Name = 'export',
    Function = function()
        local result = buildExportTable(animNameBox.Value())
        setclipboard(result)
        library.notify({
            Title = 'export',
            Description = 'copied to clipboard'
        })
    end,
    Side = 'middleleft'
})

Patchma.addButton({
    Name = 'save',
    Function = function()
        saveProgress()
        library.notify({
            Title = 'save',
            Description = 'progress saved'
        })
    end,
    Side = 'middleright'
})

local keybindguithing = Patchma.addTextbox({
    Name = 'gui keybind',
    Placeholder = 'e.g: LeftShift',
    Text = readfile('placeholder_keybind.txt'),
    Side = 'middleleft'
})

keybindguithing.OnChange.Event:Connect(function()
    if #keybindguithing.Value() == 1 then
        keybind = keybindguithing.Value():upper()
        writefile('placeholder_keybind.txt', keybind)
    else
        keybind = keybindguithing.Value()
        writefile('placeholder_keybind.txt', keybind)
    end
end)
