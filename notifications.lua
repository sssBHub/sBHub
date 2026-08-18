function refreshCharacter()
    backpack = player:WaitForChild("Backpack")

    character =
        player.Character or
        player.CharacterAdded:Wait()

    humanoid =
        character:WaitForChild("Humanoid", 10)

    root =
        character:WaitForChild("HumanoidRootPart", 10)

    gems = player:FindFirstChild("Gems")
    durability = player:FindFirstChild("Durability")

    gameGui = playerGui:FindFirstChild("gameGui")
    rebirthButton = nil

    if gameGui then
        local menu = gameGui:FindFirstChild("rebirthMenu")

        if menu then
            rebirthButton =
                menu:FindFirstChild("confirmButton")
        end
    end

    return character and humanoid and root
end

function getJungleRock()
    local folder =
        workspace:FindFirstChild("machinesFolder")

    if not folder then
        return nil, nil
    end

    local machine =
        folder:FindFirstChild("Ancient Jungle Rock")

    if not machine then
        return nil, nil
    end

    local rock =
        machine:FindFirstChild("Rock", true)

    if not rock or not rock:IsA("BasePart") then
        return nil, nil
    end

    return machine, rock
end

function jungleTarget()
    if not character or not character.Parent then
        return nil
    end

    local machine, rock = getJungleRock()

    if not machine or not rock then
        return nil
    end

    local desired =
        rock.Position +
        Vector3.new(0, 0, 100)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        character,
        machine,
    }

    local result =
        workspace:Raycast(
            Vector3.new(desired.X, 300, desired.Z),
            Vector3.new(0, -600, 0),
            params
        )

    if not result then
        return nil
    end

    local p =
        result.Position +
        Vector3.new(0, 3, 0)

    return CFrame.lookAt(
        p,
        Vector3.new(
            rock.Position.X,
            p.Y,
            rock.Position.Z
        )
    )
end

function createJungleBillboard()
    if jungleBillboard then
        return
    end

    local _, rock = getJungleRock()

    if not rock then
        return
    end

    jungleBillboard =
        Instance.new("BillboardGui")

    jungleBillboard.Name =
        "sB_AutoRockStatus"

    jungleBillboard.Size =
        UDim2.fromOffset(190, 52)

    jungleBillboard.StudsOffset =
        Vector3.new(
            0,
            rock.Size.Y / 2 + 4,
            0
        )

    jungleBillboard.AlwaysOnTop = true
    jungleBillboard.Enabled = false
    jungleBillboard.Parent = rock

    local frame = Instance.new("Frame")
    frame.Name = "Background"
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = GUI_COLORS.panel
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 1
    frame.BorderColor3 = GUI_COLORS.border
    frame.Parent = jungleBillboard

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = GUI_COLORS.text
    label.TextSize = 12
    label.Font = FONT
    label.TextWrapped = true
    label.Parent = frame
end

function updateJungleBillboard(text, active)
    createJungleBillboard()

    if not jungleBillboard then
        return
    end

    jungleBillboard.Enabled = active

    local background =
        jungleBillboard:FindFirstChild("Background")

    local label =
        background and
        background:FindFirstChild("Text")

    if label then
        label.Text = tostring(text or "")
        label.TextColor3 =
            active
            and GUI_COLORS.blue
            or GUI_COLORS.muted
    end
end

function getPunch()
    if not character or not character.Parent then
        return nil
    end

    local punch =
        character:FindFirstChild("Punch")

    if punch and punch:IsA("Tool") then
        return punch
    end

    punch =
        backpack:FindFirstChild("Punch")

    if punch and punch:IsA("Tool") then
        return punch
    end

    return nil
end

