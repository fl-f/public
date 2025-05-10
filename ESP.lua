local ESP = {
    Enabled     = true,
    MaxDistance = 200,
    ScreenGui   = nil,
    _boxes      = {},
}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Camera     = workspace.CurrentCamera

function ESP:Initialize()
    if self.ScreenGui then return end
    local sg = Instance.new("ScreenGui")
    sg.Name   = "ESP"
    sg.Parent = CoreGui
    self.ScreenGui = sg
end

function ESP:SetEnabled(state)
    self.Enabled = state
    for _, data in pairs(self._boxes) do
        if data and data.Frame then
            data.Frame.Visible = state
            if data.DistanceLabel then
                data.DistanceLabel.Visible = state
            end
        end
    end
end

function ESP:AddObject(model, opts)
    opts = opts or {}
    local showDist = opts.Distance or false

    if self._boxes[model] then
        self._boxes[model].Distance = showDist
        return self._boxes[model]
    end

    self:Initialize()

    local frame = Instance.new("Frame")
    frame.Name                   = model.Name .. "_ESPBox"
    frame.AnchorPoint            = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(0,0,0,0)
    frame.Position               = UDim2.new(0,0,0,0)
    frame.Rotation               = 0
    frame.Parent                 = self.ScreenGui

    local stroke = Instance.new("UIStroke")
    stroke.Parent       = frame
    stroke.Thickness    = 1
    stroke.Transparency = 0

    local distLabel
    if showDist then
        distLabel = Instance.new("TextLabel")
        distLabel.Name                   = model.Name .. "_ESPDistance"
        distLabel.AnchorPoint            = Vector2.new(0.5, 0.5)
        distLabel.BackgroundTransparency = 1
        distLabel.Size                   = UDim2.new(0,100,0,20)
        distLabel.Position               = UDim2.new(0,0,0,0)
        distLabel.TextColor3             = Color3.fromRGB(255,255,255)
        distLabel.Font                   = Enum.Font.Code
        distLabel.TextSize               = 11
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0)
        distLabel.RichText               = true
        distLabel.Text                   = ""
        distLabel.Parent                 = self.ScreenGui
    end

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not model or not model.Parent then
            conn:Disconnect()
            if frame then frame:Destroy() end
            if distLabel then distLabel:Destroy() end
            self._boxes[model] = nil
            return
        end

        local root = model:FindFirstChild("HumanoidRootPart")
                     or model:FindFirstChildWhichIsA("BasePart")
        if not root then return end

        local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
        local dist = (Camera.CFrame.Position - root.Position).Magnitude

        if onScreen and dist <= self.MaxDistance and self.Enabled then
            local scale = (root.Size.Y * Camera.ViewportSize.Y) / (screenPos.Z * 2)
            local w, h = 3 * scale, 4.5 * scale

            frame.Size     = UDim2.new(0, w, 0, h)
            frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            frame.Visible  = true

            if distLabel then
                distLabel.Text     = tostring(math.floor(dist)) .. "m"
                distLabel.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y + h/2 + 11)
                distLabel.Visible  = true
            end
        else
            frame.Visible = false
            if distLabel then distLabel.Visible = false end
        end
    end)

    local data = {
        Frame         = frame,
        Stroke        = stroke,
        Connection    = conn,
        Distance      = showDist,
        DistanceLabel = distLabel,
    }
    self._boxes[model] = data
    return data
end

function ESP:RemoveObject(model)
    local data = self._boxes[model]
    if not data then return end
    
    if data.Connection then 
        data.Connection:Disconnect() 
    end
    
    if data.Frame then 
        data.Frame:Destroy() 
    end
    
    if data.DistanceLabel then
        data.DistanceLabel:Destroy()
    end
    
    self._boxes[model] = nil
end

function ESP:Clear()
    for model, _ in pairs(self._boxes) do
        self:RemoveObject(model)
    end
end

return ESP
