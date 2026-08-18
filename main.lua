local BASE_URL =
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/"

local function loadModule(fileName)
    local url = BASE_URL .. fileName .. ".lua"

    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error(
            "[sB Hub] Download failed: "
            .. fileName
            .. "\n"
            .. tostring(source)
        )
    end

    local chunk, compileError =
        loadstring(source)

    if not chunk then
        error(
            "[sB Hub] Compile failed: "
            .. fileName
            .. "\n"
            .. tostring(compileError)
        )
    end

    local success, result =
        pcall(chunk)

    if not success then
        error(
            "[sB Hub] Runtime error: "
            .. fileName
            .. "\n"
            .. tostring(result)
        )
    end

    return result
end

local Hub = {
    Config = loadModule("config"),
    UI = loadModule("ui"),
    Automation = loadModule("automation"),
    ESP = loadModule("esp"),
    Notifications = loadModule("notifications"),
    Overlays = loadModule("overlays"),
    Stats = loadModule("stats"),
    Spy = loadModule("spy"),
}

if Hub.UI.Init then
    Hub.UI.Init(Hub)
end

if Hub.Automation.Init then
    Hub.Automation.Init(Hub)
end

if Hub.ESP.Init then
    Hub.ESP.Init(Hub)
end

if Hub.Notifications.Init then
    Hub.Notifications.Init(Hub)
end

if Hub.Overlays.Init then
    Hub.Overlays.Init(Hub)
end

if Hub.Stats.Init then
    Hub.Stats.Init(Hub)
end

if Hub.Spy.Init then
    Hub.Spy.Init(Hub)
end

print("[sB Hub] Loaded")