function findExercise()
    if not character or not character.Parent then
        return nil
    end

    local choices = {}

    local function scan(container)
        for _, tool in ipairs(container:GetChildren()) do
            if not tool:IsA("Tool") then
                continue
            end

            local gain =
                tool:FindFirstChild("strengthGain")

            local repTime =
                tool:FindFirstChild("repTime")

            if not gain
                or not repTime
                or not gain:IsA("ValueBase")
                or not repTime:IsA("ValueBase") then
                continue
            end

            local requirement =
                tool:FindFirstChild("requiredAmount")

            local req = 0

            if requirement and requirement:IsA("ValueBase") then
                req = tonumber(requirement.Value) or 0
            end

            if strength.Value >= req then
                table.insert(
                    choices,
                    {
                        tool = tool,
                        gain = tonumber(gain.Value) or 0,
                        requirement = req,
                        repTime =
                            math.max(
                                tonumber(repTime.Value) or 0.35,
                                0.01
                            ),
                    }
                )
            end
        end
    end

    scan(backpack)
    scan(character)

    table.sort(
        choices,
        function(a, b)
            if a.requirement ~= b.requirement then
                return a.requirement > b.requirement
            end

            return a.gain > b.gain
        end
    )

    return choices[1]
end

function getRebirthRequirement()
    if not GlobalFunctions then
        return nil
    end

    local fn =
        GlobalFunctions.calculateRequiredRebirthStrength

    if typeof(fn) ~= "function" then
        return nil
    end

    local ok, result =
        pcall(
            fn,
            rebirths.Value,
            player
        )

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

function getNextRebirthGems()
    if not GlobalFunctions then
        return nil
    end

    local fn =
        GlobalFunctions.calculateNextRebirthGems

    if typeof(fn) ~= "function" then
        return nil
    end

    local ok, result =
        pcall(
            fn,
            rebirths.Value
        )

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

function stopRebirthSequence()
    local controller =
        ReplicatedStorage
            :FindFirstChild("client")
            and
            ReplicatedStorage.client:FindFirstChild(
                "controllers"
            )
            and
            ReplicatedStorage.client.controllers:FindFirstChild(
                "RebirthController"
            )

    if not controller
        or not controller:IsA("ModuleScript") then
        return
    end

    local ok, module =
        pcall(require, controller)

    if not ok or type(module) ~= "table" then
        return
    end

    if type(module.StopCameraSequence) == "function" then
        pcall(function()
            module.StopCameraSequence(module)
        end)

        pcall(function()
            module.StopCameraSequence()
        end)
    end
end

function setSettingValue(name, value)
    local menu =
        gameGui
        and
        gameGui:FindFirstChild("settingsMenu")

    local frame =
        menu
        and
        menu:FindFirstChild(
            "settingsFrame",
            true
        )

    if not frame then
        return
    end

    local target =
        frame:FindFirstChild(
            name,
            true
        )

    if not target then
        return
    end

    local amount =
        target:FindFirstChild(
            "amountBox",
            true
        )

    if amount and amount:IsA("TextBox") then
        amount.Text = tostring(value)
    end
end

function applySize()
    local menu =
        gameGui
        and
        gameGui:FindFirstChild("settingsMenu")

    if not menu then
        return
    end

    if state.sizeMode == "Max" then
        local button =
            menu:FindFirstChild(
                "maxSizeButton",
                true
            )

        if button and button:IsA("GuiButton") then
            fire(button.Activated)
        end
    else
        setSettingValue(
            "sizeSetting",
            state.sizeCustom
        )
    end
end

function applySpeed()
    local menu =
        gameGui
        and
        gameGui:FindFirstChild("settingsMenu")

    if not menu then
        return
    end

    if state.speedMode == "Max" then
        local button =
            menu:FindFirstChild(
                "maxSpeedButton",
                true
            )

        if button and button:IsA("GuiButton") then
            fire(button.Activated)
        end
    else
        setSettingValue(
            "speedSetting",
            state.speedCustom
        )
    end
end

