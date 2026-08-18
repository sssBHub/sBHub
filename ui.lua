local UI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local config = nil

local gui
local window
local content
local tabButtons = {}
local pages = {}

local currentTab
local dragging = false
local dragStart
local startPosition

local function make(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    object.Parent = parent
    return object
end

local function clear(object)
    for _, child in ipairs(object:GetChildren()) do
        child:Destroy()
    end
end

local function showTab(name)
    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end

    for tabName, button in pairs(tabButtons) do
        if tabName == name then
            button.TextTransparency = 0
        else
            button.TextTransparency = 0.35
        end
    end

    currentTab = name
end

local function createPage(name)
    local page = make("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        Visible = false,
    }, content)

    pages[name] = page
    return page
end

local function addLabel(parent, text, height)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, height or 28),
        Text = text,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(230, 230, 230),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function addToggle(parent, text, initial, callback)
    local state = initial == true

    local button = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = state
            and Color3.fromRGB(45, 110, 65)
            or Color3.fromRGB(45, 45, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 34),
        Text = text .. ": " .. (state and "ON" or "OFF"),
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextSize = 13,
        Font = Enum.Font.Gotham,
    }, parent)

    button.MouseButton1Click:Connect(function()
        state = not state

        button.Text = text .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state
            and Color3.fromRGB(45, 110, 65)
            or Color3.fromRGB(45, 45, 50)

        if callback then
            callback(state)
        end
    end)

    return button
end

local function setupDragging()
    local dragHandle = window

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart

        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local function buildHome(page)
    addLabel(page, "sB Hub", 34)
    addLabel(page, "Modular build • GitHub loader", 24)

    addToggle(
        page,
        "Notifications",
        config.state.notifications,
        function(value)
            config.state.notifications = value
        end
    )

    addToggle(
        page,
        "Coordinates Overlay",
        config.state.coords,
        function(value)
            config.state.coords = value
        end
    )

    addToggle(
        page,
        "ESP",
        config.state.esp,
        function(value)
            config.state.esp = value
        end
    )

    addLabel(page, "More systems will be connected as modules are added.", 40)
end

local function buildAutomation(page)
    addLabel(page, "Automation", 34)

    addToggle(page, "Auto Train", config.state.autoTrain, function(value)
        config.state.autoTrain = value
    end)

    addToggle(page, "Auto Rebirth", config.state.autoRebirth, function(value)
        config.state.autoRebirth = value
    end)

    addToggle(page, "Auto Egg", config.state.autoEgg, function(value)
        config.state.autoEgg = value
    end)

    addToggle(page, "Auto Jungle Rock", config.state.autoJungleRock, function(value)
        config.state.autoJungleRock = value
    end)

    addToggle(page, "Anti AFK", config.state.antiAFK, function(value)
        config.state.antiAFK = value
    end)
end

local function buildVisuals(page)
    addLabel(page, "Visuals & Overlays", 34)

    addToggle(page, "ESP", config.state.esp, function(value)
        config.state.esp = value
    end)

    addToggle(page, "ESP Boxes", config.state.espBoxes, function(value)
        config.state.espBoxes = value
    end)

    addToggle(page, "ESP Names", config.state.espNames, function(value)
        config.state.espNames = value
    end)

    addToggle(page, "ESP Distance", config.state.espDistance, function(value)
        config.state.espDistance = value
    end)

    addToggle(page, "ESP Health", config.state.espHealth, function(value)
        config.state.espHealth = value
    end)

    addToggle(page, "Tracers", config.state.espTracers, function(value)
        config.state.espTracers = value
    end)

    addToggle(page, "Coordinates", config.state.coords, function(value)
        config.state.coords = value
    end)

    addToggle(page, "Detailed Compass", config.state.coordsCompass, function(value)
        config.state.coordsCompass = value
    end)

    addToggle(page, "Heading", config.state.coordsHeading, function(value)
        config.state.coordsHeading = value
    end)
end

local function buildStats(page)
    addLabel(page, "Stats & Goals", 34)

    addLabel(page, "Strength, rebirth and session tracking will be connected here.", 42)

    addToggle(page, "Goal Tracking", config.goal.enabled, function(value)
        config.goal.enabled = value
    end)

    addLabel(
        page,
        "Current goal: "
            .. tostring(config.goal.type)
            .. " → "
            .. tostring(config.goal.target),
        34
    )
end

local function buildSpy(page)
    addLabel(page, "Server Spy", 34)
    addLabel(page, "Select a player to inspect available public stats.", 42)

    local list = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, page)

    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 5),
    }, list)

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local button = make("TextButton", {
                BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32),
                Text = target.Name,
                TextColor3 = Color3.fromRGB(235, 235, 235),
                TextSize = 13,
                Font = Enum.Font.Gotham,
            }, list)

            button.MouseButton1Click:Connect(function()
                print("[sB Hub] Spy selected:", target.Name)
            end)
        end
    end
end

local function createWindow()
    gui = make("ScreenGui", {
        Name = "sBHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, player:WaitForChild("PlayerGui"))

    window = make("Frame", {
        Name = "Window",
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 720, 0, 460),
        Position = UDim2.new(0.5, -360, 0.5, -230),
    }, gui)

    make("UICorner", {
        CornerRadius = UDim.new(0, 8),
    }, window)

    local title = make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 10),
        Size = UDim2.new(1, -36, 0, 32),
        Text = "sB Hub",
        TextColor3 = Color3.fromRGB(245, 245, 245),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, window)

    local sidebar = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 52),
        Size = UDim2.new(0, 145, 1, -62),
    }, window)

    make("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)

    content = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 165, 0, 52),
        Size = UDim2.new(1, -175, 1, -62),
    }, window)

    local tabs = {
        "Home",
        "Automation",
        "Visuals",
        "Stats",
        "Spy",
    }

    for index, tabName in ipairs(tabs) do
        local button = make("TextButton", {
            BackgroundTransparency = 1,
            LayoutOrder = index,
            Size = UDim2.new(1, -10, 0, 34),
            Text = tabName,
            TextColor3 = Color3.fromRGB(235, 235, 235),
            TextSize = 13,
            Font = Enum.Font.Gotham,
        }, sidebar)

        tabButtons[tabName] = button

        button.MouseButton1Click:Connect(function()
            showTab(tabName)
        end)

        createPage(tabName)
    end

    buildHome(pages.Home)
    buildAutomation(pages.Automation)
    buildVisuals(pages.Visuals)
    buildStats(pages.Stats)
    buildSpy(pages.Spy)

    showTab("Home")
    setupDragging()
end

function UI.Init(hub)
    config = hub.Config

    if not player then
        return
    end

    local old = player.PlayerGui:FindFirstChild("sBHub")
    if old then
        old:Destroy()
    end

    createWindow()
end

function UI.Destroy()
    if gui then
        gui:Destroy()
        gui = nil
    end
end

function UI.ShowTab(name)
    if pages[name] then
        showTab(name)
    end
end

return UI
