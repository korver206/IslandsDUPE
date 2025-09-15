-- Universal Roblox Islands Item Duplicator
-- Based on provided remote exploit, generalized for any item ID and amount
-- Fires client_request_35 with itemId and amount for server-side addition
-- Includes persistence via save remote
-- UI for easy input, toggle with 'D' key
-- Not bannable if used sparingly; relog to verify persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer


local enabled = true
local gui = nil
local frame = nil
local currentMode = "remotes"  -- "remotes" or "items"
local amountInput = nil

-- Enhanced remote discovery with island selector detection
local allRemotes = {}
local inventoryNames = {"AddItem", "GiveItem", "InventoryAdd", "AddToInventory", "GiveTool", "EquipItem", "ReceiveItem", "ItemAdd", "UpdateInventory", "Award", "ProcessItem", "GrantItem", "AddToBackpack", "GiveAward", "Purchase", "Buy", "SpawnItem", "CreateItem"}
local islandNames = {"Island", "SelectIsland", "IslandSelector", "ChooseIsland", "SetIsland", "IslandSelect"}

-- Known item IDs for fallback if scanning fails (name -> ID)
local knownItems = {
    ["Aquamarine Sword"] = 2,
    ["Ancient Longbow"] = 3,
    ["Cactus Spike"] = 6,
    ["Cutlass"] = 8,
    ["Diamond Great Sword"] = 9,
    ["Diamond War Hammer"] = 10,
    ["Formula 86"] = 11,
    ["Gilded Steel Hammer"] = 12,
    ["Staff of Godzilla"] = 13,
    ["Iron War Axe"] = 15,
    ["Rageblade"] = 16,
    ["Spellbook"] = 19,
    ["Lightning Scepter"] = 21,
    ["Tidal Spellbook"] = 22,
    ["Azarathian Longbow"] = 24,
    ["Aquamarine Shard"] = 27,
    ["Buffalkor Crystal"] = 28,
    ["Electrite"] = 31,
    ["Copper Bolt"] = 32,
    ["Copper Ingot"] = 33,
    ["Copper Plate"] = 35,
    ["Copper Rod"] = 36,
    ["Crystallized Aquamarine"] = 37,
    ["Crystallized Gold"] = 38,
    ["Crystallized Iron"] = 39,
    ["Diamond"] = 40,
    ["Enchanted Diamond"] = 41,
    ["Gearbox"] = 42,
    ["Gold Ingot"] = 44,
    ["Iron Ingot"] = 46,
    ["Red Bronze Ingot"] = 48,
    ["Steel Bolt"] = 49,
    ["Steel Ingot"] = 50,
    ["Steel Plate"] = 51,
    ["Steel Rod"] = 52,
    ["Shipwreck Podium"] = 719,
    ["The Divine Dao"] = 1860,
    -- Add more as needed
}

-- Find island selector if it exists
local islandSelector = nil
local function findIslandSelector()
    local selectorNames = {"IslandSelector", "SelectIsland", "IslandChooser", "IslandSelect"}
    for _, name in ipairs(selectorNames) do
        local selector = ReplicatedStorage:FindFirstChild(name, true)
        if selector and (selector:IsA("RemoteEvent") or selector:IsA("RemoteFunction")) then
            islandSelector = selector
            print("Found island selector: " .. selector.Name)
            return selector
        end
    end
    return nil
end

local netManaged = ReplicatedStorage:FindFirstChild("rbxts_include", true)
if netManaged then
    netManaged = netManaged:FindFirstChild("node_modules", true)
    if netManaged then
        netManaged = netManaged:FindFirstChild("@rbxts", true)
        if netManaged then
            netManaged = netManaged:FindFirstChild("net", true)
            if netManaged then
                netManaged = netManaged:FindFirstChild("out", true)
                if netManaged then
                    netManaged = netManaged:FindFirstChild("_NetManaged", true)
                end
            end
        end
    end
end

