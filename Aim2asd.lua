local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Aim Assist",
        Text = "Criado por SouteX",
		Icon = "rbxassetid://109207488716677",
        Duration = 5
    })
end)

local FOV_RADIUS = 55
local AIM_SMOOTHNESS = 0.10
local AIM_ENABLED = true

local circle = Drawing.new("Circle")
circle.Visible = true
circle.Color = Color3.fromRGB(170, 0, 255)
circle.Thickness = 2
circle.NumSides = 80
circle.Radius = FOV_RADIUS
circle.Filled = false
circle.Transparency = 0.35

local ESP_CACHE = {}

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255,255,255)
    box.Thickness = 1.5
    box.Filled = false
    box.Transparency = 0.5

    ESP_CACHE[player] = box
end

local function removeESP(player)
    if ESP_CACHE[player] then
        ESP_CACHE[player]:Remove()
        ESP_CACHE[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function isVisible(part, character)
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        Camera
    }

    local result = workspace:Raycast(origin, direction, params)

    if result then
        return result.Instance:IsDescendantOf(character)
    end

    return false
end

local function getClosestTarget()
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local closestPart = nil
    local closestDistance = FOV_RADIUS

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character

            if character then
                local humanoid = character:FindFirstChild("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local head = character:FindFirstChild("Head")

                    local priorityParts = {}

                    if hrp then
                        table.insert(priorityParts, hrp)
                    end

                    if head then
                        table.insert(priorityParts, head)
                    end

                    for _, part in ipairs(priorityParts) do
                        local pos, visible = Camera:WorldToViewportPoint(part.Position)

                        if visible and isVisible(part, character) then
                            local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude

                            if distance < closestDistance then
                                closestDistance = distance
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    circle.Position = center

    local target = getClosestTarget()

    if AIM_ENABLED and target then
        local targetPos = target.Position
        local newCF = CFrame.new(Camera.CFrame.Position, targetPos)

        Camera.CFrame = Camera.CFrame:Lerp(newCF, AIM_SMOOTHNESS)
    end

    for player, box in pairs(ESP_CACHE) do
        local character = player.Character

        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and hrp then
                local headPos = hrp.Position + Vector3.new(0, 3, 0)
                local footPos = hrp.Position - Vector3.new(0, 3, 0)

                local headScreen, visible1 = Camera:WorldToViewportPoint(headPos)
                local footScreen, visible2 = Camera:WorldToViewportPoint(footPos)

                if visible1 and visible2 then
                    local height = math.abs(headScreen.Y - footScreen.Y)
                    local width = height / 2

                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(
                        headScreen.X - width / 2,
                        headScreen.Y
                    )

                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
end)
