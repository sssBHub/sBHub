-- notifications.lua
-- Clean modular notification service for sB Hub.
-- No dependency on notification-page UI objects from the old monolithic script.
-- Safe to load even when the main UI has not created any controls yet.

local Notifications = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Hub

local enabled = true
local petNotifications = true
local auraNotifications = true
local rarityNotifications = true

local rarityEnabled = {
    Basic = false,
    Rare = false,
    Epic = true,
    Unique = true,
    Advanced = true,
}

local selectedPets = {}
local selectedAuras = {}

local notificationFeed = {}
local activeToasts = {}

local petReferenceSnapshot = {}
local auraReferenceSnapshot = {}

local pendingCrystalWindow = 0
local crystalStats = {
    total = 0,
    selectedPetHits = 0,
    selectedAuraHits = 0,
    rarityHits = 0,
}

local connections = {}
local overlayGui

local function connect(signal, callback)
    if not signal or typeof(callback) ~= "function" then
        return nil
    end

    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)

    if ok and connection then
        table.insert(connections, connection)
        return connection
    end

    return nil
end

local function disconnectAll()
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
end

local function safeCall(fn, ...)
    if typeof(fn) ~= "function" then
        return false
    end

    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[sB Hub] Notifications callback error:", err)
    end

    return ok
end

local function findGameGui()
    return playerGui:FindFirstChild("gameGui")
end

local function ensureOverlay()
    if overlayGui and overlayGui.Parent then
        return overlayGui
    end

    local old = playerGui:FindFirstChild("sB_NotificationOverlay")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end

    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "sB_NotificationOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 100001
    overlayGui.Parent = playerGui

    return overlayGui
end

local function getColor(name)
    if name == "yellow" then
        return Color3.fromRGB(255, 215, 80)
    elseif name == "red" then
        return Color3.fromRGB(255, 90, 90)
    elseif name == "green" then
        return Color3.fromRGB(90, 220, 130)
    elseif name == "blue" then
        return Color3.fromRGB(90, 170, 255)
    end

    return Color3.fromRGB(90, 170, 255)
end

local function addHistory(text)
    table.insert(notificationFeed, 1, {
        time = os.date("%H:%M:%S"),
        text = tostring(text),
    })

    while #notificationFeed > 50 do
        table.remove(notificationFeed)
    end
end

local function repositionToasts()
    for index, toast in ipairs(activeToasts) do
        if toast and toast.Parent then
            toast.Position = UDim2.new(
                1,
                -290,
                0,
                20 + ((index - 1) * 75)
            )
        end
    end
end

local function notify(titleText, bodyText, colorName)
    if not enabled then
        return
    end

    titleText = tostring(titleText or "Notification")
    bodyText = tostring(bodyText or "")

    local overlay = ensureOverlay()

    local toast = Instance.new("Frame")
    toast.Name = "Notification"
    toast.Size = UDim2.fromOffset(270, 65)
    toast.BackgroundTransparency = 0.08
    toast.BorderSizePixel = 0
    toast.ZIndex = 10000
    toast.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = toast

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(8, 5)
    titleLabel.Size = UDim2.new(1, -16, 0, 20)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = titleText
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = getColor(colorName)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 10001
    titleLabel.Parent = toast

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Position = UDim2.fromOffset(8, 26)
    bodyLabel.Size = UDim2.new(1, -16, 1, -31)
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.Text = bodyText
    bodyLabel.TextSize = 10
    bodyLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    bodyLabel.TextWrapped = true
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    bodyLabel.ZIndex = 10001
    bodyLabel.Parent = toast

    table.insert(activeToasts, toast)
    addHistory(titleText .. " - " .. bodyText)
    repositionToasts()

    task.delay(4, function()
        pcall(function()
            toast:Destroy()
        end)

        for i, item in ipairs(activeToasts) do
            if item == toast then
                table.remove(activeToasts, i)
                break
            end
        end

        repositionToasts()
    end)
end

local function selectedContains(list, name)
    name = tostring(name)

    for _, item in ipairs(list) do
        if tostring(item) == name then
            return true
        end
    end

    return false
end

