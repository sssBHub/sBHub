task.spawn(function()
    while running do
        task.wait(0.5)

        updatePetAnalyzer()

        gems =
            player:FindFirstChild("Gems")

        durability =
            player:FindFirstChild("Durability")

        local now =
            os.clock()

        local elapsed =
            math.max(
                1,
                now - sessionStart
            )

        local currentStrength =
            tonumber(
                strength.Value
            ) or 0

        local currentRebirths =
            tonumber(
                rebirths.Value
            ) or 0

        local currentDurability =
            durability
            and
            tonumber(
                durability.Value
            )
            or
            0

        local currentGems =
            gems
            and
            tonumber(
                gems.Value
            )
            or
            0

        local strengthGain =
            math.max(
                0,
                currentStrength -
                startingStrength
            )

        local rebirthGain =
            math.max(
                0,
                currentRebirths -
                startingRebirths
            )

        local durabilityGain =
            math.max(
                0,
                currentDurability -
                startingDurability
            )

        local strengthHour =
            strengthGain / elapsed * 3600

        local rebirthHour =
            rebirthGain / elapsed * 3600

        local durabilityHour =
            durabilityGain / elapsed * 3600

        sessionValue.Text =
            formatTime(elapsed)

        strengthStartValue.Text =
            fmt(startingStrength)

        strengthCurrentValue.Text =
            fmt(currentStrength)

        strengthGainValue.Text =
            "+"
            ..
            fmt(strengthGain)

        strengthHourValue.Text =
            fmt(strengthHour)

        rebirthStartValue.Text =
            fmt(startingRebirths)

        rebirthCurrentValue.Text =
            fmt(currentRebirths)

        rebirthGainValue.Text =
            "+"
            ..
            fmt(rebirthGain)

        rebirthHourValue.Text =
            string.format(
                "%.2f",
                rebirthHour
            )

        gemsValue.Text =
            fmt(currentGems)

        durabilityValue.Text =
            fmt(currentDurability)

        durabilityHourValue.Text =
            fmt(durabilityHour)

        exerciseValue.Text =
            tostring(
                currentExercise
            )

        rockValue.Text =
            tostring(
                currentRock
            )

        fpsValue.Text =
            tostring(
                math.floor(fps)
            )

        local requirement =
            getRebirthRequirement()

        if requirement
            and requirement > 0 then

            local progress =
                math.clamp(
                    currentStrength /
                    requirement,
                    0,
                    1
                )

            progressFill.Size =
                UDim2.new(
                    progress,
                    0,
                    1,
                    0
                )

            progressPercent.Text =
                string.format(
                    "%.1f%%",
                    progress * 100
                )

            progressText.Text =
                fmt(currentStrength)
                ..
                " / "
                ..
                fmt(requirement)
                ..
                " Strength"

        else
            progressFill.Size =
                UDim2.new(
                    0,
                    0,
                    1,
                    0
                )

            progressPercent.Text =
                "Waiting"

            progressText.Text =
                "Waiting for rebirth data..."
        end

        local remaining =
            requirement
            and
            math.max(
                0,
                requirement -
                currentStrength
            )
            or
            0

        local goalCurrent =
            getGoalCurrent()

        local goalPercent = 0
        local goalRate = 0

        if goal.target > 0 then
            goalPercent =
                math.clamp(
                    goalCurrent /
                    goal.target,
                    0,
                    1
                )
        end

        if goal.type == "Strength" then
            goalRate =
                strengthGain /
                elapsed

        elseif goal.type == "Durability" then
            goalRate =
                durabilityGain /
                elapsed

        elseif goal.type == "Rebirths" then
            goalRate =
                rebirthGain /
                elapsed
        end

        local etaText = "N/A"

        if goalRate > 0
            and goalCurrent < goal.target then

            etaText =
                formatTime(
                    (
                        goal.target -
                        goalCurrent
                    )
                    /
                    goalRate
                )
        end

        goalProgress.Text =
            "Goal: "
            ..
            goal.type
            ..
            "\n"
            ..
            string.format(
                "%.1f%%",
                goalPercent * 100
            )
            ..
            " • "
            ..
            fmt(goalCurrent)
            ..
            " / "
            ..
            fmt(goal.target)
            ..
            "\nETA: "
            ..
            etaText

        activityText.Text =
            "Exercise: "
            ..
            tostring(
                currentExercise
            )
            ..
            "\nRock: "
            ..
            tostring(
                currentRock
            )
            ..
            "\nRebirth: "
            ..
            (
                requirement
                and
                string.format(
                    "%.1f%%",
                    math.clamp(
                        currentStrength /
                        requirement,
                        0,
                        1
                    ) * 100
                )
                or
                "N/A"
            )

        currentActivity.Text =
            "Exercise: "
            ..
            tostring(
                currentExercise
            )
            ..
            "\n\nTarget: "
            ..
            tostring(
                currentRock
            )
            ..
            "\n\nRebirth: "
            ..
            (
                requirement
                and
                string.format(
                    "%.1f%%",
                    math.clamp(
                        currentStrength /
                        requirement,
                        0,
                        1
                    ) * 100
                )
                or
                "N/A"
            )
            ..
            "\n\nStrength/hr: "
            ..
            fmt(strengthHour)
            ..
            "\nDurability/hr: "
            ..
            fmt(durabilityHour)
            ..
            "\nRebirths/hr: "
            ..
            string.format(
                "%.2f",
                rebirthHour
            )
            ..
            "\n\nGoal: "
            ..
            goal.type
            ..
            "\nETA: "
            ..
            etaText

        if goal.enabled
            and goalCurrent >= goal.target then

            notify(
                "GOAL COMPLETE",
                goal.type .. " reached " .. fmt(goal.target),
                GUI_COLORS.green
            )

            goal.enabled = false
            saveConfig()
        end

        crystalText.Text =
            "Crystals opened: "
            ..
            tostring(
                crystalStats.opened
            )
            ..
            "\nSelected pet hits: "
            ..
            tostring(
                crystalStats.selectedPetHits
            )
            ..
            "\nSelected aura hits: "
            ..
            tostring(
                crystalStats.selectedAuraHits
            )
            ..
            "\nRare hits: "
            ..
            tostring(
                crystalStats.rarityHits
            )

        local overlays =
            state.automationOverlay

        automationOverlay.Visible =
            overlays

        if overlays then
            automationOverlayText.Text =
                "TRAIN     "
                ..
                (state.autoTrain and "● ON" or "○ OFF")
                ..
                "\nREBIRTH   "
                ..
                (state.autoRebirth and "● ON" or "○ OFF")
                ..
                "\nROCK      "
                ..
                (state.autoJungleRock and "● ON" or "○ OFF")
                ..
                "\nEGG       "
                ..
                (state.autoEgg and "● ON" or "○ OFF")
                ..
                "\nULTIMATES "
                ..
                (state.autoUltimates and "● ON" or "○ OFF")
                ..
                "\nSIZE      "
                ..
                (state.autoSize and "● ON" or "○ OFF")
                ..
                "\nSPEED     "
                ..
                (state.autoSpeed and "● ON" or "○ OFF")
                ..
                "\nESP       "
                ..
                (state.esp and "● ON" or "○ OFF")
                ..
                "\nANTI AFK  "
                ..
                (state.antiAFK and "● ON" or "○ OFF")
        end

        performanceOverlay.Visible =
            state.performanceOverlay

        if state.performanceOverlay then
            local ping = "N/A"

            pcall(function()
                local item =
                    Stats.Network.ServerStatsItem[
                        "Data Ping"
                    ]

                if item then
                    ping =
                        string.format(
                            "%.0f ms",
                            item:GetValue()
                        )
                end
            end)

            performanceText.Text =
                "FPS: "
                ..
                tostring(
                    math.floor(fps)
                )
                ..
                "\nPing: "
                ..
                ping
                ..
                "\nSTR/hr: "
                ..
                fmt(strengthHour)
                ..
                "\nDUR/hr: "
                ..
                fmt(durabilityHour)
                ..
                "\nREB/hr: "
                ..
                string.format(
                    "%.2f",
                    rebirthHour
                )
        end
    end
end)

