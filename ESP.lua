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
        data.Frame.Visible = state
    end
end

function ESP:AddObject(model)
    if not model or self._boxes[model] then return end
    self:Initialize()

    local frame = Instance.new("Frame")
    frame.Name                   = model.Name .. "_ESPBox"
    frame.AnchorPoint            = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(0,0,0,0)
    frame.Position               = UDim2.new(0,0,0,0)
    frame.Parent                 = self.ScreenGui

    local stroke = Instance.new("UIStroke")
    stroke.Parent       = frame
    stroke.Thickness    = 1
    stroke.Transparency = 0

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not model.Parent then
            conn:Disconnect()
            frame:Destroy()
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

            stroke.Rotation = tick() * 30
        else
            frame.Visible = false
        end
    end)

    self._boxes[model] = {
        Frame      = frame,
        Stroke     = stroke,
        Connection = conn,
    }
end

function ESP:RemoveObject(model)
    local data = self._boxes[model]
    if not data then return end
    data.Connection:Disconnect()
    data.Frame:Destroy()
    self._boxes[model] = nil
end

function ESP:Clear()
    for model, _ in pairs(self._boxes) do
        self:RemoveObject(model)
    end
end

return ESP