local function loadModule(fileName)
    local url = BASE_URL .. fileName .. ".lua"

    print("[sB Hub] Loading:", fileName)
    print("[sB Hub] URL:", url)

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
