local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "H4Solux - Aim",
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
local HEAD_CACHE = {}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

LocalPlayer.CharacterAdded:Connect(function(char)
    raycastParams.FilterDescendantsInstances = {char, Camera}
end)

local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Thickness = 1.5
    box.Filled = false
    box.Transparency = 0.5
    ESP_CACHE[player] = box

    local headCircle = Drawing.new("Circle")
    headCircle.Visible = false
    headCircle.Color = Color3.fromRGB(255, 255, 255)
    headCircle.Thickness = 1.5
    headCircle.Filled = false
    headCircle.Transparency = 0.7
    HEAD_CACHE[player] = headCircle
end

local function removeESP(player)
    if ESP_CACHE[player] then
        ESP_CACHE[player]:Remove()
        ESP_CACHE[player] = nil
    end
    if HEAD_CACHE[player] then
        HEAD_CACHE[player]:Remove()
        HEAD_CACHE[player] = nil
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
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function getClosestTarget(screenCenter)
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

                    if hrp then
                        local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
                        if visible and isVisible(hrp, character) then
                            local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPart = hrp
                            end
                        end
                    end

                    if head then
                        local pos, visible = Camera:WorldToViewportPoint(head.Position)
                        if visible and isVisible(head, character) then
                            local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPart = head
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

    local target = getClosestTarget(center)

    if AIM_ENABLED and target then
        local targetPos = target.Position
        local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, AIM_SMOOTHNESS)
    end

    for player, box in pairs(ESP_CACHE) do
        local character = player.Character
        local headCircle = HEAD_CACHE[player]

        if character and headCircle then
            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and hrp and head then
                local headBoxPos = hrp.Position + Vector3.new(0, 3, 0)
                local footBoxPos = hrp.Position - Vector3.new(0, 3, 0)

                local headScreen, visible1 = Camera:WorldToViewportPoint(headBoxPos)
                local footScreen, visible2 = Camera:WorldToViewportPoint(footBoxPos)
                local actualHeadPos, visible3 = Camera:WorldToViewportPoint(head.Position)

                if visible1 and visible2 then
                    local height = math.abs(headScreen.Y - footScreen.Y)
                    local width = height / 2

                    -- Atualiza Caixa
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(headScreen.X - width / 2, headScreen.Y)
                    box.Visible = true

                    -- Atualiza Círculo baseado na altura relativa da caixa (Escala Perfeita)
                    if visible3 then
                        headCircle.Position = Vector2.new(actualHeadPos.X, actualHeadPos.Y)
                        
                        -- O raio agora é uma fração da altura do corpo (ex: 12% da altura total do boneco)
                        -- Se achar o círculo da cabeça muito grande ou pequeno, mude o 0.12 abaixo
                        headCircle.Radius = height * 0.12 
                        
                        headCircle.Visible = true
                    else
                        headCircle.Visible = false
                    end
                else
                    box.Visible = false
                    headCircle.Visible = false
                end
            else
                box.Visible = false
                headCircle.Visible = false
            end
        elseif box then
            box.Visible = false
            if headCircle then headCircle.Visible = false end
        end
    end
end)
