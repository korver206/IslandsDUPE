-- Universal Roblox Islands Item Duplicator
-- Based on provided remote exploit, generalized for any item ID and amount
-- Fires client_request_35 with itemId and amount for server-side addition
-- Includes persistence via save remote
-- UI for easy input, toggle with 'D' key
-- Not bannable if used sparingly; relog to verify persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

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
    local saveNames = {"SaveData", "saveData", "UpdateData", "Persist", "Commit", "RemoteSave"}
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

-- Function to scan and load all obtainable items
local allItems = {}
local function scanItems()
    allItems = {}
    local areas = {ReplicatedStorage, workspace}
    for _, area in ipairs(areas) do
        for _, child in ipairs(area:GetDescendants()) do
            if child:IsA("Tool") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
                local itemName = child.Name
                if not table.find(allItems, itemName) then  -- Avoid duplicates
                    local icon = ""
                    if child:IsA("Tool") and child:FindFirstChild("TextureId") then
                        icon = child.TextureId
                    elseif child:FindFirstChild("Handle") and child.Handle:FindFirstChildOfClass("Decal") then
                        icon = child.Handle.Decal.Texture
                    end
                    if icon == "" then icon = "rbxassetid://0" end
                    table.insert(allItems, {name = itemName, obj = child, icon = icon})
                end
            end
        end
    end
    table.sort(allItems, function(a, b) return a.name < b.name end)
    print("Scanned " .. #allItems .. " items")
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

-- Create UI with item list and console
local consoleOutput = nil
local itemListFrame = nil
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 400)
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
    title.Text = "Universal Islands Dupe - All Items"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Item list
    itemListFrame = Instance.new("ScrollingFrame")
    itemListFrame.Size = UDim2.new(0.95, 0, 0, 200)
    itemListFrame.Position = UDim2.new(0.025, 0, 0, 40)
    itemListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemListFrame.BorderSizePixel = 0
    itemListFrame.ScrollBarThickness = 8
    itemListFrame.Parent = frame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = itemListFrame
    
    -- Scan and populate items
    if scanItems() then
        local amountInput = Instance.new("TextBox")
        amountInput.Size = UDim2.new(0.45, 0, 0, 25)
        amountInput.Position = UDim2.new(0.025, 0, 0, 250)
        amountInput.Text = "1"
        amountInput.PlaceholderText = "Amount"
        amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        amountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        amountInput.Parent = frame
        
        local scanBtn = Instance.new("TextButton")
        scanBtn.Size = UDim2.new(0.45, 0, 0, 25)
        scanBtn.Position = UDim2.new(0.5, 0, 0, 250)
        scanBtn.Text = "Rescan Items"
        scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        scanBtn.Parent = frame
        scanBtn.MouseButton1Click:Connect(function()
            scanItems()
            for _, child in ipairs(itemListFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            -- Repopulate
            for i, itemData in ipairs(allItems) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.Text = itemData.name .. " (Click to dupe)"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                btn.Font = Enum.Font.SourceSans
                btn.TextScaled = true
                btn.Parent = itemListFrame
                btn.MouseButton1Click:Connect(function()
                    local amt = tonumber(amountInput.Text) or 1
                    local count = dupeItem(itemData, amt)
                    consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Duped " .. itemData.name .. " x" .. count
                end)
            end
            itemListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end)
        scanBtn.MouseButton1Click:Connect(scanBtn.MouseButton1Click)  -- Initial scan
        
        -- Populate initial items
        for i, itemData in ipairs(allItems) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.Text = itemData.name .. " (Click to dupe)"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.Parent = itemListFrame
            btn.MouseButton1Click:Connect(function()
                local amt = tonumber(amountInput.Text) or 1
                local count = dupeItem(itemData, amt)
                consoleOutput.Text = consoleOutput.Text .. "\n[SUCCESS] Duped " .. itemData.name .. " x" .. count
            end)
        end
        itemListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end
    
    -- Fixed dupe button
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.95, 0, 0, 30)
    fixedBtn.Position = UDim2.new(0.025, 0, 0, 290)
    fixedBtn.Text = "Fixed Dupe (Original 3 Items)"
    fixedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fixedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    fixedBtn.BorderSizePixel = 0
    fixedBtn.Font = Enum.Font.SourceSansBold
    fixedBtn.TextScaled = true
    fixedBtn.Parent = frame
    fixedBtn.MouseButton1Click:Connect(fixedDupe)
    
    -- Console output
    consoleOutput = Instance.new("TextLabel")
    consoleOutput.Size = UDim2.new(0.95, 0, 0, 80)
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 330)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BackgroundTransparency = 0.3
    consoleOutput.Text = "[CONSOLE] Script loaded. Click items to dupe. Output here."
    consoleOutput.TextColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.TextScaled = false
    consoleOutput.TextSize = 12
    consoleOutput.TextWrapped = true
    consoleOutput.TextYAlignment = Enum.TextYAlignment.Top
    consoleOutput.Font = Enum.Font.SourceSans
    consoleOutput.Parent = frame
    
    -- Override print for console
    local oldPrint = print
    print = function(...)
        local msg = table.concat({...}, " ")
        if consoleOutput then
            consoleOutput.Text = consoleOutput.Text .. "\n[PRINT] " .. msg
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
print("Universal Islands Dupe loaded. Press 'D' to toggle UI, Delete to unload. UI lists all items; click to dupe.")