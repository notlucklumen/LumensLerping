local Selection = game:GetService("Selection")

local jointMap = {
	["Torso"] = "torso",
	["Left Arm"] = "leftArm",
	["Right Arm"] = "rightArm",
	["Left Leg"] = "leftLeg",
	["Right Leg"] = "rightLeg",
	["Head"] = "head",
}

local jointOrder = { "torso", "leftArm", "rightArm", "leftLeg", "rightLeg", "head" }

local colors = {
	bg = Color3.fromRGB(37, 37, 41),
	panel = Color3.fromRGB(28, 28, 31),
	button = Color3.fromRGB(58, 58, 66),
	selected = Color3.fromRGB(0, 120, 215),
	text = Color3.fromRGB(235, 235, 235),
	dim = Color3.fromRGB(150, 150, 158),
}

local function num(n)
	local s = string.format("%.4f", n)
	s = s:gsub("0+$", ""):gsub("%.$", "")
	if s == "-0" or s == "" then
		s = "0"
	end
	return s
end

local function cfStr(cf)
	if cf == CFrame.new() then
		return "CFrame.new()"
	end
	local parts = {}
	for i, v in { cf:GetComponents() } do
		parts[i] = num(v)
	end
	return "CFrame.new(" .. table.concat(parts, ", ") .. ")"
end

local function convertSequence(ks)
	local keyframes = ks:GetKeyframes()
	table.sort(keyframes, function(a, b)
		return a.Time < b.Time
	end)

	local lines = { "{" }
	for _, kf in keyframes do
		local found = {}
		for _, p in kf:GetDescendants() do
			if p:IsA("Pose") and p.Weight > 0 and jointMap[p.Name] then
				found[jointMap[p.Name]] = p.CFrame
			end
		end
		local fields = { "time = " .. num(kf.Time) }
		for _, joint in jointOrder do
			if found[joint] then
				table.insert(fields, joint .. " = " .. cfStr(found[joint]))
			end
		end
		table.insert(lines, "\t{ " .. table.concat(fields, ", ") .. " },")
	end
	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local widget = plugin:CreateDockWidgetPluginGui(
	"KeyframesToPoseTable",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 440, 600, 340, 400)
)
widget.Title = "Keyframes To Pose Table"

local root = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = colors.bg,
	BorderSizePixel = 0,
}, widget)

make("TextLabel", {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 0, 20),
	BackgroundTransparency = 1,
	Text = "Select the keyframe sequence to convert",
	TextColor3 = colors.text,
	Font = Enum.Font.SourceSansBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
}, root)

local function makeButton(text, x, w, y, h)
	return make("TextButton", {
		Position = UDim2.new(0, x, 0, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = colors.button,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = colors.text,
		Font = Enum.Font.SourceSans,
		TextSize = 15,
		AutoButtonColor = true,
	}, root)
end

local refreshButton = makeButton("Refresh", 8, 80, 32, 26)
local clearButton = makeButton("Clear", 94, 70, 32, 26)

local list = make("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 64),
	Size = UDim2.new(1, -16, 0.38, 0),
	BackgroundColor3 = colors.panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, root)

make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 2),
}, list)

local convertButton = make("TextButton", {
	Position = UDim2.new(0, 8, 0.38, 72),
	Size = UDim2.new(1, -16, 0, 30),
	BackgroundColor3 = colors.selected,
	BorderSizePixel = 0,
	Text = "Convert Selected",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.SourceSansBold,
	TextSize = 16,
}, root)

local output = make("TextBox", {
	Position = UDim2.new(0, 8, 0.38, 110),
	Size = UDim2.new(1, -16, 0.62, -118),
	BackgroundColor3 = colors.panel,
	BorderSizePixel = 0,
	Text = "",
	PlaceholderText = "Output appears here. Click, Ctrl+A, Ctrl+C.",
	PlaceholderColor3 = colors.dim,
	TextColor3 = colors.text,
	Font = Enum.Font.Code,
	TextSize = 14,
	MultiLine = true,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
}, root)

local current = nil
local rows = {}

local function paintAll()
	for ks, row in rows do
		row.BackgroundColor3 = (current == ks) and colors.selected or colors.button
	end
end

local function refresh()
	for _, row in rows do
		row:Destroy()
	end
	table.clear(rows)

	local found = {}
	for _, inst in game:GetDescendants() do
		if inst:IsA("KeyframeSequence") then
			table.insert(found, inst)
		end
	end
	table.sort(found, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	if current and not current:IsDescendantOf(game) then
		current = nil
	end

	for i, ks in found do
		local row = make("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(1, -8, 0, 24),
			BackgroundColor3 = colors.button,
			BorderSizePixel = 0,
			Text = "  " .. ks.Name .. "   (" .. ks:GetFullName() .. ")",
			TextColor3 = colors.text,
			Font = Enum.Font.SourceSans,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
		}, list)
		rows[ks] = row
		row.MouseButton1Click:Connect(function()
			current = ks
			paintAll()
		end)
	end

	paintAll()

	if #found == 0 then
		output.Text = "No KeyframeSequences found in this place."
	end
end

refreshButton.MouseButton1Click:Connect(refresh)

clearButton.MouseButton1Click:Connect(function()
	current = nil
	paintAll()
end)

convertButton.MouseButton1Click:Connect(function()
	if not current or not current:IsDescendantOf(game) then
		output.Text = "Select a keyframe sequence first."
		return
	end

	output.Text = convertSequence(current)
end)

local toolbar = plugin:CreateToolbar("Animation Tools")
local toggle = toolbar:CreateButton("KeyframesToPoses", "Convert KeyframeSequences to pose tables", "")
toggle.ClickableWhenViewportHidden = true

toggle.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggle:SetActive(widget.Enabled)
	if widget.Enabled then
		refresh()
	end
end)

Selection.SelectionChanged:Connect(function()
	if not widget.Enabled then
		return
	end
	for _, inst in Selection:Get() do
		if rows[inst] then
			current = inst
			paintAll()
			break
		end
	end
end)
