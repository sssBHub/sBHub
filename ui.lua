-- ui.lua
-- sB Hub UI module
-- Safe modular UI: initializes all state before building pages,
-- never iterates nil tables, and keeps drag logic isolated.

local UI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Hub
local gui
local window
local titleLabel
local sidebar
local content

local tabs = {}
local pages = {}
local connections = {}
local activeTab

local function disconnectAll()
    for _, c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(connections)
end

local function connect(signal, callback)
    if not signal or typeof(callback) ~= "function" then
        return nil
    end

    local ok, c = pcall(function()
        return signal:Connect(callback)
    end)

    if ok and c then
        table.insert(connections, c)
        return c
    end

    return nil
end

local function safeCall(fn, ...)
    if typeof(fn) ~= "function" then
        return false
    end

    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[sB Hub] UI callback error:", err)
    end

    return ok
end

local function make(className, parent, props)
    local object = Instance.new(className)

    if type(props) == "table" then
        for property, value in pairs(props) do
            pcall(function()
                object[property] = value
            end)
        end
    end

    object.Parent = parent
    return object
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = object
    return c
end

local function stroke(object)
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Transparency = 0.5
    s.Parent = object
    return s
end

local function getModule(name)
    if not Hub or type(Hub) ~= "table" then
        return nil
    end

    return Hub[name]
end

local function invokeModule(moduleName, methodName, ...)
    local module = getModule(moduleName)
    if not module then
        return false
    end

    return safeCall(module[methodName], ...)
end

