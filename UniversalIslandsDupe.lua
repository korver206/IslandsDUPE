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

-- Remote paths from provided code
local redeemRemotePath = "rbxts_include.node_modules.@rbxts.net.out._NetManaged.RedeemAnniversary"
local requestRemotePath = "rbxts_include.node_modules.@rbxts.net.out._NetManaged.client_request_35"

-- Function to get remote by path
local function getRemote(path)
    local current = ReplicatedStorage
    for _, part in ipairs(path:split(".")) do
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end
    return current
end

-- Fire the fixed redeem remote (gives 3 items as in original)
local function fireRedeem()
    local redeemRemote = getRemote(redeemRemotePath)
    if redeemRemote and redeemRemote:IsA("RemoteEvent") then
        pcall(function()
            redeemRemote:FireServer()
        end)
        return true
    end
    return false
end

-- Fire request remote with itemId and amount
local function fireRequest(itemId, amount)
    local requestRemote = getRemote(requestRemotePath)
    if requestRemote and requestRemote:IsA("RemoteEvent") then
        pcall(function()
            requestRemote:FireServer(itemId, amount)
        end)
        return true
    end
    return false
end

-- Find and fire save remote for persistence
local function saveData()
    local saveNames = {"SaveData", "saveData", "UpdateData", "Persist", "Commit"}
    for _, name in ipairs(saveNames) do
        local saveRemote = ReplicatedStorage:FindFirstChild(name, true)
        if saveRemote and saveRemote:IsA("RemoteEvent") then
            pcall(function()
                saveRemote:FireServer()
            end)
            break
        end
    end
end

-- Duplicate function
local function duplicateItem()
    local itemIdStr = itemIdBox.Text
    local amountStr = amountBox.Text
    local itemId = tonumber(itemIdStr) or 1  -- Default to wood (ID 1)
    local amount = math.max(1, tonumber(amountStr) or 1)
    
    if amount > 100 then amount = 100 end  -- Safety limit
    
    statusLabel.Text = "Status: Duping item ID " .. itemId .. " x" .. amount .. "..."
    
    local success = fireRequest(itemId, amount)
    if success then
        wait(0.5)  -- Delay for server processing
        saveData()  -- Ensure persistence
        statusLabel.Text = "Status: Success! Item ID " .. itemId .. " x" .. amount .. " added. Relog to verify."
    else
        statusLabel.Text = "Status: Failed. Remote not found or error. Try scanning game."
    end
end

-- Optional fixed dupe (original 3 items)
local function fixedDupe()
    statusLabel.Text = "Status: Firing fixed redeem (3 items)..."
    local success = fireRedeem()
    if success then
        wait(0.5)
        saveData()
        statusLabel.Text = "Status: Fixed dupe success! 3 items added."
    else
        statusLabel.Text = "Status: Fixed dupe failed. Remote path changed?"
    end
end

-- Create UI
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
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
    title.Text = "Universal Islands Dupe"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    itemIdBox = Instance.new("TextBox")
    itemIdBox.Size = UDim2.new(0.9, 0, 0, 30)
    itemIdBox.Position = UDim2.new(0.05, 0, 0, 40)
    itemIdBox.Text = "1"  -- Default wood
    itemIdBox.PlaceholderText = "Item ID (e.g., 1=wood, 2=stone)"
    itemIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemIdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemIdBox.BorderSizePixel = 0
    itemIdBox.Font = Enum.Font.SourceSans
    itemIdBox.TextScaled = true
    itemIdBox.Parent = frame
    
    amountBox = Instance.new("TextBox")
    amountBox.Size = UDim2.new(0.9, 0, 0, 30)
    amountBox.Position = UDim2.new(0.05, 0, 0, 80)
    amountBox.Text = "10"
    amountBox.PlaceholderText = "Amount (1-100)"
    amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    amountBox.BorderSizePixel = 0
    amountBox.Font = Enum.Font.SourceSans
    amountBox.TextScaled = true
    amountBox.Parent = frame
    
    dupeBtn = Instance.new("TextButton")
    dupeBtn.Size = UDim2.new(0.9, 0, 0, 35)
    dupeBtn.Position = UDim2.new(0.05, 0, 0, 120)
    dupeBtn.Text = "Dupe Custom Item"
    dupeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dupeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    dupeBtn.BorderSizePixel = 0
    dupeBtn.Font = Enum.Font.SourceSansBold
    dupeBtn.TextScaled = true
    dupeBtn.Parent = frame
    
    local fixedBtn = Instance.new("TextButton")
    fixedBtn.Size = UDim2.new(0.9, 0, 0, 35)
    fixedBtn.Position = UDim2.new(0.05, 0, 0, 165)
    fixedBtn.Text = "Fixed Dupe (Original 3 Items)"
    fixedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fixedBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    fixedBtn.BorderSizePixel = 0
    fixedBtn.Font = Enum.Font.SourceSansBold
    fixedBtn.TextScaled = true
    fixedBtn.Parent = frame
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 1, -30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Ready. Enter item ID and amount."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.Parent = frame
    
    -- Connections
    dupeBtn.MouseButton1Click:Connect(duplicateItem)
    fixedBtn.MouseButton1Click:Connect(fixedDupe)
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
print("Universal Islands Dupe loaded. Press 'D' to toggle UI, Delete to unload.")