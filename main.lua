local BASE_URL = "https://raw.githubusercontent.com/sssBHub/sBHub/main/"

local function loadModule(fileName)
    local url = BASE_URL .. fileName .. ".lua"

    print("[sB Hub] Requesting: " .. url)

    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error(
            "[sB Hub] Download failed: "
            .. fileName
            .. "\nURL: "
            .. url
            .. "\nError: "
            .. tostring(source)
        )
    end

    print(
        "[sB Hub] Downloaded "
        .. fileName
        .. " (" .. tostring(#source) .. " bytes)"
    )

    local chunk, compileError = loadstring(source)

    if not chunk then
        error(
            "[sB Hub] Compile failed: "
            .. fileName
            .. "\n"
            .. tostring(compileError)
        )
    end

    local success, result = pcall(chunk)

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

if Hub.UI and Hub.UI.Init then
    Hub.UI.Init(Hub)
end

print("[sB Hub] Diagnostic build loaded")
