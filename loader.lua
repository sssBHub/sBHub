local BASE_URL = "https://raw.githubusercontent.com/sssBHub/sBHub/main/"

local G = (getgenv and getgenv()) or _G

local function runModule(name)
    local url = BASE_URL .. name .. ".lua"
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        error("[sB Hub] Download failed: " .. name .. "\n" .. tostring(source))
    end

    local chunk, compileError = loadstring(source, "@" .. name .. ".lua")
    if not chunk then
        error("[sB Hub] Compile failed: " .. name .. "\n" .. tostring(compileError))
    end

    if type(setfenv) == "function" then
        pcall(setfenv, chunk, G)
    end

    local success, result = pcall(chunk)
    if not success then
        error("[sB Hub] Runtime error: " .. name .. "\n" .. tostring(result))
    end

    return result
end

local modules = {
    "config",
    "ui",
    "notifications",
    "spy",
    "esp",
    "automation",
    "stats",
    "overlays",
    "runtime",
}

for _, name in ipairs(modules) do
    runModule(name)
end

print("[sB Hub] Modular build loaded")
