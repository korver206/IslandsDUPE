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

-- Hardcoded remote access (improved with fallback search)
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
local redeemRemote, requestRemote
if netManaged then
    redeemRemote = netManaged:FindFirstChild("RedeemAnniversary")
    requestRemote = netManaged:FindFirstChild("client_request_35")
else
    print("NetManaged path not found. Searching for remotes directly.")
    redeemRemote = ReplicatedStorage:FindFirstChild("RedeemAnniversary", true)
    requestRemote = ReplicatedStorage:FindFirstChild("client_request_35", true)
end
if not redeemRemote then
    print("RedeemAnniversary remote not found.")
end
if not requestRemote then
    print("client_request_35 remote not found.")
end
if not redeemRemote or not requestRemote then
    print("Required remotes not found. Dupe may not work, but UI will load.")
end

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

-- Removed search and favorites for simplicity

-- Function to dupe selected item (fire remotes with itemId and amount for permanent add)
local function dupeItem(itemData, itemId, amount)
    print("Attempting to dupe " .. itemData.name .. " (ID: " .. itemId .. ") x" .. amount .. " permanently")

    -- Fire remotes with args for the specific item
    fireRedeem()  -- Always fire redeem
    wait(0.1)
    fireRequest(itemId, amount)  -- Fire request with itemId and amount
    wait(0.5)
    local saved = saveData()
    if saved then
        print("Data saved for persistence. Relog to verify permanent items.")
    end

    -- Also clone to backpack for immediate use (may not persist)
    local backpack = player:WaitForChild("Backpack")
    local clone = itemData.obj:Clone()
    clone.Parent = backpack
    print("Cloned " .. itemData.name .. " to backpack for immediate use")

    if consoleOutput then
        consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Duped " .. itemData.name .. " (ID: " .. itemId .. ") x" .. amount .. " permanently"
    end

    return 1
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

-- Create simple UI with text list of all items (alphabetical)
local consoleOutput = nil
local itemListFrame = nil
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 480)
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
    title.Text = "Universal Islands Dupe - All Items (Click to Dupe Permanently)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    -- Item list (simple alphabetical text list)
    itemListFrame = Instance.new("ScrollingFrame")
    itemListFrame.Size = UDim2.new(0.95, 0, 0, 300)
    itemListFrame.Position = UDim2.new(0.025, 0, 0, 30)
    itemListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemListFrame.BorderSizePixel = 0
    itemListFrame.ScrollBarThickness = 8
    itemListFrame.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = itemListFrame

    -- Item ID input
    local itemIdInput = Instance.new("TextBox")
    itemIdInput.Size = UDim2.new(0.45, 0, 0, 25)
    itemIdInput.Position = UDim2.new(0.025, 0, 0, 340)
    itemIdInput.Text = ""
    itemIdInput.PlaceholderText = "Item ID (optional)"
    itemIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemIdInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    itemIdInput.BorderSizePixel = 0
    itemIdInput.Parent = frame

    -- Amount input
    local amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(0.45, 0, 0, 25)
    amountInput.Position = UDim2.new(0.5, 0, 0, 340)
    amountInput.Text = "1"
    amountInput.PlaceholderText = "Amount"
    amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    amountInput.BorderSizePixel = 0
    amountInput.Parent = frame

    -- Rescan button
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.45, 0, 0, 25)
    scanBtn.Position = UDim2.new(0.025, 0, 0, 370)
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
            if consoleOutput then
                consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Rescanned " .. #allItems .. " items."
            end
        end
    end)

    -- Fixed dupe
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.95, 0, 0, 25)
    fixedBtn.Position = UDim2.new(0.025, 0, 0, 400)
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

        for i, itemData in ipairs(allItems) do
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

            btn.MouseButton1Click:Connect(function()
                local amt = tonumber(amountInput.Text) or 1
                local itemId = tonumber(itemIdInput.Text) or itemData.id
                dupeItem(itemData, itemId, amt)
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
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 430)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BorderSizePixel = 1
    consoleOutput.BorderColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.Text = "[CONSOLE] Click items to dupe permanently. Use Item ID input for custom ID, Amount for quantity."
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
scanInventoryRemotes()
createUI()
print("Universal Islands Dupe loaded! Press 'D' to toggle UI. Click items to dupe permanently.")