function scanPetPool()
    local names = {}

    local runtime =
        ReplicatedStorage
            :FindFirstChild("shared")
            and
            ReplicatedStorage.shared:FindFirstChild(
                "runtime"
            )

    local petFolder =
        runtime
        and
        runtime:FindFirstChild(
            "cPetShopFolder"
        )

    if petFolder then
        for _, obj in ipairs(
            petFolder:GetChildren()
        ) do
            if obj.Name ~= "" then
                names[obj.Name] = true
            end
        end
    end

    local pets =
        player:FindFirstChild(
            "petsFolder"
        )

    if pets then
        for _, rarity in ipairs(
            pets:GetChildren()
        ) do
            for _, pet in ipairs(
                rarity:GetChildren()
            ) do
                names[pet.Name] = true
            end
        end
    end

    local list = {}

    for name in pairs(names) do
        table.insert(list, name)
    end

    table.sort(list)

    return list
end

function scanAuraPool()
    local names = {}

    local pets =
        player:FindFirstChild(
            "powerUpsFolder"
        )

    if pets then
        for _, rarity in ipairs(
            pets:GetChildren()
        ) do
            for _, aura in ipairs(
                rarity:GetChildren()
            ) do
                names[aura.Name] = true
            end
        end
    end

    if gameGui then
        local boosts =
            gameGui:FindFirstChild(
                "itemsMenu"
            )

        boosts =
            boosts
            and
            boosts:FindFirstChild(
                "boostsFrames"
            )

        if boosts then
            for _, obj in ipairs(
                boosts:GetDescendants()
            ) do

                local label =
                    obj:FindFirstChild(
                        "nameLabel"
                    )

                if label
                    and label:IsA("TextLabel")
                    and label.Text ~= "" then

                    names[label.Text] = true
                end
            end
        end
    end

    local list = {}

    for name in pairs(names) do
        table.insert(list, name)
    end

    table.sort(list)

    return list
end

function selectedContains(list, name)
    for _, item in ipairs(list) do
        if item == name then
            return true
        end
    end

    return false
end

function rarityEnabled(rarity)
    rarity = string.lower(tostring(rarity or ""))

    if rarity == "basic" then
        return state.rareBasic
    elseif rarity == "rare" then
        return state.rareRare
    elseif rarity == "epic" then
        return state.rareEpic
    elseif rarity == "unique" then
        return state.rareUnique
    elseif rarity == "advanced" then
        return state.rareAdvanced
    end

    return false
end

function announcePet(pet)
    if not pet then
        return
    end

    local name =
        tostring(pet.Name)

    local rarity =
        pet.Parent
        and
        tostring(pet.Parent.Name)
        or
        "Unknown"

    local selected =
        selectedContains(
            selectedPets,
            name
        )

    local rare =
        state.rarityNotifications
        and
        rarityEnabled(rarity)

    if not selected and not rare then
        return
    end

    if selected then
        crystalStats.selectedPetHits += 1
    end

    if rare then
        crystalStats.rarityHits += 1
    end

    local color =
        rare
        and GUI_COLORS.yellow
        or GUI_COLORS.blue

    notify(
        "NEW PET",
        name .. " • " .. rarity,
        color
    )
end

function announceAura(name, rarity)
    name = tostring(name or "")
    rarity = tostring(rarity or "Unknown")

    local selected =
        selectedContains(
            selectedAuras,
            name
        )

    local rare =
        state.rarityNotifications
        and
        rarityEnabled(rarity)

    if not selected and not rare then
        return
    end

    if selected then
        crystalStats.selectedAuraHits += 1
    end

    if rare then
        crystalStats.rarityHits += 1
    end

    notify(
        "NEW AURA",
        name .. " • " .. rarity,
        rare and GUI_COLORS.yellow or GUI_COLORS.blue
    )
end

