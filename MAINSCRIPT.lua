repeat task.wait() until game:IsLoaded()

function rootClean(v)
    if type(v) == 'function' then
        pcall(v)
        return
    end
    if type(v) == 'table' then
        for _, value in pairs(v) do
            rootClean(value)
        end
        table.clear(v)
        return
    end
    pcall(function() task.cancel(v) end)
    pcall(function() v:Stop()       end)
    pcall(function() v:Disconnect() end)
    pcall(function() v:Cancel()     end)
    pcall(function() v:Disable()    end)
    pcall(function() v:Remove()     end)
    pcall(function() v:Destroy()    end)
end

if shared.CleanupTable then
    for _, v in shared.CleanupTable do
        rootClean(v)
    end
end

shared.CleanupTable = {}

function clean(obj, boolFunc)
    table.insert(shared.CleanupTable, obj)
    if boolFunc ~= nil then
        task.spawn(function()
            pcall(function()
                repeat task.wait() until boolFunc() == false
                rootClean(obj)
            end)
        end)
    end
    return obj
end

local comment = function(...) end

local github = 'https://raw.githubusercontent.com/notlucklumen/LumensLerping' --if you ever fork this mess, change this to your repository

clean(task.spawn(function()
    --note: before moon loads, make sure accessories have been loaded or some thing might break
    --to make animations, use.. some of these idk how i would explain it
    --math.sin(os.clock() * 4) * 5
    --you just do math like that and basically use lerp, by the time im making this, ill probably
    --add some helper functions
    local hide_health_gui = true --removes the coregui health bar
    local hide_hurt_gui = true --stops the hurt gui from appearing (should be false if you're trying to debug)
    local loading_text = true --shows cool text to indicate the user the script is loading
    local check_moon = false --when true, will avoid resetting the character. potentinally useful for debugging
    local no_animation = true --makes your player have no animation. useful for motor6D's animations like patchma
    local force_r6 = true --always true, please, unless you're modifying the source.
    local run_moon_in_task = false --if true, will run moon in a task spawn so the script can load instantly, useful for debugging, but some things might bug.

    local function runMoon()
        loadstring(game:HttpGet(github..'/refs/heads/main/MyWorldsReanimate.lua'))()
    end

    local cloneref = cloneref or function(obj)
        return obj
    end
    local run = function(func) func() end

    local textChatService = cloneref(game:GetService('TextChatService'))
    local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
    local playersService = cloneref(game:GetService('Players'))
    local runService = cloneref(game:GetService('RunService'))
    local coreGui = cloneref(game:GetService('CoreGui'))
    local debrisService = cloneref(game:GetService('Debris'))

    local lplr = playersService.LocalPlayer
    local lplrGui = lplr.PlayerGui
    local camera = workspace.CurrentCamera

    local gui = clean(Instance.new('ScreenGui', lplrGui))
    gui.ResetOnSpawn = false

    if not lplr.Character then
        lplr.CharacterAdded:Wait()
    end

    local loadlbl
    if loading_text then
        loadlbl = Instance.new('TextLabel')
        loadlbl.BackgroundTransparency = 1
        loadlbl.Text = '  '..'loading the coolness!!!'
        loadlbl.TextScaled = true
        loadlbl.AnchorPoint = Vector2.new(0, 1)
        loadlbl.Position = UDim2.new(0, 0, 0.98, 0)
        loadlbl.Font = Enum.Font.Code
        loadlbl.TextStrokeTransparency = 0.5
        loadlbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadlbl.Size = UDim2.new(1, 0, 0.03, 0)
        loadlbl.TextXAlignment = Enum.TextXAlignment.Left
        loadlbl.Parent = gui
        clean(debrisService:AddItem(loadlbl, 100))
    end
    if hide_hurt_gui then
        task.spawn(function()
            clean(runService.RenderStepped:Connect(function()
                pcall(function()
                    coreGui.TopBarApp.TopBarApp.FullScreenFrame.HurtOverlay.Visible = false
                end)
            end))
        end)
        clean(function()
            pcall(function()
                coreGui.TopBarApp.TopBarApp.FullScreenFrame.HurtOverlay.Visible = true
            end)
        end)
    end
    if hide_health_gui then
        task.spawn(function()
            clean(runService.RenderStepped:Connect(function()
                pcall(function()
                    coreGui.TopBarApp.TopBarApp.UnibarLeftFrame.HealthBar.Visible = false
                end)
            end))
        end)
        clean(function()
            pcall(function()
                coreGui.TopBarApp.TopBarApp.UnibarLeftFrame.HealthBar.Visible = true
            end)
        end)
    end

    local function runCommand(cmd, redo, untilTrue)
        local server = replicatedStorage:FindFirstChild('01_server')
        if not server then return end
        server:FireServer('cmd', '-'..cmd:gsub('-',''))
        if redo == 0 or not redo then
            redo = math.huge
        end
        local start = os.clock() + redo
        repeat
            if redo and redo ~= math.huge then
                if os.clock() >= start then
                    server:FireServer('cmd', '-'..cmd:gsub('-',''))
                    start = os.clock() + redo
                end
            end
            task.wait()
        until untilTrue == nil or untilTrue()
    end
    
    local oldChar = lplr.Character
    if not oldChar:FindFirstChild('MoonConvertRealChar') or not check_moon then
        runCommand('-rs', 0.5, function()
            return oldChar ~= lplr.Character
        end)
    end
    local char = lplr.Character or lplr.CharacterAdded:Wait()
    local hum = char:WaitForChild('Humanoid')

    if hum.RigType == Enum.HumanoidRigType.R15 and force_r6 then
        runCommand('-r6', 0.5, function()
            return hum.RigType == Enum.HumanoidRigType.R6
        end)
    end

    task.wait(0.08)

    if run_moon_in_task then
        clean(task.spawn(function()
            if not oldChar:FindFirstChild('MoonConvertRealChar') or not check_moon then
                runMoon()
            end
        end))
    else
        if not oldChar:FindFirstChild('MoonConvertRealChar') or not check_moon then
            runMoon()
        end
    end
    repeat task.wait() until char:FindFirstChild('MoonConvertRealChar')

    if loadlbl then
        loadlbl:Destroy()--hides loading lbl
    end
    loadlbl = nil

    local function unloadMoon()
        char.Event:Fire()
    end

    local hum = char:WaitForChild('Humanoid')
    local animator = hum:WaitForChild('Animator')
    local animate = char:FindFirstChild('Animate')

    if no_animation then
        if animate then
            animate:Destroy()
        end
        for _, anim in animator:GetPlayingAnimationTracks() do
            anim:Stop()
        end
    end

    local bodyPartNames = {
        'torso',
        'leftArm',
        'rightArm',
        'leftLeg',
        'rightLeg',
        'head',
        'hrp'--you should ignore hrp i guess
    }

    local body = {--the limbs, probably wont be as useful
        torso = char['Torso'],
        leftArm = char['Left Arm'],
        rightArm = char['Right Arm'],
        leftLeg = char['Left Leg'],
        rightLeg = char['Right Leg'],
        head = char['Head'],
        hrp = char['HumanoidRootPart']
    }

    local joints = {--the characters motor6D's, useful for making animations. use lerping and sin/cos (patchma)
        torso = body.hrp['RootJoint'],
        leftArm = body.torso['Left Shoulder'],
        rightArm = body.torso['Right Shoulder'],
        leftLeg = body.torso['Left Hip'],
        rightLeg = body.torso['Right Hip'],
        head = body.torso['Neck']
    }

    local origins = {--you probably don't need to modify these, but these are joints origins
        torso = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
        leftArm = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        rightArm = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
        leftLeg = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        rightLeg = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
        head = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
    }

    local offsets = {--pretty useful for animations, these are offsets and they auto-update sorta.
        torso = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
        leftArm = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
        rightArm = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
        leftLeg = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
        rightLeg = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
        head = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
    }

    local lerpAnimations = {--basically animations that use something similar to patchma, these are functions so they can be a bit more customizable
        idle = function()
            setOffset('head', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
            setOffset('torso', CFrame.new(0, sin(1, 2), 0) * CFrame.Angles(math.rad(cos(-20, 4)), math.rad(0), math.rad(0)))
            setOffset('leftArm', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
            setOffset('rightArm', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
            setOffset('leftLeg', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
            setOffset('rightLeg', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        end
    }

    local animations = {--these are just offsets basically, u need to manually make the poses, and etc.
        none = {}, --you don't need to change this but dont delete unless you are modifying the code and stuff

        surfing = {
            { time = 0.1167, torso = CFrame.new(0.0047, 0.1273, -0.3721, 0.9056, 0.4191, -0.0649, -0.4241, 0.895, -0.1387, 0, 0.1531, 0.9882), leftArm = CFrame.new(-0.183, -0.1565, 0.0181, 0.5292, 0.7579, -0.3815, -0.5436, 0.6481, 0.5334, 0.6515, -0.0748, 0.7549), rightArm = CFrame.new(-0.3851, -0.1089, -0.114, 0.8658, -0.5005, 0, 0.3619, 0.626, 0.6908, -0.3457, -0.5981, 0.723), leftLeg = CFrame.new(-0.3925, 0.2291, 0.0197, 0.919, 0.3825, 0.0954, -0.3923, 0.9111, 0.1263, -0.0386, -0.1535, 0.9874), rightLeg = CFrame.new(0.0077, -0.0298, 0.0086, 0.8556, 0.4074, -0.3193, -0.365, 0.9122, 0.186, 0.3671, -0.0426, 0.9292), head = CFrame.new(0, 0, 0, 0.9667, -0.2545, 0.0265, 0.2556, 0.9654, -0.0516, -0.0125, 0.0567, 0.9983) },
            { time = 0.1667, torso = CFrame.new(-0.0173, 0.2084, -0.4174, 0.5898, 0.7879, -0.1769, -0.8041, 0.553, -0.2182, -0.0741, 0.2709, 0.9597), leftArm = CFrame.new(-0.3184, -0.096, 0.0222, 0.3839, 0.92, -0.0787, -0.6515, 0.3303, 0.6829, 0.6543, -0.2108, 0.7262), rightArm = CFrame.new(-0.7616, -0.12, -0.1827, 0.6068, -0.7506, -0.2615, 0.5029, 0.1078, 0.8576, -0.6155, -0.6519, 0.4428), leftLeg = CFrame.new(-0.3196, 0.4085, -0.0666, 0.9403, 0.266, 0.2122, -0.3338, 0.8422, 0.4234, -0.0661, -0.469, 0.8807), rightLeg = CFrame.new(0.1987, 0.1015, 0.2091, 0.9429, 0.0751, -0.3245, -0.0651, 0.997, 0.0415, 0.3266, -0.018, 0.945), head = CFrame.new(0, 0, 0, 0.679, -0.7332, 0.0373, 0.7282, 0.6791, 0.093, -0.0935, -0.036, 0.995) },
            { time = 0.2, torso = CFrame.new(-0.0157, 0.3489, -0.8705, 0.3671, 0.8941, -0.2566, -0.9194, 0.3068, -0.2461, -0.1413, 0.3263, 0.9346), leftArm = CFrame.new(-0.4194, -0.0955, 0.0819, 0.3839, 0.8608, 0.3343, -0.6515, -0.004, 0.7586, 0.6543, -0.509, 0.5593), rightArm = CFrame.new(-0.624, -0.6295, -0.2484, 0.6783, -0.5865, -0.4427, 0.5124, -0.0543, 0.857, -0.5267, -0.8081, 0.2637), leftLeg = CFrame.new(-0.3691, 0.935, -0.1152, 0.9403, 0.2362, 0.2449, -0.3338, 0.7801, 0.5292, -0.0661, -0.5793, 0.8124), rightLeg = CFrame.new(0.1149, 0.5374, 0.2626, 0.9215, -0.2728, -0.2764, 0.2328, 0.9577, -0.1693, 0.3109, 0.0916, 0.946), head = CFrame.new(0, 0, 0, 0.5676, -0.8233, -0.0064, 0.8175, 0.5626, 0.123, -0.0977, -0.075, 0.9924) },
            { time = 0.2167, leftArm = CFrame.new(-0.4194, -0.0955, 0.0819, 0.0527, 0.9766, 0.2086, -0.6265, -0.1303, 0.7684, 0.7776, -0.1712, 0.605), rightArm = CFrame.new(-0.624, -0.6295, -0.2484, 0.7607, -0.4747, -0.4427, 0.5147, 0.0255, 0.857, -0.3955, -0.8798, 0.2637), leftLeg = CFrame.new(-0.3212, 0.351, 0.154, 0.9546, 0.1972, 0.2233, -0.2806, 0.8469, 0.4518, -0.1, -0.4939, 0.8637), rightLeg = CFrame.new(0.1987, 0.1015, 0.2091, 0.8875, -0.3687, -0.2764, 0.3326, 0.9277, -0.1693, 0.3189, 0.0583, 0.946), head = CFrame.new(0, 0, 0, 0.6349, -0.7725, -0.0064, 0.7672, 0.6295, 0.123, -0.091, -0.083, 0.9924) },
            { time = 0.2333, leftArm = CFrame.new(-0.3017, -0.1505, 0.1034, 0.1238, 0.9491, 0.2895, -0.5868, -0.1653, 0.7927, 0.8002, -0.268, 0.5365), rightArm = CFrame.new(-0.3015, -0.5531, 0.0449, 0.5446, -0.7123, -0.4427, 0.4906, -0.1575, 0.857, -0.6802, -0.6839, 0.2637), leftLeg = CFrame.new(-0.3212, 0.351, 0.154, 0.9432, 0.2543, 0.2139, -0.3241, 0.8459, 0.4235, -0.0733, -0.4688, 0.8803), rightLeg = CFrame.new(0.1987, 0.1015, 0.2091, 0.8875, -0.3526, -0.2966, 0.3326, 0.9357, -0.1172, 0.3189, 0.0054, 0.9478), head = CFrame.new(0, 0, 0, 0.6479, -0.7617, -0.0064, 0.7565, 0.6424, 0.123, -0.0896, -0.0845, 0.9924) },
            { time = 0.25, torso = CFrame.new(0.1632, -0.1492, -0.462, 0.7346, 0.6738, -0.0798, -0.6392, 0.6477, -0.4146, -0.2276, 0.3556, 0.9065), leftArm = CFrame.new(-0.4799, -0.1089, -0.0609, -0.044, 0.9597, 0.2774, -0.5942, -0.2484, 0.765, 0.8031, -0.1312, 0.5812), rightArm = CFrame.new(0.0209, -0.4768, 0.3381, 0.2586, -0.8586, -0.4427, 0.4036, -0.3203, 0.857, -0.8776, -0.4003, 0.2637), leftLeg = CFrame.new(-0.3212, 0.351, 0.154, 0.9288, 0.3104, 0.2027, -0.3676, 0.8417, 0.3955, -0.0478, -0.4418, 0.8958), rightLeg = CFrame.new(0.1987, 0.1015, 0.2091, 0.917, 0.2437, -0.3158, -0.2771, 0.9587, -0.0648, 0.287, 0.1469, 0.9466), head = CFrame.new(0, 0, 0, 0.6606, -0.7507, -0.0064, 0.7455, 0.655, 0.123, -0.0882, -0.086, 0.9924) },
            { time = 0.2667, torso = CFrame.new(-0.0888, -0.2645, -0.5036, 0.7906, -0.5765, 0.2063, 0.5992, 0.6593, -0.4542, 0.1258, 0.4827, 0.8667), leftArm = CFrame.new(-1.0148, 0.0157, -0.5538, -0.5207, 0.832, 0.1916, -0.5292, -0.4907, 0.6922, 0.6699, 0.259, 0.6958), rightArm = CFrame.new(-0.6935, -0.9145, -0.0736, 0.2586, -0.7653, -0.5895, 0.4036, -0.4689, 0.7857, -0.8776, -0.4411, 0.1876), leftLeg = CFrame.new(-0.434, 0.4583, -0.021, 0.7887, 0.4919, -0.3688, -0.4895, 0.8654, 0.1075, 0.3721, 0.0958, 0.9233), rightLeg = CFrame.new(0.5032, 0.362, 0.4577, 0.7728, 0.3448, -0.5328, -0.4962, 0.8517, -0.1686, 0.3957, 0.3946, 0.8293), head = CFrame.new(0, 0, 0, 0.8686, 0.4955, 0.0037, -0.4911, 0.8597, 0.1406, 0.0665, -0.124, 0.9901) },
            { time = 0.2833, torso = CFrame.new(-0.0888, -0.2645, -0.5036, 0.5232, -0.7973, 0.301, 0.8309, 0.3989, -0.3878, 0.1891, 0.453, 0.8712), leftArm = CFrame.new(-0.1505, -0.5265, -0.2128, -0.3894, 0.9182, -0.0726, -0.7326, -0.261, 0.6286, 0.5582, 0.298, 0.7743), rightArm = CFrame.new(0.0858, -0.1324, 0.5115, 0.571, -0.4338, -0.697, 0.5426, -0.4378, 0.7169, -0.6161, -0.7875, -0.0146), leftLeg = CFrame.new(-0.2364, 0.2149, -0.0058, 0.919, 0.314, 0.2383, -0.35, 0.9281, 0.1269, -0.1813, -0.2001, 0.9629), rightLeg = CFrame.new(0.1032, 1.0623, 0.0907, 0.7374, -0.2517, -0.6268, 0.3247, 0.9458, 0.0022, 0.5923, -0.2051, 0.7792), head = CFrame.new(0, 0, 0, 0.7062, 0.708, 0.0037, -0.7013, 0.6988, 0.1406, 0.0969, -0.1019, 0.9901) },
            { time = 0.3, torso = CFrame.new(-0.0888, -0.2645, -0.5036, 0.3617, -0.8689, 0.3379, 0.907, 0.2441, -0.3433, 0.2158, 0.4306, 0.8764), leftArm = CFrame.new(0.2816, -0.7976, -0.0423, -0.2993, 0.9336, -0.1969, -0.8126, -0.1413, 0.5654, 0.5001, 0.3293, 0.8009), rightArm = CFrame.new(0.4754, 0.2586, 0.8041, 0.6684, -0.2195, -0.7106, 0.6049, -0.3954, 0.6912, -0.4327, -0.8919, -0.1315), leftLeg = CFrame.new(-0.1376, 0.0931, 0.0018, 0.8402, 0.162, 0.5175, -0.2866, 0.9428, 0.1702, -0.4603, -0.2913, 0.8386), rightLeg = CFrame.new(0.1567, 0.4595, 0.1138, 0.5351, -0.4755, -0.6982, 0.6921, 0.7207, 0.0395, 0.4844, -0.5044, 0.7148), head = CFrame.new(0, 0, 0, 0.6052, 0.7961, 0.0037, -0.7885, 0.5988, 0.1406, 0.1097, -0.088, 0.9901) },
            { time = 0.3167, torso = CFrame.new(-0.0618, -0.2644, -0.5332, 0.2926, -0.8829, 0.3672, 0.924, 0.1621, -0.3464, 0.2463, 0.4407, 0.8632), leftArm = CFrame.new(0.3402, -0.8135, -0.0332, -0.2456, 0.9655, -0.0861, -0.8265, -0.1621, 0.5391, 0.5066, 0.2036, 0.8378), rightArm = CFrame.new(0.4315, 0.171, 0.5988, 0.6759, -0.1774, -0.7153, 0.6239, -0.3787, 0.6836, -0.3922, -0.9083, -0.1453), leftLeg = CFrame.new(-0.1376, 0.0931, 0.0018, 0.8255, 0.2389, 0.5114, -0.3397, 0.9338, 0.1122, -0.4507, -0.2663, 0.852), rightLeg = CFrame.new(0.1268, 0.4916, 0.046, 0.5299, -0.3994, -0.7481, 0.7037, 0.6994, 0.1251, 0.4733, -0.5927, 0.6517), head = CFrame.new(0, 0, 0, 0.6052, 0.7961, 0.0037, -0.7885, 0.5988, 0.1406, 0.1097, -0.088, 0.9901) },
            { time = 0.35, torso = CFrame.new(-0.0078, -0.2641, -0.5925, 0.1519, -0.8919, 0.4259, 0.9388, -0.0046, -0.3444, 0.3092, 0.4522, 0.8366), leftArm = CFrame.new(0.4573, -0.8455, -0.0151, -0.1385, 0.9799, 0.1436, -0.8563, -0.1913, 0.4798, 0.4976, -0.0565, 0.8656), rightArm = CFrame.new(0.4207, 0.1601, 0.5821, 0.6851, -0.0922, -0.7226, 0.6596, -0.3425, 0.6691, -0.3092, -0.935, -0.1738), leftLeg = CFrame.new(-0.1376, 0.0931, 0.0018, 0.7836, 0.3878, 0.4853, -0.4423, 0.8968, -0.0025, -0.4362, -0.2127, 0.8743), rightLeg = CFrame.new(0.0669, 0.5557, -0.0897, 0.524, -0.2322, -0.8194, 0.7247, 0.6271, 0.2858, 0.4475, -0.7436, 0.4968), head = CFrame.new(0, 0, 0, 0.6052, 0.7961, 0.0037, -0.7885, 0.5988, 0.1406, 0.1097, -0.088, 0.9901) },
            { time = 0.45, torso = CFrame.new(-0.0621, -0.1757, -0.6316, 0.106, -0.8985, 0.4259, 0.9373, -0.0527, -0.3444, 0.3319, 0.4358, 0.8366), leftArm = CFrame.new(0.4573, -0.8455, -0.0151, 0.0944, 0.9954, 0.0149, -0.7781, 0.0644, 0.6249, 0.621, -0.0706, 0.7806), rightArm = CFrame.new(0.4207, 0.1601, 0.5821, 0.6148, -0.1035, -0.7819, 0.7196, -0.3323, 0.6098, -0.3229, -0.9375, -0.1298), leftLeg = CFrame.new(-0.1376, 0.0931, 0.0018, 0.769, 0.4566, 0.4474, -0.4716, 0.8777, -0.0853, -0.4317, -0.1454, 0.8902), rightLeg = CFrame.new(0.0669, 0.5557, -0.0897, 0.524, -0.1749, -0.8335, 0.7247, 0.6058, 0.3285, 0.4475, -0.7762, 0.4442), head = CFrame.new(0, 0, 0, 0.6052, 0.7961, 0.0037, -0.7885, 0.5988, 0.1406, 0.1097, -0.088, 0.9901) },
            { time = 0.5167, torso = CFrame.new(-0.1167, -0.1789, -0.6051, 0.1283, -0.9127, 0.3881, 0.9533, 0.0055, -0.3021, 0.2735, 0.4087, 0.8707), leftArm = CFrame.new(0.4573, -0.8455, -0.0151, 0.0944, 0.9918, -0.0857, -0.7781, 0.1272, 0.6152, 0.621, 0.0086, 0.7837), rightArm = CFrame.new(0.4208, 0.1601, 0.5821, 0.5408, -0.0515, -0.8395, 0.7793, -0.3448, 0.5232, -0.3164, -0.9373, -0.1463), leftLeg = CFrame.new(-0.1376, 0.0931, 0.0018, 0.769, 0.4083, 0.4919, -0.4716, 0.8818, 0.0052, -0.4317, -0.236, 0.8706), rightLeg = CFrame.new(0.0825, 0.5052, -0.0382, 0.5397, -0.2115, -0.8149, 0.6765, 0.685, 0.2703, 0.501, -0.6972, 0.5128), head = CFrame.new(0, 0, 0, 0.6052, 0.7961, 0.0037, -0.7885, 0.5988, 0.1406, 0.1097, -0.088, 0.9901) },
        }
    }

    
    local currentAnimation = 'surfing' --change this to the playing animation! (btw, if this is set to "lerp:your-animation", the script will instead allow you to use your lerp animations)
    local animAlpha = 0.3 --this is the lerp alpha, its basically how smooth animations will play, 0 to 1!
    local animModular = 0.2 --change this for faster frame switching!@!#

    local function jointCFrame(name)
        local o = origins[name]
        local off = offsets[name]
        return CFrame.new(o.Position + off.Position) * off.Rotation * o.Rotation
    end

    local function setOffset(joint, cf)
        if typeof(cf) == 'CFrame' then
            offsets[joint] = offsets[joint]:Lerp(cf, animAlpha)
        elseif type(cf) == 'table' then
            offsets[joint] = offsets[joint]:Lerp(CFrame.new(cf[1]) * CFrame.Angles(math.rad(cf[2][1]), math.rad(cf[2][2]), math.rad(cf[2][3])), animAlpha)
        end
    end

    --helpers
    local sin = function(radius, speed)
        return math.sin(os.clock()*speed)*radius
    end
    local cos = function(radius, speed)
        return math.cos(os.clock()*speed)*radius
    end

    --[[
        lerp animation example:

        setOffset('head', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        setOffset('torso', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        setOffset('leftArm', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        setOffset('rightArm', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        setOffset('leftLeg', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))
        setOffset('rightLeg', CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)))



        if INSTEAD you want to create lerp animations the easy way, you can do so using this script, it's just placeholder reanimate but kind of tweaked by me, its at the bottom of this script!
    ]]

    local modular = 0
    local animFrame = 0
    local oldAnim = currentAnimation

    --auto upddating and more stuff?
    clean(runService.Heartbeat:Connect(function()
        local pose
        local isLerp = currentAnimation:sub(1, 5) == 'lerp:'

        if oldAnim ~= currentAnimation then -- resets modular when a new animation comes
            modular = 0
            oldAnim = currentAnimation
        end
    
        for name in offsets do
            offsets[name] = CFrame.new()
        end
    
        if isLerp then
            local lerpAnim = lerpAnimations[currentAnimation:sub(6)]
            if lerpAnim then
                lerpAnim()
            end
        else
            local frames = animations[currentAnimation]
            if frames and #frames > 0 then
                modular += animModular
                animFrame = math.floor(modular) % #frames + 1
                pose = frames[animFrame]
            else
                modular = 0
            end
        end
    
        for _, name in bodyPartNames do
            local joint = joints[name]
            if joint then
                local extra = pose and pose[name] or CFrame.new()
                joint.C0 = joint.C0:Lerp(jointCFrame(name) * extra, animAlpha)
            end
        end
    end))

    --animate stuff
end))



-- ADDITIONAL HELP (sorry if you didn't see this)

--[[
    For making animations more easier, use this script below:

    https://raw.githubusercontent.com/notlucklumen/LumensLerping/refs/heads/main/KeyframePlugin.lua
    

    If you are on PC, paste the script in a script instance
    then do Save/Export -> Save as Local plugin on the script instance. The plugin name is "KeyframesToPoses" with a keyframe icon

    After that, import a roblox dummy in the toolbox (you dont need to do this, but if you are making your own animations you should)
    when you have your dummy, use the clip editor to animate your animation
    once your animation is done, save a name for it, then exit the clip editor
    go into your dummy and find "AnimSaves" with a # icon
    here, you will find a animation which is yours (should be the name you set it as, or if you didn't, it will be a default name)
    open the plugin, and select that instance, then press "Convert selected"
    there should be code that has generated in the ui, copy and paste that code in your animation table

    EXAMPLE:
        local animations = {
            ['My Cool Animation'] = { ... }
        }
    this is basically what you should do ^^^
    if you are instead getting animations off a http, you should do return { ... }
    and to do so you would do:
        local myAnimTable = loadstring(game:HttpGet('myanimationurl'))() --should return a table


    i forgot most of what i said here, but if you want to do like animation lerps and stuff more easier use the code below in ur executor
    (the ui will be super large or super small on most devices, sorry about that)

    loadstring(game:HttpGet('https://raw.githubusercontent.com/notlucklumen/LumensLerping/refs/heads/main/PlaceholderReanimateSamFork.lua'))()
]]
