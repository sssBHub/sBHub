-- overlays.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Overlays = {}

local state = {
    esp = false,
    coords = false,
    coordsCompass = true,
    coordsHeading = true,
    coordsPitch = true,
}

local character
local root
local humanoid

local frameCounter = 0
local lastFpsTime = os.clock()
local fps = 0

local coordsOverlay
local coordsText

local function refreshCharacter()
    character = player.Character

    if character then
        root = character:FindFirstChild("HumanoidRootPart")
        humanoid = character:FindFirstChildOfClass("Humanoid")
    else
        root = nil
        humanoid = nil
    end
end

local function createCoordinateOverlay()
    if coordsOverlay and coordsOverlay.Parent then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SBHubOverlays"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    coordsOverlay = Instance.new("Frame")
    coordsOverlay.Name = "Coordinates"
    coordsOverlay.BackgroundTransparency = 1
    coordsOverlay.Size = UDim2.new(0, 240, 0, 130)
    coordsOverlay.Position = UDim2.new(0, 15, 0, 15)
    coordsOverlay.Visible = false
    coordsOverlay.Parent = gui

    coordsText = Instance.new("TextLabel")
    coordsText.Name = "Text"
    coordsText.BackgroundTransparency = 1
    coordsText.Size = UDim2.new(1, 0, 1, 0)
    coordsText.Font = Enum.Font.Code
    coordsText.TextSize = 16
    coordsText.TextXAlignment = Enum.TextXAlignment.Left
    coordsText.TextYAlignment = Enum.TextYAlignment.Top
    coordsText.Text = ""
    coordsText.Parent = coordsOverlay
end

local function updateCoordinates()
    if not coordsText or not coordsOverlay then
        return
    end

    if not state.coords or not root or not root.Parent then
        coordsOverlay.Visible = false
        return
    end

    local look = root.CFrame.LookVector

    local heading =
        (
            math.deg(
                math.atan2(
                    look.X,
                    -look.Z
                )
            ) + 360
        ) % 360

    local pitch =
        math.deg(
            math.asin(
                math.clamp(
                    look.Y,
                    -1,
                    1
                )
            )
        )

    local directions = {
        "N",
        "NE",
        "E",
        "SE",
        "S",
        "SW",
        "W",
        "NW",
    }

    local index =
        math.floor(
            (heading + 22.5) / 45
        ) % 8 + 1

    local direction = directions[index]

    local lines = {
        string.format(
            "X: %.2f",
            root.Position.X
        ),
        string.format(
            "Y: %.2f",
            root.Position.Y
        ),
        string.format(
            "Z: %.2f",
            root.Position.Z
        ),
    }

    if state.coordsCompass then
        table.insert(
            lines,
            "Facing: " .. direction
        )
    end

    if state.coordsHeading then
        table.insert(
            lines,
            string.format(
                "Heading: %.1f°",
                heading
            )
        )
    end

    if state.coordsPitch then
        table.insert(
            lines,
            string.format(
                "Pitch: %.1f°",
                pitch
            )
        )
    end

    coordsText.Text = table.concat(
        lines,
        "\n"
    )

    coordsOverlay.Visible = true
end

local function updateESP()
    -- ESP rendering can be added here.
    -- Kept intentionally safe so the overlay
    -- module cannot crash the hub.
end

local function update()
    frameCounter += 1

    local now = os.clock()

    if now - lastFpsTime >= 1 then
        fps =
            frameCounter /
            (now - lastFpsTime)

        frameCounter = 0
        lastFpsTime = now
    end

    if state.esp then
        pcall(updateESP)
    end

    if state.coords then
        pcall(updateCoordinates)
    elseif coordsOverlay then
        coordsOverlay.Visible = false
    end
end

function Overlays.SetState(newState)
    if type(newState) ~= "table" then
        return
    end

    for key, value in pairs(newState) do
        if state[key] ~= nil then
            state[key] = value
        end
    end

    updateCoordinates()
end

function Overlays.SetCoordinates(enabled)
    state.coords = enabled == true
    updateCoordinates()
end

function Overlays.SetESP(enabled)
    state.esp = enabled == true
end

function Overlays.GetState()
    local copy = {}

    for key, value in pairs(state) do
        copy[key] = value
    end

    return copy
end

function Overlays.GetFPS()
    return fps
end

function Overlays.Init(Hub)
    createCoordinateOverlay()
    refreshCharacter()

    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        refreshCharacter()
    end)

    RunService.RenderStepped:Connect(function()
        pcall(update)
    end)
end

createCoordinateOverlay()

return Overlays
