-- ui.lua
-- sB Hub UI
-- Standalone UI module for the modular loader

local UI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Hub
local gui
local main
local sidebar
local content
local title
local tabs = {}
local pages = {}
local activeTab

local connections = {}

local function disconnectAll()
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    object.Parent = parent

    return object
end

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function addStroke(object)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = object
    return stroke
end

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and
           not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function makePage(name)
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        Visible = false
    }, content)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    }, page)

    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    pages[name] = page

    return page
end

local function makeSection(parent, text)
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)

    return label
end

local function makeButton(parent, text, callback)
    local button = create("TextButton", {
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 36),
        AutoButtonColor = true,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13
    }, parent)

    addCorner(button, 6)
    addStroke(button)

    if callback then
        connect(button.Activated, function()
            local success, err = pcall(callback)

            if not success then
                warn("[sB Hub] Button error:", err)
            end
        end)
    end

    return button
end

local function makeToggle(parent, text, default, callback)
    local state = default == true

    local button = create("TextButton", {
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 38),
        AutoButtonColor = true,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)

    addCorner(button, 6)
    addStroke(button)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, button)

    local stateLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -55, 0, 0),
        Size = UDim2.new(0, 45, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 12
    }, button)

    local function update()
        stateLabel.Text = state and "ON" or "OFF"
    end

    connect(button.Activated, function()
        state = not state
        update()

        if callback then
            local success, err = pcall(callback, state)

            if not success then
                warn("[sB Hub] Toggle error:", err)
            end
        end
    end)

    update()

    return button, function()
        return state
    end
end

local function showTab(name)
    if not pages[name] then
        return
    end

    activeTab = name

    for tabName, page in pairs(pages) do
        page.Visible = tabName == name
    end

    for tabName, button in pairs(tabs) do
        if tabName == name then
            button.BackgroundTransparency = 0
        else
            button.BackgroundTransparency = 0.35
        end
    end

    if title then
        title.Text = "sB Hub  •  " .. name
    end
end

local function addTab(name)
    if tabs[name] then
        return tabs[name]
    end

    local button = create("TextButton", {
        Name = name .. "Tab",
        BackgroundTransparency = 0.35,
        Size = UDim2.new(1, -10, 0, 36),
        AutoButtonColor = true,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextSize = 13
    }, sidebar)

    addCorner(button, 6)

    tabs[name] = button

    local page = makePage(name)

    connect(button.Activated, function()
        showTab(name)
    end)

    return button, page
end

local function createBase()
    disconnectAll()

    local old = LocalPlayer.PlayerGui:FindFirstChild("sB_Hub_v1")

    if old then
        old:Destroy()
    end

    gui = create("ScreenGui", {
        Name = "sB_Hub_v1",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, LocalPlayer.PlayerGui)

    main = create("Frame", {
        Name = "Frame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 720, 0, 460),
        BackgroundTransparency = 0.05,
        Active = true
    }, gui)

    addCorner(main, 10)
    addStroke(main)

    title = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 8),
        Size = UDim2.new(1, -60, 0, 36),
        Font = Enum.Font.GothamBold,
        Text = "sB Hub",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    }, main)

    local close = create("TextButton", {
        Name = "Close",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -42, 0, 8),
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 22
    }, main)

    connect(close.Activated, function()
        gui.Enabled = false
    end)

    sidebar = create("Frame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 52),
        Size = UDim2.new(0, 150, 1, -62)
    }, main)

    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sidebar)

    content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 170, 0, 52),
        Size = UDim2.new(1, -180, 1, -62)
    }, main)

    -- Dragging
    local dragging = false
    local dragStart
    local startPosition

    connect(main.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            local releaseConnection
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false

                    if releaseConnection then
                        releaseConnection:Disconnect()
                    end
                end
            end)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local function buildPages()
    -- Main
    local mainPage = addTab("Main")
    mainPage = pages.Main

    makeSection(mainPage, "sB Hub")

    makeButton(mainPage, "Refresh", function()
        if Hub and Hub.Stats and Hub.Stats.Refresh then
            pcall(function()
                Hub.Stats.Refresh()
            end)
        end
    end)

    -- Automation
    addTab("Automation")
    local automationPage = pages.Automation

    makeSection(automationPage, "Automation")

    makeButton(automationPage, "Initialize Automation", function()
        if Hub and Hub.Automation and Hub.Automation.Start then
            pcall(function()
                Hub.Automation.Start()
            end)
        end
    end)

    -- ESP
    addTab("ESP")
    local espPage = pages.ESP

    makeSection(espPage, "ESP")

    makeToggle(espPage, "Enable ESP", false, function(enabled)
        if Hub and Hub.ESP then
            if enabled and Hub.ESP.Enable then
                pcall(Hub.ESP.Enable)
            elseif not enabled and Hub.ESP.Disable then
                pcall(Hub.ESP.Disable)
            end
        end
    end)

    -- Notifications
    addTab("Notifications")
    local notificationsPage = pages.Notifications

    makeSection(notificationsPage, "Notifications")

    makeToggle(
        notificationsPage,
        "Enable Notifications",
        true,
        function(enabled)
            if Hub and Hub.Notifications then
                if enabled and Hub.Notifications.Enable then
                    pcall(Hub.Notifications.Enable)
                elseif not enabled and Hub.Notifications.Disable then
                    pcall(Hub.Notifications.Disable)
                end
            end
        end
    )

    -- Overlays
    addTab("Overlays")
    local overlaysPage = pages.Overlays

    makeSection(overlaysPage, "Overlays")

    makeToggle(overlaysPage, "Coordinates", false, function(enabled)
        if Hub and Hub.Overlays then
            if enabled and Hub.Overlays.EnableCoordinates then
                pcall(Hub.Overlays.EnableCoordinates)
            elseif not enabled and Hub.Overlays.DisableCoordinates then
                pcall(Hub.Overlays.DisableCoordinates)
            end
        end
    end)

    -- Stats
    addTab("Stats")
    local statsPage = pages.Stats

    makeSection(statsPage, "Statistics")

    makeButton(statsPage, "Refresh Statistics", function()
        if Hub and Hub.Stats and Hub.Stats.Refresh then
            pcall(Hub.Stats.Refresh)
        end
    end)

    -- Spy
    addTab("Spy")
    local spyPage = pages.Spy

    makeSection(spyPage, "Player Spy")

    makeButton(spyPage, "Refresh Players", function()
        if Hub and Hub.Spy and Hub.Spy.Refresh then
            pcall(Hub.Spy.Refresh)
        end
    end)
end

function UI.Init(hub)
    Hub = hub

    createBase()

    -- Make absolutely sure these tables exist before any tab loop.
    tabs = {}
    pages = {}

    buildPages()

    showTab("Main")

    print("[sB Hub] UI initialized")
end

function UI.GetGui()
    return gui
end

function UI.Show()
    if gui then
        gui.Enabled = true
    end
end

function UI.Hide()
    if gui then
        gui.Enabled = false
    end
end

function UI.Toggle()
    if gui then
        gui.Enabled = not gui.Enabled
    end
end

return UI
