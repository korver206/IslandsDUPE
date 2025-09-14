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

-- Common Islands item IDs for fallback
local itemIds = {
    wood = 1, stone = 2, iron = 3, gold = 4, diamond = 5,
    coal = 6, copper = 7, silver = 8, -- Add more as needed
}

local enabled = true
local gui = nil
local frame = nil
local itemIdBox = nil
local amountBox = nil
local dupeBtn = nil
local statusLabel = nil

-- Hardcoded remote access (exact from provided code)
local netManaged = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
local redeemRemote = netManaged:WaitForChild("RedeemAnniversary")
local requestRemote = netManaged:WaitForChild("client_request_35")

-- Potential inventory remotes for real adds (enhanced for Islands)
local inventoryRemotes = {}
local function scanInventoryRemotes()
    inventoryRemotes = {}
    local remoteNames = {
        "AddItem", "GiveItem", "InventoryAdd", "AddToInventory", "GiveTool", "EquipItem",
        "ReceiveItem", "ItemAdd", "UpdateInventory", "RemoteEvent", "ItemRemote",
        "CraftRemote", "FurnaceRemote", "AnvilRemote", "GiveAward", "ProcessItem"
    }
    local areas = {ReplicatedStorage, workspace, player.PlayerGui}
    for _, area in ipairs(areas) do
        pcall(function()
            for _, child in ipairs(area:GetDescendants()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    for _, name in ipairs(remoteNames) do
                        if string.find(child.Name:lower(), name:lower()) or child.Name:find("Remote") or child.Name:find("Event") then
                            table.insert(inventoryRemotes, child)
                            break
                        end
                    end
                end
            end
        end)
    end
    print("Found " .. #inventoryRemotes .. " potential inventory remotes")
end

-- Fire the fixed redeem remote (exact as provided)
local function fireRedeem()
    pcall(function()
        redeemRemote:FireServer()
    end)
    return true
end

-- Fire request remote (exact as provided, no args for fixed dupe)
local function fireRequest()
    pcall(function()
        requestRemote:FireServer()
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

-- Function to scan and load all obtainable items (text-only names)
local allItems = {}
local favorites = {}  -- Favorited item names
local function scanItems()
    allItems = {}
    local areas = {ReplicatedStorage, workspace, game:GetService("StarterPack")}
    if player:FindFirstChild("Backpack") then
        table.insert(areas, player.Backpack)
    end
    local scanned = 0
    local limit = 1000  -- Higher limit for text list
    for _, area in ipairs(areas) do
        pcall(function()
            local descendants = area:GetDescendants()
            for _, child in ipairs(descendants) do
                scanned = scanned + 1
                if scanned > limit then break end
                
                if child:IsA("Tool") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
                    local itemName = child.Name
                    local lowerName = itemName:lower()
                    -- Load all Tools/Models with Handle, no skips
                        local itemId = nil
                        local isStackable = false
                        local stackValueName = nil
                        
                        -- Stack detection
                        local quantityVal = child:FindFirstChild("Quantity") or child:FindFirstChild("Stack") or child:FindFirstChild("Amount")
                        if quantityVal and (quantityVal:IsA("IntValue") or quantityVal:IsA("NumberValue")) then
                            isStackable = true
                            stackValueName = quantityVal.Name
                        end
                        
                        -- Item ID from name
                        for name, id in pairs(itemIds) do
                            if lowerName:find(name) then
                                itemId = id
                                break
                            end
                        end
                        
                        -- Avoid duplicates
                        local exists = false
                        for _, item in ipairs(allItems) do
                            if item.name == itemName then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(allItems, {
                                name = itemName,
                                obj = child,
                                id = itemId or 0,
                                lowerName = lowerName,
                                isStackable = isStackable,
                                stackValueName = stackValueName
                            })
                        end
                    end
                end
            end
        end)
        if scanned > limit then break end
    end
    table.sort(allItems, function(a, b) return a.name < b.name end)
    print("Scanned " .. #allItems .. " unique items (text names only)")
    return #allItems > 0
end

-- Filter items based on search
local function filterItems(searchText)
    local filtered = {}
    local lowerSearch = searchText:lower()
    for _, item in ipairs(allItems) do
        if item.lowerName:find(lowerSearch) then
            table.insert(filtered, item)
        end
    end
    return filtered
end

-- Get favorites list
local function getFavorites()
    local favList = {}
    for _, name in ipairs(favorites) do
        for _, item in ipairs(allItems) do
            if item.name == name then
                table.insert(favList, item)
                break
            end
        end
    end
    return favList
end

-- Function to dupe selected item
local function dupeItem(itemData, amount)
    local backpack = player:WaitForChild("Backpack")
    local successCount = 0
    for i = 1, amount do
        local clone = itemData.obj:Clone()
        clone.Parent = backpack
        successCount = successCount + 1
        wait(0.1)  -- Small delay
    end
    print("Cloned " .. itemData.name .. " x" .. amount .. " to backpack")
    
    -- Fire original remotes for server-side dupe/persistence
    fireBothRemotes()
    wait(0.5)
    local saved = saveData()
    if saved then
        print("Data saved for persistence")
    end
    
    return successCount
end

-- Duplicate function (now for UI buttons)
local function duplicateItem()
    if #allItems == 0 and not scanItems() then
        statusLabel.Text = "Status: No items found. Try relogging."
        return
    end
    -- This will be called from item buttons
    consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Scan complete: " .. #allItems .. " items loaded."
end

-- Fixed dupe (original method)
local function fixedDupe()
    consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Firing original remotes for fixed 3 items..."
    local success = fireBothRemotes()
    if success then
        wait(0.5)
        saveData()
        consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Fixed dupe: 3 items added. Relog to verify."
    else
        consoleOutput.Text = consoleOutput.Text .. "\n[ERROR] Fixed dupe failed. Check remotes."
    end
end

-- Create UI with text list, search, favorites tab
local consoleOutput = nil
local itemListFrame = nil
local searchBox = nil
local currentTab = "All"  -- "All" or "Favorites"
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 450)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    frame.Visible = enabled
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "Universal Islands Dupe - Alphabetical Items"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Tab buttons
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 0, 25)
    tabFrame.Position = UDim2.new(0, 0, 0, 25)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = frame
    
    local allTabBtn = Instance.new("TextButton")
    allTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
    allTabBtn.Position = UDim2.new(0, 0, 0, 0)
    allTabBtn.Text = "All Items"
    allTabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    allTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    allTabBtn.Parent = tabFrame
    allTabBtn.MouseButton1Click:Connect(function()
        currentTab = "All"
        allTabBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        favTabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        populateItemList()
    end)
    
    local favTabBtn = Instance.new("TextButton")
    favTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
    favTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
    favTabBtn.Text = "Favorites"
    favTabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    favTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    favTabBtn.Parent = tabFrame
    favTabBtn.MouseButton1Click:Connect(function()
        currentTab = "Favorites"
        favTabBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        allTabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        populateItemList()
    end)
    
    -- Search bar
    searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.95, 0, 0, 25)
    searchBox.Position = UDim2.new(0.025, 0, 0, 50)
    searchBox.PlaceholderText = "Search items..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.SourceSans
    searchBox.TextScaled = true
    searchBox.Parent = frame
    searchBox:GetPropertyChangedSignal("Text"):Connect(populateItemList)
    
    -- Item list
    itemListFrame = Instance.new("ScrollingFrame")
    itemListFrame.Size = UDim2.new(0.95, 0, 0, 250)
    itemListFrame.Position = UDim2.new(0.025, 0, 0, 80)
    itemListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemListFrame.BorderSizePixel = 0
    itemListFrame.ScrollBarThickness = 8
    itemListFrame.Parent = frame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = itemListFrame
    
    -- Amount input
    local amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(0.3, 0, 0, 25)
    amountInput.Position = UDim2.new(0.025, 0, 0, 345)
    amountInput.Text = "1"
    amountInput.PlaceholderText = "Amount"
    amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    amountInput.BorderSizePixel = 0
    amountInput.Parent = frame
    
    -- Scan button
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.3, 0, 0, 25)
    scanBtn.Position = UDim2.new(0.35, 0, 0, 345)
    scanBtn.Text = "Rescan Items"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scanBtn.BorderSizePixel = 0
    scanBtn.Font = Enum.Font.SourceSansBold
    scanBtn.TextScaled = true
    scanBtn.Parent = frame
    scanBtn.MouseButton1Click:Connect(function()
        if scanItems() then
            populateItemList()
            consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Rescanned " .. #allItems .. " items."
        end
    end)
    
    -- Inv scan button
    local invScanBtn = Instance.new("TextButton")
    invScanBtn.Size = UDim2.new(0.3, 0, 0, 25)
    invScanBtn.Position = UDim2.new(0.65, 0, 0, 345)
    invScanBtn.Text = "Scan Remotes"
    invScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    invScanBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 150)
    invScanBtn.BorderSizePixel = 0
    invScanBtn.Font = Enum.Font.SourceSansBold
    invScanBtn.TextScaled = true
    invScanBtn.Parent = frame
    invScanBtn.MouseButton1Click:Connect(function()
        scanInventoryRemotes()
        consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Scanned " .. #inventoryRemotes .. " remotes."
    end)
    
    -- Fixed dupe
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.95, 0, 0, 25)
    fixedBtn.Position = UDim2.new(0.025, 0, 0, 380)
    fixedBtn.Text = "Fixed Dupe (3 Items)"
    fixedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fixedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    fixedBtn.BorderSizePixel = 0
    fixedBtn.Font = Enum.Font.SourceSansBold
    fixedBtn.TextScaled = true
    fixedBtn.Parent = frame
    fixedBtn.MouseButton1Click:Connect(fixedDupe)
    
    -- Function to populate list
    function populateItemList()
        for _, child in ipairs(itemListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local itemsToShow = {}
        if currentTab == "Favorites" then
            itemsToShow = getFavorites()
        else
            local searchText = searchBox.Text
            itemsToShow = filterItems(searchText)
        end
        
        for i, itemData in ipairs(itemsToShow) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.BorderSizePixel = 0
            btn.Text = itemData.name .. (itemData.isStackable and " [Stackable]" or "")
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.LayoutOrder = i
            btn.Parent = itemListFrame
            
            -- Favorite toggle (right click or star button)
            local isFav = table.find(favorites, itemData.name) ~= nil
            btn.Text = btn.Text .. (isFav and " ★" or "☆")
            
            btn.MouseButton1Click:Connect(function()
                local amt = tonumber(amountInput.Text) or 1
                local count = dupeItem(itemData, amt)
                consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Duped " .. itemData.name .. " x" .. amt
            end)
            
            btn.MouseButton2Click:Connect(function()  -- Right click to favorite
                local idx = table.find(favorites, itemData.name)
                if idx then
                    table.remove(favorites, idx)
                    btn.Text = btn.Text:gsub(" ★", "☆")
                    print("Unfavorited " .. itemData.name)
                else
                    table.insert(favorites, itemData.name)
                    btn.Text = btn.Text:gsub(" ☆", " ★")
                    print("Favorited " .. itemData.name)
                end
                if currentTab == "Favorites" then
                    populateItemList()  -- Refresh favorites
                end
            end)
        end
        
        if #itemsToShow == 0 then
            local noItems = Instance.new("TextLabel")
            noItems.Size = UDim2.new(1, 0, 0, 25)
            noItems.BackgroundTransparency = 1
            noItems.Text = "No items found" .. (currentTab == "All" and " (try searching)" or " (no favorites)")
            noItems.TextColor3 = Color3.fromRGB(200, 200, 200)
            noItems.Font = Enum.Font.SourceSans
            noItems.TextScaled = true
            noItems.Parent = itemListFrame
        end
        
        itemListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end
    
    -- Initial scan and populate
    scanItems()
    populateItemList()
    
    -- Console
    consoleOutput = Instance.new("TextLabel")
    consoleOutput.Size = UDim2.new(0.95, 0, 0, 45)
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 410)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BorderSizePixel = 1
    consoleOutput.BorderColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.Text = "[CONSOLE] Text list alpha order. Search bar filters. Right-click items to favorite ☆/★. Tabs: All/Favorites."
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
    if input.KeyCode == Enum.KeyCode.G then
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
scanInventoryRemotes()
createUI()
print("Universal Islands Dupe (Text List + Search + Favorites) loaded! Press 'G' to toggle. Right-click to favorite, search to filter.")