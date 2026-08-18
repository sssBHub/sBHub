local BASE_URL = "https://raw.githubusercontent.com/sssBHub/sBHub/main/"

local function loadModule(fileName)
    local url = BASE_URL .. fileName .. ".lua"

    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error("[sB Hub] Download failed: " .. fileName .. "\n" .. tostring(source))
    end

    print("[sB Hub] Downloaded " .. fileName .. ".lua (" .. #source .. " bytes)")

    local chunk, compileError = loadstring(source)

    if not chunk then
        error("[sB Hub] Compile failed: " .. fileName .. "\n" .. tostring(compileError))
    end

    local success, result = pcall(chunk)

    if not success then
        error("[sB Hub] Runtime error: " .. fileName .. "\n" .. tostring(result))
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

for name, module in pairs(Hub) do
    if type(module) == "table" and type(module.Init) == "function" then
        local ok, err = pcall(module.Init, Hub)

        if not ok then
            error("[sB Hub] Init failed: " .. name .. "\n" .. tostring(err))
        end
    end
end

print("[sB Hub] Loaded successfully")
