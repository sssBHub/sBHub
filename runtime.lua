    player.CharacterRemoving,
    function()
        character = nil
        humanoid = nil
        root = nil
        junglePositioned = false
        currentRock = "Recovering"
    end
)

connect(
    player.CharacterAdded,
    function()
        junglePositioned = false
        currentRock = "Recovering"

        task.spawn(function()
            task.wait(0.35)

            if running
                and refreshCharacter() then

                addEvent(
                    "Respawn recovered"
                )

                notify(
                    "RECOVERY",
                    "Character recovered.",
                    GUI_COLORS.green
                )
            end
        end)
    end
)

connect(
    UserInputService.InputBegan,
    function(input, processed)
        if processed or not running then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if hotkeyCapture then
            local key =
                input.KeyCode

            if key ~= Enum.KeyCode.Unknown then
                hotkeys[hotkeyCapture] =
                    key

                local button =
                    hotkeyRows[hotkeyCapture]

                if button then
                    button.Text =
                        key.Name
                end

                hotkeyCapture = nil
                saveConfig()
                return
            end
        end

        if input.KeyCode ==
            Enum.KeyCode.RightShift then

            guiOpen =
                not guiOpen

            gui.Enabled =
                guiOpen

            return
        end

        for name, key in pairs(
            hotkeys
        ) do
            if key
                and input.KeyCode ==
                key then

                if name == "autoPetNotifications" then
                    state.petNotifications =
                        not state.petNotifications

                elseif name == "autoAuraNotifications" then
                    state.auraNotifications =
                        not state.auraNotifications

                elseif state[name] ~= nil
                    and
                    type(state[name]) == "boolean" then

                    state[name] =
                        not state[name]
                end

                saveConfig()
                break
            end
        end
    end
)

dragging = false
dragStart
startPosition

connect(
    titleBar.InputBegan,
    function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPosition =
                window.Position
        end
    end
)

connect(
    UserInputService.InputChanged,
    function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~=
            Enum.UserInputType.MouseMovement then
            return
        end

        local delta =
            input.Position -
            dragStart

        window.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
    end
)

connect(
    UserInputService.InputEnded,
    function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = false
        end
    end
)

connect(
    unloadButton.Activated,
    function()
        if not running then
            return
        end

        running = false

        destroyAllESP()

        if jungleBillboard then
            pcall(function()
                jungleBillboard:Destroy()
            end)
        end

        for _, c in ipairs(
            connections
        ) do
            pcall(function()
                c:Disconnect()
            end)
        end

        table.clear(connections)

        if gui and gui.Parent then
            gui:Destroy()
        end

        if overlayGui and overlayGui.Parent then
            overlayGui:Destroy()
        end

        print("[sB Hub] Unloaded")
    end
)

rebuildSpyList()
refreshCharacter()
showTab("main")
updatePetSelectionText()
saveConfig()

petReferenceSnapshot =
    getPetCardSnapshot()

auraReferenceSnapshot =
    getAuraSnapshot()

print("[sB Hub] Loaded")