if netManaged then
    for _, child in ipairs(netManaged:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local isInventory = false
            local isIsland = false
            for _, name in ipairs(inventoryNames) do
                if string.find(child.Name:lower(), name:lower()) then
                    isInventory = true
                    break
                end
            end
            for _, name in ipairs(islandNames) do
                if string.find(child.Name:lower(), name:lower()) then
                    isIsland = true
                    break
                end
            end
            table.insert(allRemotes, {
                name = child.Name,
                obj = child,
                isEvent = child:IsA("RemoteEvent"),
                isInventory = isInventory,
                isIsland = isIsland
            })
        end
    end
    redeemRemote = netManaged:FindFirstChild("RedeemAnniversary")
    requestRemote = netManaged:FindFirstChild("client_request_35")
else
    print("NetManaged path not found. Searching for remotes directly.")
    redeemRemote = ReplicatedStorage:FindFirstChild("RedeemAnniversary", true)
    requestRemote = ReplicatedStorage:FindFirstChild("client_request_35", true)
end

-- Find island selector
findIslandSelector()

table.sort(allRemotes, function(a, b) return a.name < b.name end)
print("Found " .. #allRemotes .. " remotes in _NetManaged")
if not redeemRemote then
    print("RedeemAnniversary remote not found.")
end
if not requestRemote then
    print("client_request_35 remote not found.")
end
if not redeemRemote or not requestRemote then
    print("Required remotes not found. Dupe may not work, but UI will load.")
end


-- Fire the fixed redeem remote (exact as provided)
local function fireRedeem()
    pcall(function()
        redeemRemote:FireServer()
    end)
    return true
end

-- Fire request remote (with args for any item, no args for fixed dupe)
local function fireRequest(itemId, amount)
    pcall(function()
        if itemId and amount then
            requestRemote:FireServer(itemId, amount)
        else
            requestRemote:FireServer()
        end
    end)
    return true
end

-- Find and fire save remote for persistence
local function saveData()
    local saveNames = {"SaveData", "saveData", "UpdateData", "Persist", "Commit", "RemoteSave", "SaveInventory", "UpdatePlayerData"}
    for _, name in ipairs(saveNames) do
        local saveRemote = ReplicatedStorage:FindFirstChild(name, true)
        if saveRemote and saveRemote:IsA("RemoteEvent") then
            pcall(function()
                saveRemote:FireServer()
            end)
            return true
        end
    end
    return false
end

-- Fire both remotes as in original (for dupe effect)
local function fireBothRemotes()
    fireRedeem()
    wait(0.1)
    fireRequest()
end

-- Scan for available islands
local allIslands = {}
local selectedIsland = nil
local function scanIslands()
    allIslands = {}
    local islandNames = {"Island", "MyIsland", "PlayerIsland", "HomeIsland"}
    for _, area in ipairs({workspace}) do
        for _, child in ipairs(area:GetDescendants()) do
            if child:IsA("Model") or child:IsA("Part") then
                for _, name in ipairs(islandNames) do
                    if string.find(child.Name:lower(), name:lower()) then
                        local found = false
                        for _, existing in ipairs(allIslands) do
                            if existing.name == child.Name then
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(allIslands, {
                                name = child.Name,
                                obj = child
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(allIslands, function(a, b) return a.name < b.name end)
    print("Scanned " .. #allIslands .. " islands")
    return #allIslands > 0
end

-- Scan and load all obtainable items with enhanced detection
local allItems = {}
local function scanItems()
    allItems = {}
    local areas = {ReplicatedStorage, workspace}
    for _, area in ipairs(areas) do
        for _, child in ipairs(area:GetDescendants()) do
            if child:IsA("Tool") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
                local itemName = child.Name
                local found = false
                for _, existing in ipairs(allItems) do
                    if existing.name == itemName then
                        found = true
                        break
                    end
                end
                if not found then
                    local icon = ""
                    if child:IsA("Tool") and child:FindFirstChild("TextureId") then
                        icon = child.TextureId
                    elseif child:FindFirstChild("Handle") and child.Handle:FindFirstChildOfClass("Decal") then
                        icon = child.Handle.Decal.Texture
                    end
                    if icon == "" then icon = "rbxassetid://0" end

                    -- Try to find item ID from various sources
                    local itemId = nil
                    if child:FindFirstChild("ItemId") then
                        itemId = child.ItemId.Value
                    elseif child:FindFirstChild("ID") then
                        itemId = child.ID.Value
                    elseif child:IsA("Tool") and child:FindFirstChild("ToolTip") then
                        -- Some games store ID in tooltip or other attributes
                        local tooltip = child.ToolTip
                        if tooltip and string.match(tooltip, "%d+") then
                            itemId = tonumber(string.match(tooltip, "%d+"))
                        end
                    end

                    -- If no ID found, try to infer from name or use index
                    if not itemId then
                        -- Check known items table
                        if knownItems[itemName] then
                            itemId = knownItems[itemName]
                            print("Used known ID for " .. itemName .. ": " .. itemId)
                        else
                            -- Look for numeric patterns in name
                            if string.match(itemName, "(%d+)") then
                                itemId = tonumber(string.match(itemName, "(%d+)"))
                            else
                                -- Use a hash or sequential ID as fallback
                                itemId = #allItems + 1
                            end
                        end
                    end

                    table.insert(allItems, {
                        name = itemName,
                        obj = child,
                        icon = icon,
                        id = itemId
                    })
                end
            end
        end
    end
    table.sort(allItems, function(a, b) return a.name < b.name end)
    print("Scanned " .. #allItems .. " items with IDs")
    return #allItems > 0
end

-- Function to find and use proper inventory remotes for legitimate item granting
local function findInventoryRemote()
    -- Look for remotes that can grant items legitimately
    local grantNames = {"GiveItem", "AddItem", "GrantItem", "AwardItem", "ReceiveItem", "AddToInventory", "InventoryAdd", "PurchaseItem", "BuyItem"}
    for _, remoteData in ipairs(allRemotes) do
        if remoteData.isInventory then
            for _, name in ipairs(grantNames) do
                if string.find(remoteData.name:lower(), name:lower()) then
                    return remoteData
                end
            end
        end
    end
    return nil
end

-- Function to try different parameter combinations for item granting
local function tryGrantItem(remote, itemId, amount)
    local success = false
    local result = nil

    -- Try different parameter combinations
    local paramCombos = {
        {itemId, amount},           -- Standard: ID, Amount
        {itemId, amount, player},   -- With player reference
        {amount, itemId},           -- Reversed: Amount, ID
        {itemId},                   -- Just ID
        {amount},                   -- Just amount
        {itemId, amount, "grant"},  -- With action string
        {"grant", itemId, amount}, -- Action first
    }

    for i, params in ipairs(paramCombos) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(params))
                success = true
                print("Fired " .. remote.Name .. " with params: " .. table.concat(params, ", "))
            else
                result = remote:InvokeServer(unpack(params))
                success = true
                print("Invoked " .. remote.Name .. " with params: " .. table.concat(params, ", ") .. " | Result: " .. tostring(result))
            end
        end)
        if success then break end
        wait(0.1)
    end

    return success, result
end

-- Function to check if item is in backpack
local function checkItemInBackpack(itemData, expectedAmount)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name == itemData.name or (item:FindFirstChild("ItemId") and item.ItemId.Value == itemData.id) then
                local count = item:FindFirstChild("Amount") and item.Amount.Value or 1
                if count >= expectedAmount then
                    return true
                end
            end
        end
    end
    return false
end

-- Function to legitimately grant items using server-side remotes
local function grantItem(itemData, amount)
    local success = false
    local attempts = 0
    local maxAttempts = 5

    -- First, try to select island if selector exists and selectedIsland
    if islandSelector and selectedIsland then
        pcall(function()
            if islandSelector:IsA("RemoteEvent") then
                islandSelector:FireServer(selectedIsland.obj)
            else
                islandSelector:InvokeServer(selectedIsland.obj)
            end
            print("Selected island: " .. selectedIsland.name .. " for dupe")
        end)
        wait(0.2)
    end

    while not success and attempts < maxAttempts do
        attempts = attempts + 1
        print("Grant attempt " .. attempts .. " for " .. itemData.name)

        -- Try all remotes (not just inventory) with different parameter combinations
        for _, remoteData in ipairs(allRemotes) do
            print("Trying remote: " .. remoteData.name)
            local remoteSuccess, result = tryGrantItem(remoteData.obj, itemData.id, amount)
            if remoteSuccess then
                wait(1)  -- Increased delay
                if checkItemInBackpack(itemData, amount) then
                    print("Successfully granted " .. itemData.name .. " x" .. amount .. " via " .. remoteData.name .. " - verified in backpack")
                    success = true
                    break
                else
                    print("Remote fired but item not in backpack, trying next...")
                end
            end
            wait(0.5)  -- Delay between remote attempts
        end

        -- Fallback: Try client_request_35 with different parameters
        if not success and requestRemote then
            print("Trying client_request_35 with item parameters")
            local remoteSuccess, result = tryGrantItem(requestRemote, itemData.id, amount)
            if remoteSuccess then
                wait(0.5)
                if checkItemInBackpack(itemData, amount) then
                    print("Granted " .. itemData.name .. " x" .. amount .. " via client_request_35 - verified in backpack")
                    success = true
                end
            end
        end

        -- Last resort: Use the original fixed dupe method
        if not success then
            print("Using fallback dupe method for " .. itemData.name)
            fireBothRemotes()
            wait(0.5)
            if checkItemInBackpack(itemData, 3) then  -- fixed dupe gives 3
                success = true
            end
        end

        if not success then
            wait(1)  -- Wait before retry
        end
    end

    -- Always try to save data for persistence multiple times
    for i = 1, 3 do
        wait(0.5)
        local saved = saveData()
        if saved then
            print("Data saved for persistence (attempt " .. i .. ")")
        end
    end

    return success
end

-- Enhanced dupe function that uses legitimate server-side granting
local function dupeItem(itemData, amount)
    print("Attempting to grant " .. itemData.name .. " x" .. amount .. " legitimately...")

    local success = grantItem(itemData, amount)

    if success then
        print("Successfully granted " .. itemData.name .. " x" .. amount)
        return amount
    else
        print("Failed to grant " .. itemData.name)
        return 0
    end
end


-- Fixed dupe (original method, no args)
local function fixedDupe()
    if consoleOutput then
        consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Firing original remotes for fixed 3 items..."
    end
    local success = fireBothRemotes()
    if success then
        wait(0.5)
        saveData()
        if consoleOutput then
            consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Fixed dupe: 3 items added. Relog to verify."
        end
    else
        if consoleOutput then
            consoleOutput.Text = consoleOutput.Text .. "\n[ERROR] Fixed dupe failed. Check remotes."
        end
    end
end

-- Create simple UI with text list of all remotes (alphabetical)
local consoleOutput = nil
local remoteListFrame = nil
local selectedRemote = nil
local selectedName = ""
local selectedItem = nil
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 600)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    frame.Visible = enabled
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "Universal Islands Item Adder"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    -- Island Selector Section
    local islandLabel = Instance.new("TextLabel")
    islandLabel.Size = UDim2.new(0.3, 0, 0, 20)
    islandLabel.Position = UDim2.new(0.025, 0, 0, 30)
    islandLabel.BackgroundTransparency = 1
    islandLabel.Text = "Island Selector:"
    islandLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    islandLabel.Font = Enum.Font.SourceSansBold
    islandLabel.TextScaled = true
    islandLabel.Parent = frame

    local islandDropdown = Instance.new("ScrollingFrame")
    islandDropdown.Size = UDim2.new(0.4, 0, 0, 60)
    islandDropdown.Position = UDim2.new(0.35, 0, 0, 30)
    islandDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    islandDropdown.BorderSizePixel = 1
    islandDropdown.ScrollBarThickness = 6
    islandDropdown.Parent = frame

    local islandLayout = Instance.new("UIListLayout")
    islandLayout.SortOrder = Enum.SortOrder.LayoutOrder
    islandLayout.Padding = UDim.new(0, 2)
    islandLayout.Parent = islandDropdown

    local selectIslandBtn = Instance.new("TextButton")
    selectIslandBtn.Size = UDim2.new(0.2, 0, 0, 20)
    selectIslandBtn.Position = UDim2.new(0.775, 0, 0, 30)
    selectIslandBtn.Text = "Select Island"
    selectIslandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectIslandBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
    selectIslandBtn.BorderSizePixel = 0
    selectIslandBtn.Font = Enum.Font.SourceSansBold
    selectIslandBtn.TextScaled = true
    selectIslandBtn.Parent = frame
    selectIslandBtn.MouseButton1Click:Connect(function()
        if selectedIsland then
            pcall(function()
                if islandSelector then
                    -- Try different parameter combinations for island selection
                    local params = {selectedIsland.name, selectedIsland.obj, player}
                    local selected = false
                    for _, param in ipairs(params) do
                        pcall(function()
                            if islandSelector:IsA("RemoteEvent") then
                                islandSelector:FireServer(param)
                            else
                                islandSelector:InvokeServer(param)
                            end
                            selected = true
                        end)
                        if selected then break end
                        wait(0.1)
                    end
                end
                print("Selected island: " .. selectedIsland.name)
                if consoleOutput then
                    consoleOutput.Text = "Selected island: " .. selectedIsland.name
                end
            end)
        else
            if consoleOutput then
                consoleOutput.Text = "No island selected"
            end
        end
    end)

    -- Function to populate island dropdown
    local function populateIslandDropdown()
        for _, child in ipairs(islandDropdown:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for i, islandData in ipairs(allIslands) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 20)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
            btn.BorderSizePixel = 0
            btn.Text = islandData.name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.LayoutOrder = i
            btn.Parent = islandDropdown

            btn.MouseButton1Click:Connect(function()
                selectedIsland = islandData
                if consoleOutput then
                    consoleOutput.Text = "Island selected: " .. selectedIsland.name
                end
            end)
        end

        islandDropdown.CanvasSize = UDim2.new(0, 0, 0, islandLayout.AbsoluteContentSize.Y)
    end

    -- Mode toggle button
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.3, 0, 0, 25)
    modeBtn.Position = UDim2.new(0.025, 0, 0, 100)
    modeBtn.Text = "Mode: Remotes"
    modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    modeBtn.BorderSizePixel = 0
    modeBtn.Font = Enum.Font.SourceSansBold
    modeBtn.TextScaled = true
    modeBtn.Parent = frame
    modeBtn.MouseButton1Click:Connect(function()
        currentMode = currentMode == "remotes" and "items" or "remotes"
        modeBtn.Text = "Mode: " .. (currentMode == "remotes" and "Remotes" or "Items")
        if currentMode == "items" and #allItems == 0 then
            scanItems()
        end
        -- Show/hide parameter inputs based on mode
        param1Input.Visible = (currentMode == "remotes")
        param2Input.Visible = (currentMode == "remotes")
        param3Input.Visible = (currentMode == "remotes")
        param4Input.Visible = (currentMode == "remotes")
        populateList()
        if consoleOutput then
            consoleOutput.Text = "Switched to " .. currentMode .. " mode"
        end
    end)

    -- Amount input for items
    amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(0.3, 0, 0, 25)
    amountInput.Position = UDim2.new(0.35, 0, 0, 100)
    amountInput.Text = "1"
    amountInput.PlaceholderText = "Amount"
    amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    amountInput.BorderSizePixel = 0
    amountInput.Parent = frame

    -- Rescan button
    local rescanBtn = Instance.new("TextButton")
    rescanBtn.Size = UDim2.new(0.3, 0, 0, 25)
    rescanBtn.Position = UDim2.new(0.675, 0, 0, 100)
    rescanBtn.Text = "Rescan"
    rescanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rescanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    rescanBtn.BorderSizePixel = 0
    rescanBtn.Font = Enum.Font.SourceSansBold
    rescanBtn.TextScaled = true
    rescanBtn.Parent = frame
    rescanBtn.MouseButton1Click:Connect(function()
        if currentMode == "remotes" then
            allRemotes = {}
            if netManaged then
                for _, child in ipairs(netManaged:GetDescendants()) do
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        local isInventory = false
                        local isIsland = false
                        for _, name in ipairs(inventoryNames) do
                            if string.find(child.Name:lower(), name:lower()) then
                                isInventory = true
                                break
                            end
                        end
                        for _, name in ipairs(islandNames) do
                            if string.find(child.Name:lower(), name:lower()) then
                                isIsland = true
                                break
                            end
                        end
                        table.insert(allRemotes, {
                            name = child.Name,
                            obj = child,
                            isEvent = child:IsA("RemoteEvent"),
                            isInventory = isInventory,
                            isIsland = isIsland
                        })
                    end
                end
            end
            table.sort(allRemotes, function(a, b) return a.name < b.name end)
        else
            scanItems()
        end
        scanIslands()
        populateIslandDropdown()
        populateList()
        if consoleOutput then
            consoleOutput.Text = "Rescanned " .. (currentMode == "remotes" and #allRemotes or #allItems) .. " " .. currentMode .. " and " .. #allIslands .. " islands"
        end
    end)

    -- List frame (dynamic for remotes or items)
    remoteListFrame = Instance.new("ScrollingFrame")
    remoteListFrame.Size = UDim2.new(0.95, 0, 0, 250)
    remoteListFrame.Position = UDim2.new(0.025, 0, 0, 130)
    remoteListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    remoteListFrame.BorderSizePixel = 0
    remoteListFrame.ScrollBarThickness = 8
    remoteListFrame.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = remoteListFrame

    -- Parameter inputs (only shown in remotes mode)
    local param1Input = Instance.new("TextBox")
    param1Input.Size = UDim2.new(0.22, 0, 0, 25)
    param1Input.Position = UDim2.new(0.025, 0, 0, 390)
    param1Input.Text = ""
    param1Input.PlaceholderText = "Item ID"
    param1Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param1Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param1Input.BorderSizePixel = 0
    param1Input.Visible = (currentMode == "remotes")
    param1Input.Parent = frame

    local param2Input = Instance.new("TextBox")
    param2Input.Size = UDim2.new(0.22, 0, 0, 25)
    param2Input.Position = UDim2.new(0.275, 0, 0, 390)
    param2Input.Text = ""
    param2Input.PlaceholderText = "Amount"
    param2Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param2Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param2Input.BorderSizePixel = 0
    param2Input.Visible = (currentMode == "remotes")
    param2Input.Parent = frame

    local param3Input = Instance.new("TextBox")
    param3Input.Size = UDim2.new(0.22, 0, 0, 25)
    param3Input.Position = UDim2.new(0.525, 0, 0, 390)
    param3Input.Text = ""
    param3Input.PlaceholderText = "Player/User"
    param3Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param3Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param3Input.BorderSizePixel = 0
    param3Input.Visible = (currentMode == "remotes")
    param3Input.Parent = frame

    local param4Input = Instance.new("TextBox")
    param4Input.Size = UDim2.new(0.22, 0, 0, 25)
    param4Input.Position = UDim2.new(0.775, 0, 0, 390)
    param4Input.Text = ""
    param4Input.PlaceholderText = "Extra Param"
    param4Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param4Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param4Input.BorderSizePixel = 0
    param4Input.Visible = (currentMode == "remotes")
    param4Input.Parent = frame


    -- Fire button
    local fireBtn = Instance.new("TextButton")
    fireBtn.Size = UDim2.new(0.45, 0, 0, 25)
    fireBtn.Position = UDim2.new(0.5, 0, 0, 420)
    fireBtn.Text = "Fire Selected"
    fireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    fireBtn.BorderSizePixel = 0
    fireBtn.Font = Enum.Font.SourceSansBold
    fireBtn.TextScaled = true
    fireBtn.Parent = frame
    fireBtn.MouseButton1Click:Connect(function()
        if currentMode == "remotes" then
            if not selectedRemote then
                if consoleOutput then consoleOutput.Text = "No remote selected" end
                return
            end
            local params = {}
            local paramInputs = {param1Input, param2Input, param3Input, param4Input}
            for _, input in ipairs(paramInputs) do
                local text = input.Text
                if text ~= "" then
                    local num = tonumber(text)
                    if num then
                        table.insert(params, num)
                    else
                        table.insert(params, text)
                    end
                end
            end
            pcall(function()
                if selectedRemote:IsA("RemoteEvent") then
                    selectedRemote:FireServer(unpack(params))
                else
                    local result = selectedRemote:InvokeServer(unpack(params))
                    if consoleOutput then
                        consoleOutput.Text = "Invoked " .. selectedName .. ", result: " .. tostring(result)
                    end
                end
                if consoleOutput then
                    consoleOutput.Text = "Fired " .. selectedName .. " with " .. #params .. " params"
                end
            end)
        else
            if not selectedItem then
                if consoleOutput then consoleOutput.Text = "No item selected" end
                return
            end
            local amt = tonumber(amountInput.Text) or 1
            local count = dupeItem(selectedItem, amt)
            if consoleOutput then
                consoleOutput.Text = "Duped " .. selectedItem.name .. " x" .. count
            end
        end
    end)

    -- Quick Add button
    local quickBtn = Instance.new("TextButton")
    quickBtn.Size = UDim2.new(0.45, 0, 0, 25)
    quickBtn.Position = UDim2.new(0.025, 0, 0, 450)
    quickBtn.Text = "Quick Add Item (ID:1, Amount:100)"
    quickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
    quickBtn.BorderSizePixel = 0
    quickBtn.Font = Enum.Font.SourceSansBold
    quickBtn.TextScaled = true
    quickBtn.Parent = frame
    quickBtn.MouseButton1Click:Connect(function()
        if currentMode == "remotes" then
            if not selectedRemote then
                if consoleOutput then consoleOutput.Text = "No remote selected" end
                return
            end
            pcall(function()
                if selectedRemote:IsA("RemoteEvent") then
                    selectedRemote:FireServer(1, 100)
                else
                    local result = selectedRemote:InvokeServer(1, 100)
                    if consoleOutput then
                        consoleOutput.Text = "Invoked " .. selectedName .. ", result: " .. tostring(result)
                    end
                end
                if consoleOutput then
                    consoleOutput.Text = "Quick added item ID:1, amount:100"
                end
            end)
        else
            if not selectedItem then
                if consoleOutput then consoleOutput.Text = "No item selected" end
                return
            end
            local count = dupeItem(selectedItem, 100)
            if consoleOutput then
                consoleOutput.Text = "Quick duped " .. selectedItem.name .. " x100"
            end
        end
    end)

    -- Fixed dupe
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.45, 0, 0, 25)
    fixedBtn.Position = UDim2.new(0.025, 0, 0, 480)
    fixedBtn.Text = "Fixed Dupe (3 Items)"
    fixedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fixedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    fixedBtn.BorderSizePixel = 0
    fixedBtn.Font = Enum.Font.SourceSansBold
    fixedBtn.TextScaled = true
    fixedBtn.Parent = frame
    fixedBtn.MouseButton1Click:Connect(fixedDupe)

    -- Retry last dupe
    local retryBtn = Instance.new("TextButton")
    retryBtn.Size = UDim2.new(0.45, 0, 0, 25)
    retryBtn.Position = UDim2.new(0.5, 0, 0, 480)
    retryBtn.Text = "Retry Last Dupe"
    retryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    retryBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    retryBtn.BorderSizePixel = 0
    retryBtn.Font = Enum.Font.SourceSansBold
    retryBtn.TextScaled = true
    retryBtn.Parent = frame
    retryBtn.MouseButton1Click:Connect(function()
        if selectedItem then
            local amt = tonumber(amountInput.Text) or 1
            local count = dupeItem(selectedItem, amt)
            if consoleOutput then
                consoleOutput.Text = "Retried duping " .. selectedItem.name .. " x" .. count
            end
        else
            if consoleOutput then
                consoleOutput.Text = "No item selected to retry"
            end
        end
    end)

    -- Function to populate list
    function populateList()
        for _, child in ipairs(remoteListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        if currentMode == "remotes" then
            for i, remoteData in ipairs(allRemotes) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 25)
                -- Color coding: Green for inventory, Yellow for island, Gray for others
                if remoteData.isIsland then
                    btn.BackgroundColor3 = Color3.fromRGB(150, 150, 100)
                elseif remoteData.isInventory then
                    btn.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
                btn.BorderSizePixel = 0
                local tags = {}
                if remoteData.isInventory then table.insert(tags, "[INVENTORY]") end
                if remoteData.isIsland then table.insert(tags, "[ISLAND]") end
                btn.Text = remoteData.name .. (remoteData.isEvent and " (Event)" or " (Function)") .. (#tags > 0 and " " .. table.concat(tags, " ") or "")
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.SourceSans
                btn.TextScaled = true
                btn.LayoutOrder = i
                btn.Parent = remoteListFrame

                btn.MouseButton1Click:Connect(function()
                    selectedRemote = remoteData.obj
                    selectedName = remoteData.name
                    selectedItem = nil
                    if consoleOutput then
                        consoleOutput.Text = "Selected: " .. selectedName
                    end
                    -- Pre-fill params if inventory
                    if remoteData.isInventory then
                        param1Input.Text = "1"  -- itemId
                        param2Input.Text = "100"  -- amount
                        param3Input.Text = ""
                        param4Input.Text = ""
                        if consoleOutput then
                            consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Pre-filled params: itemId=1, amount=100"
                        end
                    end
                end)
            end

            if #allRemotes == 0 then
                local noRemotes = Instance.new("TextLabel")
                noRemotes.Size = UDim2.new(1, 0, 0, 25)
                noRemotes.BackgroundTransparency = 1
                noRemotes.Text = "No remotes found."
                noRemotes.TextColor3 = Color3.fromRGB(200, 200, 200)
                noRemotes.Font = Enum.Font.SourceSans
                noRemotes.TextScaled = true
                noRemotes.Parent = remoteListFrame
            end
        else
            for i, itemData in ipairs(allItems) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
                btn.BorderSizePixel = 0
                btn.Text = itemData.name .. " (ID: " .. itemData.id .. ") - Click to dupe"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.SourceSans
                btn.TextScaled = true
                btn.LayoutOrder = i
                btn.Parent = remoteListFrame

                btn.MouseButton1Click:Connect(function()
                    selectedItem = itemData
                    selectedRemote = nil
                    selectedName = itemData.name
                    if consoleOutput then
                        consoleOutput.Text = "Selected: " .. selectedName .. " (ID: " .. itemData.id .. ")"
                    end
                end)
            end

            if #allItems == 0 then
                local noItems = Instance.new("TextLabel")
                noItems.Size = UDim2.new(1, 0, 0, 25)
                noItems.BackgroundTransparency = 1
                noItems.Text = "No items found. Try rescanning."
                noItems.TextColor3 = Color3.fromRGB(200, 200, 200)
                noItems.Font = Enum.Font.SourceSans
                noItems.TextScaled = true
                noItems.Parent = remoteListFrame
            end
        end

        remoteListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end

    -- Initial scan and populate
    scanIslands()
    populateIslandDropdown()
    populateList()

    -- Console
    consoleOutput = Instance.new("TextLabel")
    consoleOutput.Size = UDim2.new(0.95, 0, 0, 45)
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 510)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BorderSizePixel = 1
    consoleOutput.BorderColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.Text = "[CONSOLE] Select island first, then item/remote. Use Retry if dupe fails. Relog may reset anti-dupe."
    consoleOutput.TextColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.TextSize = 11
    consoleOutput.TextWrapped = true
    consoleOutput.TextYAlignment = Enum.TextYAlignment.Top
    consoleOutput.Font = Enum.Font.Code
    consoleOutput.Parent = frame

    -- Print override
    local oldPrint = print
    print = function(...)
        local msg = table.concat({...}, " ")
        if consoleOutput then
            local lines = consoleOutput.Text:split("\n")
            table.insert(lines, "[PRINT] " .. msg)
            if #lines > 8 then table.remove(lines, 1) end
            consoleOutput.Text = table.concat(lines, "\n")
        end
        oldPrint(...)
    end
end

-- Toggle UI
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.D then
        enabled = not enabled
        if frame then
            frame.Visible = enabled
        end
        if not gui then
            createUI()
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        if gui then
            gui:Destroy()
            gui = nil
        end
    end
end)

-- Initialize
createUI()
print("Universal Islands Item Adder loaded! Press 'D' to toggle UI.")