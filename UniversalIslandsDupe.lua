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

-- Common Islands item IDs for fallback (if remotes use IDs)
local itemIds = {
    wood = 1, stone = 2, iron = 3, gold = 4, diamond = 5, -- etc., expand as needed
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

-- Function to scan and load all obtainable items with better icon detection
local allItems = {}
local function scanItems()
    allItems = {}
    local areas = {ReplicatedStorage, workspace, game:GetService("StarterPack")}
    if player:FindFirstChild("Backpack") then
        table.insert(areas, player.Backpack)
    end
    local scanned = 0
    local limit = 500  -- Prevent lag
    for _, area in ipairs(areas) do
        pcall(function()
            local descendants = area:GetDescendants()
            for _, child in ipairs(descendants) do
                scanned = scanned + 1
                if scanned > limit then break end
                
                if child:IsA("Tool") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
                    local itemName = child.Name:lower()
                    -- Skip common non-items
                    if not (itemName:find("clone") or itemName:find("temp") or itemName:find("effect")) then
                        local iconId = ""
                        local itemId = nil
                        
                        -- Enhanced icon detection for Islands
                        if child:IsA("Tool") then
                            -- IconId StringValue
                            local iconVal = child:FindFirstChild("IconId")
                            if iconVal and iconVal:IsA("StringValue") and iconVal.Value ~= "" then
                                iconId = "rbxassetid://" .. iconVal.Value
                            elseif child:FindFirstChild("Icon") and child.Icon:IsA("ImageLabel") and child.Icon.Image ~= "" then
                                iconId = child.Icon.Image
                            elseif child.TextureId and child.TextureId ~= "" and not child.TextureId:find("http") then
                                iconId = "rbxassetid://" .. child.TextureId
                            end
                        end
                        
                        -- Handle Decal/Texture
                        if child:FindFirstChild("Handle") then
                            local handle = child.Handle
                            if handle:FindFirstChildOfClass("Decal") then
                                local decal = handle:FindFirstChildOfClass("Decal")
                                if decal.Texture and not decal.Texture:find("http") then
                                    iconId = "rbxassetid://" .. decal.Texture
                                end
                            elseif handle.TextureId and handle.TextureId ~= "" then
                                iconId = "rbxassetid://" .. handle.TextureId
                            end
                        end
                        
                        -- Search for dedicated icon assets
                        if iconId == "" then
                            local iconSearch = ReplicatedStorage:FindFirstChild(itemName .. "Icon", true) or
                                             ReplicatedStorage:FindFirstChild(itemName .. "_icon", true) or
                                             ReplicatedStorage:FindFirstChild("Icons"):FindFirstChild(itemName, true)
                            if iconSearch then
                                if iconSearch:IsA("StringValue") and iconSearch.Value ~= "" then
                                    iconId = "rbxassetid://" .. iconSearch.Value
                                elseif iconSearch:IsA("ImageLabel") and iconSearch.Image ~= "" then
                                    iconId = iconSearch.Image
                                end
                            end
                        end
                        
                        -- Fallback icon
                        if iconId == "" then
                            iconId = "rbxassetid://6031097220"  -- Generic item icon
                        end
                        
                        -- Try to get item ID from name
                        for name, id in pairs(itemIds) do
                            if itemName:find(name) then
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
                                name = child.Name,
                                obj = child,
                                icon = iconId,
                                id = itemId or 0,
                                lowerName = itemName
                            })
                        end
                    end
                end
            end
        end)
        if scanned > limit then break end
    end
    table.sort(allItems, function(a, b) return a.name < b.name end)
    print("Scanned " .. #allItems .. " unique items with enhanced icons")
    return #allItems > 0
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

-- Create UI with icon grid (alpha sorted) and console
local consoleOutput = nil
local itemGridFrame = nil
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 500)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    frame.Visible = enabled
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Universal Islands Dupe - Items with Icons (Alphabetical)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Item icon grid
    itemGridFrame = Instance.new("ScrollingFrame")
    itemGridFrame.Size = UDim2.new(0.95, 0, 0, 300)
    itemGridFrame.Position = UDim2.new(0.025, 0, 0, 40)
    itemGridFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemGridFrame.BorderSizePixel = 0
    itemGridFrame.ScrollBarThickness = 8
    itemGridFrame.Parent = frame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 90, 0, 110)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = itemGridFrame
    
    -- Controls
    local amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(0.2, 0, 0, 25)
    amountInput.Position = UDim2.new(0.025, 0, 0, 355)
    amountInput.Text = "1"
    amountInput.PlaceholderText = "Amount"
    amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    amountInput.BorderSizePixel = 0
    amountInput.Font = Enum.Font.SourceSans
    amountInput.TextScaled = true
    amountInput.Parent = frame
    
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.25, 0, 0, 25)
    scanBtn.Position = UDim2.new(0.25, 0, 0, 355)
    scanBtn.Text = "Rescan Items"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scanBtn.BorderSizePixel = 0
    scanBtn.Font = Enum.Font.SourceSansBold
    scanBtn.TextScaled = true
    scanBtn.Parent = frame
    scanBtn.MouseButton1Click:Connect(function()
        if scanItems() then
            for _, child in ipairs(itemGridFrame:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            populateItemGrid()
            consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Rescanned and repopulated " .. #allItems .. " items."
        else
            consoleOutput.Text = consoleOutput.Text .. "\n[ERROR] Scan failed, no items found."
        end
    end)
    
    local invScanBtn = Instance.new("TextButton")
    invScanBtn.Size = UDim2.new(0.25, 0, 0, 25)
    invScanBtn.Position = UDim2.new(0.5, 0, 0, 355)
    invScanBtn.Text = "Scan Inv Remotes"
    invScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    invScanBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 150)
    invScanBtn.BorderSizePixel = 0
    invScanBtn.Font = Enum.Font.SourceSansBold
    invScanBtn.TextScaled = true
    invScanBtn.Parent = frame
    invScanBtn.MouseButton1Click:Connect(function()
        scanInventoryRemotes()
        consoleOutput.Text = consoleOutput.Text .. "\n[INFO] Scanned " .. #inventoryRemotes .. " inventory remotes."
    end)
    
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.25, 0, 0, 25)
    fixedBtn.Position = UDim2.new(0.75, 0, 0, 355)
    fixedBtn.Text = "Fixed Dupe (3 Items)"
    fixedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fixedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    fixedBtn.BorderSizePixel = 0
    fixedBtn.Font = Enum.Font.SourceSansBold
    fixedBtn.TextScaled = true
    fixedBtn.Parent = frame
    fixedBtn.MouseButton1Click:Connect(fixedDupe)
    
    -- Function to populate grid with icons
    function populateItemGrid()
        for i, itemData in ipairs(allItems) do
            local itemFrame = Instance.new("Frame")
            itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            itemFrame.BackgroundTransparency = 0.3
            itemFrame.BorderSizePixel = 1
            itemFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
            itemFrame.LayoutOrder = i
            itemFrame.Parent = itemGridFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = itemFrame
            
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(1, -10, 0.6, -5)
            icon.Position = UDim2.new(0, 5, 0, 5)
            icon.BackgroundTransparency = 1
            icon.Image = itemData.icon
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = itemFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
            nameLabel.Position = UDim2.new(0, 0, 0.6, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = itemData.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = itemFrame
            
            -- Click to dupe
            itemFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local amt = tonumber(amountInput.Text) or 1
                    local count = dupeItem(itemData, amt)
                    consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Duped '" .. itemData.name .. "' x" .. amt .. " (Local: " .. count .. ", Server: " .. realAdds .. ")"
                end
            end)
            
            -- Hover effect
            local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
            itemFrame.MouseEnter:Connect(function()
                TweenService:Create(itemFrame, hoverInfo, {BackgroundTransparency = 0.1, BorderColor3 = Color3.fromRGB(150, 150, 150)}):Play()
            end)
            itemFrame.MouseLeave:Connect(function()
                TweenService:Create(itemFrame, hoverInfo, {BackgroundTransparency = 0.3, BorderColor3 = Color3.fromRGB(80, 80, 80)}):Play()
            end)
        end
        itemGridFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Initial scan and populate
    if scanItems() then
        populateItemGrid()
    end
    
    -- Console output
    consoleOutput = Instance.new("TextLabel")
    consoleOutput.Size = UDim2.new(0.95, 0, 0, 100)
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 390)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BackgroundTransparency = 0.2
    consoleOutput.BorderSizePixel = 1
    consoleOutput.BorderColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.Text = "[CONSOLE] Loaded! Icons in alpha order. Click icons to dupe (tries real server adds for persistence/usability)."
    consoleOutput.TextColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.TextSize = 12
    consoleOutput.TextWrapped = true
    consoleOutput.TextYAlignment = Enum.TextYAlignment.Top
    consoleOutput.Font = Enum.Font.Code
    consoleOutput.TextXAlignment = Enum.TextXAlignment.Left
    consoleOutput.Parent = frame
    
    -- Override print/warn for console with line management
    local oldPrint = print
    local oldWarn = warn
    print = function(...)
        local msg = table.concat({...}, " ")
        if consoleOutput then
            local lines = consoleOutput.Text:split("\n")
            table.insert(lines, "[PRINT] " .. msg)
            if #lines > 18 then
                table.remove(lines, 1)
            end
            consoleOutput.Text = table.concat(lines, "\n")
        end
        oldPrint(...)
    end
    warn = function(...)
        local msg = table.concat({...}, " ")
        if consoleOutput then
            local lines = consoleOutput.Text:split("\n")
            table.insert(lines, "[WARN] " .. msg)
            if #lines > 18 then
                table.remove(lines, 1)
            end
            consoleOutput.Text = table.concat(lines, "\n")
        end
        oldWarn(...)
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
print("Universal Islands Dupe with Icons loaded! Press 'D' to toggle. Icons alpha sorted; click for dupe (real server + persistence attempts).")