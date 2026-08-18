task.spawn(function()
    while running do
        task.wait()

        if not state.autoTrain then
            continue
        end

        if not character
            or not character.Parent
            or not humanoid
            or not humanoid.Parent then

            refreshCharacter()
            continue
        end

        local selected =
            findExercise()

        if not selected then
            currentExercise =
                "None"

            continue
        end

        currentExercise =
            tostring(
                selected.tool.Name
            )

        local tool =
            selected.tool

        if tool.Parent ~= character then
            pcall(function()
                humanoid:EquipTool(tool)
            end)

            task.wait()
            continue
        end

        pcall(function()
            tool:Activate()
        end)
    end
end)

task.spawn(function()
    while running do
        task.wait(0.1)

        if not state.autoRebirth then
            continue
        end

        if state.rebirthLimit
            and rebirths.Value >=
            state.rebirthTarget then

            continue
        end

        if rebirthButton
            and rebirthButton.Parent
            and rebirthButton.Visible
            and rebirthButton.Active then

            fire(
                rebirthButton.Activated
            )
        end
    end
end)

task.spawn(function()
    while running do
        task.wait(0.04)

        if state.skipRebirthAnimation then
            stopRebirthSequence()

            if humanoid and humanoid.Parent then
                for _, track in ipairs(
                    humanoid:GetPlayingAnimationTracks()
                ) do
                    local name =
                        string.lower(
                            tostring(
                                track.Name
                            )
                        )

                    if name:find(
                        "rebirth",
                        1,
                        true
                    )
                    or name:find(
                        "celebrat",
                        1,
                        true
                    ) then

                        pcall(function()
                            track:Stop(0)
                        end)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while running do
        task.wait(0.08)

        if not state.autoEgg then
            continue
        end

        pcall(function()
            VirtualInputManager:SendKeyEvent(
                true,
                Enum.KeyCode.E,
                false,
                game
            )

            VirtualInputManager:SendKeyEvent(
                false,
                Enum.KeyCode.E,
                false,
                game
            )

            pendingCrystalWindow =
                os.clock() + 2

            crystalStats.opened += 1
        end)
    end
end)

task.spawn(function()
    while running do
        task.wait(0.05)

        if not state.autoJungleRock then
            junglePositioned = false
            currentRock = "OFF"

            if jungleBillboard then
                jungleBillboard.Enabled = false
            end

            continue
        end

        if not character
            or not character.Parent
            or not root
            or not root.Parent then

            currentRock = "Recovering"
            continue
        end

        local target =
            jungleTarget()

        if not target then
            currentRock =
                "Unavailable"
            continue
        end

        currentRock =
            "Ancient Jungle Rock"

        if not junglePositioned then
            pcall(function()
                character:PivotTo(target)
            end)

            junglePositioned = true
        elseif
            (root.Position - target.Position).Magnitude > 4 then

            pcall(function()
                character:PivotTo(target)
            end)
        end

        updateJungleBillboard(
            "● AUTO ROCK ACTIVE\nAncient Jungle Rock",
            true
        )
    end
end)

task.spawn(function()
    while running do
        task.wait()

        if not state.autoJungleRock then
            continue
        end

        if not character
            or not humanoid
            or not humanoid.Parent then
            continue
        end

        local punch =
            getPunch()

        if not punch then
            continue
        end

        if punch.Parent ~= character then
            pcall(function()
                humanoid:EquipTool(punch)
            end)

            task.wait()
        end

        if punch.Parent == character then
            pcall(function()
                punch:Activate()
            end)
        end
    end
end)

task.spawn(function()
    while running do
        task.wait(1)

        if state.autoSize then
            applySize()
        end

        if state.autoSpeed then
            applySpeed()
        end
    end
end)

task.spawn(function()
    while running do
        task.wait(0.5)

        if not state.autoUltimates then
            continue
        end

        local ultimateGui =
            playerGui:FindFirstChild(
                "ultimatesGui"
            )

        if not ultimateGui then
            continue
        end

        for _, object in ipairs(
            ultimateGui:GetDescendants()
        ) do
            if object:IsA("GuiButton") then
                local label =
                    object:FindFirstChild(
                        "titleLabel",
                        true
                    )

                if label and label.Text ~= "" then
                    currentUltimate =
                        tostring(
                            label.Text
                        )

                    fire(
                        object.Activated
                    )

                    task.wait(0.15)
                    break
                end
            end
        end
    end
end)

task.spawn(function()
    while running do
        task.wait(0.25)

        if pendingCrystalWindow > 0
            and os.clock() > pendingCrystalWindow then

            pendingCrystalWindow = 0
        end

        refreshNotificationSources()
        updateHistory()
    end
end)

