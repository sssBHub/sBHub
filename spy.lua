-- spy.lua
-- Clean, crash-safe spy module

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Spy = {}

local running = false
local connections = {}

local state = {
    enabled = false,
}

local function disconnectAll()
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
end

local function safeConnect(signal, callback)
    if not signal then
        return nil
    end

    local connection

    local ok = pcall(function()
        connection = signal:Connect(callback)
    end)

    if ok and connection then
        table.insert(connections, connection)
    end

    return connection
end

local function findGuiButton(name)
    local object = playerGui:FindFirstChild(name, true)

    if object and object:IsA("GuiButton") then
        return object
    end

    return nil
end

local function setEnabled(enabled)
    state.enabled = enabled == true
end

function Spy.Enable()
    setEnabled(true)
end

function Spy.Disable()
    setEnabled(false)
end

function Spy.Toggle()
    setEnabled(not state.enabled)
end

function Spy.IsEnabled()
    return state.enabled
end

function Spy.GetState()
    return {
        enabled = state.enabled,
    }
end

function Spy.Init(Hub)
    if running then
        return
    end

    running = true

    -- Intentionally do not assume that a spy GUI/button exists.
    -- This prevents the previous:
    -- attempt to index nil with 'Activated'
    -- runtime error.

    local buttonNames = {
        "SpyButton",
        "RemoteSpyButton",
        "spyButton",
        "remoteSpyButton",
    }

    for _, name in ipairs(buttonNames) do
        local button = findGuiButton(name)

        if button then
            safeConnect(
                button.Activated,
                function()
                    Spy.Toggle()
                end
            )

            break
        end
    end
end

function Spy.Destroy()
    running = false
    disconnectAll()
    state.enabled = false
end

return Spy