local function makePage(name)
    if pages[name] and pages[name].Parent then
        return pages[name]
    end

    local page = make("ScrollingFrame", content, {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        Visible = false,
    })

    make("UIPadding", page, {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })

    make("UIListLayout", page, {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    pages[name] = page
    return page
end

local function makeSection(parent, text)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local function makeButton(parent, text, callback)
    local button = make("TextButton", parent, {
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 36),
        AutoButtonColor = true,
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
    })

    corner(button, 6)
    stroke(button)

    if callback then
        connect(button.Activated, function()
            safeCall(callback)
        end)
    end

    return button
end

local function makeToggle(parent, text, defaultValue, callback)
    local state = defaultValue == true

    local button = make("TextButton", parent, {
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 38),
        AutoButtonColor = true,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    corner(button, 6)
    stroke(button)

    make("TextLabel", button, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -75, 1, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local stateLabel = make("TextLabel", button, {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -58, 0, 0),
        Size = UDim2.new(0, 48, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    })

    local function update()
        stateLabel.Text = state and "ON" or "OFF"
    end

    connect(button.Activated, function()
        state = not state
        update()
        safeCall(callback, state)
    end)

    update()

    return button, function()
        return state
    end
end

local function showTab(name)
    if type(pages) ~= "table" then
        pages = {}
    end

    if type(tabs) ~= "table" then
        tabs = {}
    end

    if not pages[name] then
        return
    end

    activeTab = name

    for tabName, page in pairs(pages) do
        if page and page.Parent then
            page.Visible = (tabName == name)
        end
    end

    for tabName, button in pairs(tabs) do
        if button and button.Parent then
            button.BackgroundTransparency =
                (tabName == name) and 0 or 0.35
        end
    end

    if titleLabel then
        titleLabel.Text = "sB Hub  •  " .. tostring(name)
    end
end

local function addTab(name)
    if tabs[name] and pages[name] then
        return pages[name]
    end

    local button = make("TextButton", sidebar, {
        Name = name .. "Tab",
        BackgroundTransparency = 0.35,
        Size = UDim2.new(1, -8, 0, 35),
        AutoButtonColor = true,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextSize = 12,
    })

    corner(button, 6)
    tabs[name] = button

    local page = makePage(name)

    connect(button.Activated, function()
        showTab(name)
    end)

    return page
end

local function createBase()
    disconnectAll()

    local old = playerGui:FindFirstChild("sB_Hub_v1")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end

    gui = make("ScreenGui", playerGui, {
        Name = "sB_Hub_v1",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100000,
    })

    window = make("Frame", gui, {
        Name = "Frame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 720, 0, 460),
        BackgroundTransparency = 0.05,
        Active = true,
    })

    corner(window, 10)
    stroke(window)

    titleLabel = make("TextLabel", window, {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 7),
        Size = UDim2.new(1, -60, 0, 34),
        Font = Enum.Font.GothamBold,
        Text = "sB Hub",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local close = make("TextButton", window, {
        Name = "Close",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -42, 0, 7),
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 22,
    })

    connect(close.Activated, function()
        if gui then
            gui.Enabled = false
        end
    end)

    sidebar = make("Frame", window, {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 48),
        Size = UDim2.new(0, 150, 1, -58),
    })

    make("UIListLayout", sidebar, {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    content = make("Frame", window, {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 170, 0, 48),
        Size = UDim2.new(1, -180, 1, -58),
    })

    -- Dragging uses only module-level state, avoiding a huge local-register
    -- footprint and keeping the handlers simple.
    local dragging = false
    local dragStart = nil
    local startPosition = nil

    connect(window.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging or not dragStart or not startPosition then
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

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPosition = nil
        end
    end)
end

local function buildPages()
    -- Always build the complete page map before selecting a tab.
    local mainPage = addTab("Main")
    makeSection(mainPage, "sB Hub")

    makeButton(mainPage, "Refresh Statistics", function()
        invokeModule("Stats", "Refresh")
    end)

    makeButton(mainPage, "Show Hub", function()
        UI.Show()
    end)

    local automationPage = addTab("Automation")
    makeSection(automationPage, "Automation")

    makeButton(automationPage, "Initialize Automation", function()
        invokeModule("Automation", "Start")
        invokeModule("Automation", "Init", Hub)
    end)

    makeToggle(automationPage, "Auto Train", false, function(enabled)
        invokeModule("Automation", "SetAutoTrain", enabled)
    end)

    makeToggle(automationPage, "Auto Rebirth", false, function(enabled)
        invokeModule("Automation", "SetAutoRebirth", enabled)
    end)

    local espPage = addTab("ESP")
    makeSection(espPage, "ESP")

    makeToggle(espPage, "Enable ESP", false, function(enabled)
        if enabled then
            invokeModule("ESP", "Enable")
        else
            invokeModule("ESP", "Disable")
        end
    end)

    makeToggle(espPage, "Boxes", true, function(enabled)
        invokeModule("ESP", "SetBoxes", enabled)
    end)

    makeToggle(espPage, "Names", true, function(enabled)
        invokeModule("ESP", "SetNames", enabled)
    end)

    makeToggle(espPage, "Tracers", false, function(enabled)
        invokeModule("ESP", "SetTracers", enabled)
    end)

    local notificationPage = addTab("Notifications")
    makeSection(notificationPage, "Notifications")

    makeToggle(notificationPage, "Enable Notifications", true, function(enabled)
        if enabled then
            invokeModule("Notifications", "Enable")
        else
            invokeModule("Notifications", "Disable")
        end
    end)

    makeToggle(notificationPage, "Pet Notifications", true, function(enabled)
        invokeModule("Notifications", "SetPetNotifications", enabled)
    end)

    makeToggle(notificationPage, "Aura Notifications", true, function(enabled)
        invokeModule("Notifications", "SetAuraNotifications", enabled)
    end)

    local overlaysPage = addTab("Overlays")
    makeSection(overlaysPage, "Overlays")

    makeToggle(overlaysPage, "Coordinates", false, function(enabled)
        if enabled then
            invokeModule("Overlays", "EnableCoordinates")
        else
            invokeModule("Overlays", "DisableCoordinates")
        end
    end)

    makeToggle(overlaysPage, "Automation Overlay", true, function(enabled)
        invokeModule("Overlays", "SetAutomationOverlay", enabled)
    end)

    makeToggle(overlaysPage, "Performance Overlay", true, function(enabled)
        invokeModule("Overlays", "SetPerformanceOverlay", enabled)
    end)

    local statsPage = addTab("Stats")
    makeSection(statsPage, "Statistics")

    makeButton(statsPage, "Refresh Statistics", function()
        invokeModule("Stats", "Refresh")
    end)

    local spyPage = addTab("Spy")
    makeSection(spyPage, "Player Spy")

    makeButton(spyPage, "Refresh Players", function()
        invokeModule("Spy", "Refresh")
    end)

    makeButton(spyPage, "Refresh Selected Player", function()
        invokeModule("Spy", "RefreshSelected")
    end)

    local settingsPage = addTab("Settings")
    makeSection(settingsPage, "Settings")

    makeButton(settingsPage, "Hide Hub", function()
        UI.Hide()
    end)

    makeButton(settingsPage, "Rebuild UI", function()
        UI.Rebuild()
    end)
end

function UI.Init(hub)
    Hub = hub

    -- Reset these BEFORE any page/tab creation.
    tabs = {}
    pages = {}
    activeTab = nil

    createBase()
    buildPages()
    showTab("Main")

    print("[sB Hub] UI initialized")
end

function UI.Rebuild()
    if not Hub then
        return
    end

    UI.Init(Hub)
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

function UI.GetActiveTab()
    return activeTab
end

return UI