function getPetCardSnapshot()
    local result = {}

    if not gameGui then
        return result
    end

    local items =
        gameGui:FindFirstChild(
            "itemsMenu"
        )

    local frames =
        items
        and
        items:FindFirstChild(
            "petsFrames"
        )

    if not frames then
        return result
    end

    for _, obj in ipairs(
        frames:GetDescendants()
    ) do
        if obj:IsA("ObjectValue")
            and obj.Name == "petReference" then

            local value = obj.Value

            if value then
                result[
                    value:GetFullName()
                ] = value
            end
        end
    end

    return result
end

function getAuraSnapshot()
    local result = {}

    if not gameGui then
        return result
    end

    local items =
        gameGui:FindFirstChild(
            "itemsMenu"
        )

    local frames =
        items
        and
        items:FindFirstChild(
            "boostsFrames"
        )

    if not frames then
        return result
    end

    for _, button in ipairs(
        frames:GetDescendants()
    ) do
        if button:IsA("TextButton")
            or button:IsA("ImageButton") then

            local ref =
                button:FindFirstChild(
                    "boostReference",
                    true
                )
                or
                button:FindFirstChild(
                    "itemReference",
                    true
                )
                or
                button:FindFirstChild(
                    "auraReference",
                    true
                )

            if ref
                and ref:IsA("ObjectValue")
                and ref.Value then

                result[
                    ref.Value:GetFullName()
                ] =
                    ref.Value
            end
        end
    end

    return result
end

function refreshNotificationSources()
    local newPets =
        getPetCardSnapshot()

    if next(petReferenceSnapshot) ~= nil then
        for path, pet in pairs(newPets) do
            if not petReferenceSnapshot[path] then
                if pendingCrystalWindow > 0 then
                    announcePet(pet)
                end
            end
        end
    end

    petReferenceSnapshot = newPets

    local newAuras =
        getAuraSnapshot()

    if next(auraReferenceSnapshot) ~= nil then
        for path, aura in pairs(newAuras) do
            if not auraReferenceSnapshot[path] then
                if pendingCrystalWindow > 0 then
                    local rarity =
                        aura.Parent
                        and aura.Parent.Name
                        or "Unknown"

                    announceAura(
                        aura.Name,
                        rarity
                    )
                end
            end
        end
    end

    auraReferenceSnapshot = newAuras
end

function updateHistory()
    local lines = {}

    for i = 1, math.min(#notificationFeed, 18) do
        local event = notificationFeed[i]
        table.insert(
            lines,
            "["
            .. event.time
            .. "] "
            .. event.text
        )
    end

    historyText.Text =
        #lines > 0
        and table.concat(lines, "\n")
        or
        "No notifications yet."
end

function updatePetSelectionText()
    local list = {}

    for i = 1, math.min(#selectedPets, 5) do
        table.insert(list, selectedPets[i])
    end

    if #selectedPets > 5 then
        table.insert(
            list,
            "+" .. tostring(#selectedPets - 5) .. " more"
        )
    end

    petSelectionText.Text =
        "Selected pets:\n"
        ..
        (
            #list > 0
            and table.concat(list, "\n")
            or "None"
        )
end

connect(
    refreshPetListButton.Activated,
    function()
        local pets = scanPetPool()

        if #pets == 0 then
            notify(
                "PET LIST",
                "No pet definitions found.",
                GUI_COLORS.red
            )
            return
        end

        selectedPets = {
            pets[1]
        }

        saveConfig()
        updatePetSelectionText()

        notify(
            "PET LIST",
            "Loaded " .. tostring(#pets) .. " pets.",
            GUI_COLORS.blue
        )
    end
)

goalTypes = {
    "Strength",
    "Durability",
    "Rebirths",
}

connect(
    goalType.Activated,
    function()
        local current =
            table.find(
                goalTypes,
                goal.type
            )
            or 1

        current =
            current % #goalTypes + 1

        goal.type =
            goalTypes[current]

        goalType.Text =
            goal.type

        saveConfig()
    end
)

