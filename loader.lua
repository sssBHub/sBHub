local BASE_URL =
    "https://raw.githubusercontent.com/sssBHub/sBHub/main/"

local function loadModule(fileName)
    local url = BASE_URL .. fileName .. ".lua"

    print("[sB Hub] Loading:", fileName)

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

    print(
        "[sB Hub] Downloaded:",
        fileName,
        #source,
        "bytes"
    )

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


local Hub = {}

Hub.Config = loadModule("config")
Hub.UI = loadModule("ui")
Hub.Automation = loadModule("automation")
Hub.ESP = loadModule("esp")
Hub.Notifications = loadModule("notifications")
Hub.Overlays = loadModule("overlays")
Hub.Stats = loadModule("stats")
Hub.Spy = loadModule("spy")


local function initModule(name, module)
    if type(module) ~= "table" then
        warn(
            "[sB Hub] "
            .. name
            .. " did not return a module table"
        )

        return
    end

    if type(module.Init) ~= "function" then
        warn(
            "[sB Hub] "
            .. name
            .. " has no Init function"
        )

        return
    end

    print("[sB Hub] Initializing:", name)

    local ok, err =
        pcall(function()
            module.Init(Hub)
        end)

    if not ok then
        warn(
            "[sB Hub] Init failed: "
            .. name
        )

        warn(tostring(err))

        return
    end

    print("[sB Hub] Initialized:", name)
end


initModule("UI", Hub.UI)
initModule("Automation", Hub.Automation)
initModule("ESP", Hub.ESP)
initModule("Notifications", Hub.Notifications)
initModule("Overlays", Hub.Overlays)
initModule("Stats", Hub.Stats)
initModule("Spy", Hub.Spy)


print("[sB Hub] Loaded")