local function rarityIsEnabled(rarity)
    rarity = tostring(rarity or "")

    for key, value in pairs(rarityEnabled) do
        if string.lower(key) == string.lower(rarity) then
            return value == true
        end
    end

    return false
end

local function getPetCardSnapshot()
    local result = {}
    local gameGui = findGameGui()

    if not gameGui then
        return result
    end

    local items = gameGui:FindFirstChild("itemsMenu")
    local frames = items and items:FindFirstChild("petsFrames")

    if not frames then
        return result
    end

    for _, obj in ipairs(frames:GetDescendants()) do
        if obj:IsA("ObjectValue") and obj.Name == "petReference" then
            local value = obj.Value

            if value then
                result[value:GetFullName()] = value
            end
        end
    end

    return result
end

local function getAuraSnapshot()
    local result = {}
    local gameGui = findGameGui()

    if not gameGui then
        return result
    end

    local items = gameGui:FindFirstChild("itemsMenu")
    local frames = items and items:FindFirstChild("boostsFrames")

    if not frames then
        return result
    end

    for _, obj in ipairs(frames:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local ref =
                obj:FindFirstChild("boostReference", true)
                or obj:FindFirstChild("itemReference", true)
                or obj:FindFirstChild("auraReference", true)

            if ref and ref:IsA("ObjectValue") and ref.Value then
                result[ref.Value:GetFullName()] = ref.Value
            end
        end
    end

    return result
end

local function announcePet(pet)
    if not pet or not petNotifications then
        return
    end

    local name = tostring(pet.Name)
    local rarity =
        pet.Parent and tostring(pet.Parent.Name)
        or "Unknown"

    local selected = selectedContains(selectedPets, name)
    local rare = rarityNotifications and rarityIsEnabled(rarity)

    if not selected and not rare then
        return
    end

    if selected then
        crystalStats.selectedPetHits += 1
    end

    if rare then
        crystalStats.rarityHits += 1
    end

    notify(
        "NEW PET",
        name .. " • " .. rarity,
        rare and "yellow" or "blue"
    )
end

local function announceAura(name, rarity)
    if not auraNotifications then
        return
    end

    name = tostring(name or "")
    rarity = tostring(rarity or "Unknown")

    local selected = selectedContains(selectedAuras, name)
    local rare = rarityNotifications and rarityIsEnabled(rarity)

    if not selected and not rare then
        return
    end

    if selected then
        crystalStats.selectedAuraHits += 1
    end

    if rare then
        crystalStats.rarityHits += 1
    end

    notify(
        "NEW AURA",
        name .. " • " .. rarity,
        rare and "yellow" or "blue"
    )
end

local function refreshNotificationSources()
    local newPets = getPetCardSnapshot()

    if next(petReferenceSnapshot) ~= nil then
        for path, pet in pairs(newPets) do
            if not petReferenceSnapshot[path] and pendingCrystalWindow > 0 then
                announcePet(pet)
            end
        end
    end

    petReferenceSnapshot = newPets

    local newAuras = getAuraSnapshot()

    if next(auraReferenceSnapshot) ~= nil then
        for path, aura in pairs(newAuras) do
            if not auraReferenceSnapshot[path] and pendingCrystalWindow > 0 then
                local rarity =
                    aura.Parent and aura.Parent.Name
                    or "Unknown"

                announceAura(aura.Name, rarity)
            end
        end
    end

    auraReferenceSnapshot = newAuras
end

local function scanPetPool()
    local names = {}

    local pets = player:FindFirstChild("petsFolder")

    if pets then
        for _, rarity in ipairs(pets:GetChildren()) do
            for _, pet in ipairs(rarity:GetChildren()) do
                if pet.Name ~= "" then
                    names[pet.Name] = true
                end
            end
        end
    end

    local result = {}

    for name in pairs(names) do
        table.insert(result, name)
    end

    table.sort(result)
    return result
end

local function scanAuraPool()
    local names = {}

    local powerUps = player:FindFirstChild("powerUpsFolder")

    if powerUps then
        for _, rarity in ipairs(powerUps:GetChildren()) do
            for _, aura in ipairs(rarity:GetChildren()) do
                if aura.Name ~= "" then
                    names[aura.Name] = true
                end
            end
        end
    end

    local gameGui = findGameGui()

    if gameGui then
        local items = gameGui:FindFirstChild("itemsMenu")
        local boosts = items and items:FindFirstChild("boostsFrames")

        if boosts then
            for _, obj in ipairs(boosts:GetDescendants()) do
                local label = obj:FindFirstChild("nameLabel")

                if label and label:IsA("TextLabel") and label.Text ~= "" then
                    names[label.Text] = true
                end
            end
        end
    end

    local result = {}

    for name in pairs(names) do
        table.insert(result, name)
    end

    table.sort(result)
    return result
end

local function startMonitor()
    table.insert(
        connections,
        task.spawn(function()
            while true do
                if not enabled then
                    task.wait(1)
                else
                    if pendingCrystalWindow > 0 then
                        pendingCrystalWindow -= 0.5
                    end

                    refreshNotificationSources()
                    task.wait(0.5)
                end
            end
        end)
    )
end

function Notifications.Init(hub)
    Hub = hub

    disconnectAll()

    enabled = true
    petNotifications = true
    auraNotifications = true
    rarityNotifications = true

    -- Take a baseline first. This prevents the existing inventory from
    -- generating a wall of "new pet" notifications on startup.
    petReferenceSnapshot = getPetCardSnapshot()
    auraReferenceSnapshot = getAuraSnapshot()

    startMonitor()

    print("[sB Hub] Notifications initialized")
end

function Notifications.Enable()
    enabled = true
end

function Notifications.Disable()
    enabled = false
end

function Notifications.SetPetNotifications(value)
    petNotifications = value == true
end

function Notifications.SetAuraNotifications(value)
    auraNotifications = value == true
end

function Notifications.SetRarityNotifications(value)
    rarityNotifications = value == true
end

function Notifications.SetRarity(rarity, value)
    rarityEnabled[tostring(rarity)] = value == true
end

function Notifications.SetSelectedPets(list)
    selectedPets = {}

    if type(list) == "table" then
        for _, name in ipairs(list) do
            table.insert(selectedPets, tostring(name))
        end
    end
end

function Notifications.SetSelectedAuras(list)
    selectedAuras = {}

    if type(list) == "table" then
        for _, name in ipairs(list) do
            table.insert(selectedAuras, tostring(name))
        end
    end
end

function Notifications.Refresh()
    local pets = scanPetPool()
    local auras = scanAuraPool()

    Notifications.SetSelectedPets(pets)
    Notifications.SetSelectedAuras(auras)

    return {
        pets = pets,
        auras = auras,
    }
end

function Notifications.Notify(titleText, bodyText, colorName)
    notify(titleText, bodyText, colorName)
end

function Notifications.OpenCrystalWindow(seconds)
    pendingCrystalWindow = math.max(
        pendingCrystalWindow,
        tonumber(seconds) or 5
    )

    crystalStats.total += 1
end

function Notifications.GetHistory()
    local result = {}

    for i, event in ipairs(notificationFeed) do
        result[i] = {
            time = event.time,
            text = event.text,
        }
    end

    return result
end

function Notifications.GetCrystalStats()
    return {
        total = crystalStats.total,
        selectedPetHits = crystalStats.selectedPetHits,
        selectedAuraHits = crystalStats.selectedAuraHits,
        rarityHits = crystalStats.rarityHits,
    }
end

function Notifications.GetState()
    return {
        enabled = enabled,
        petNotifications = petNotifications,
        auraNotifications = auraNotifications,
        rarityNotifications = rarityNotifications,
        rarityEnabled = table.clone(rarityEnabled),
        selectedPets = table.clone(selectedPets),
        selectedAuras = table.clone(selectedAuras),
    }
end

function Notifications.Rebuild()
    Notifications.Init(Hub)
end

function Notifications.Unload()
    disconnectAll()

    if overlayGui then
        pcall(function()
            overlayGui:Destroy()
        end)
    end

    overlayGui = nil
    table.clear(activeToasts)
end

return Notifications
