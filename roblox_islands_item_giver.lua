-- Roblox Islands Item Giver Script
-- This script creates a GUI to add any items server-side using paths from Dark Dex.
-- Toggle GUI with G key, close with Shift+G.
-- Items added are permanent and sellable if the remote is correct.
-- Enter item path like "ReplicatedStorage.Tools.vendingMachineIndustrial"

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ItemGiverGUI"
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 300)
frame.Position = UDim2.new(0, 10, 1, -320)
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.BackgroundTransparency = 0.5
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Item Giver"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Parent = frame

local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(1, 0, 0, 20)
amountLabel.Position = UDim2.new(0, 0, 0, 35)
amountLabel.Text = "Amount per Add:"
amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
amountLabel.BackgroundTransparency = 1
amountLabel.Parent = frame

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1, -20, 0, 30)
amountBox.Position = UDim2.new(0, 10, 0, 60)
amountBox.Text = "1"
amountBox.TextColor3 = Color3.fromRGB(0, 0, 0)
amountBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
amountBox.Parent = frame

local itemLabel = Instance.new("TextLabel")
itemLabel.Size = UDim2.new(1, 0, 0, 20)
itemLabel.Position = UDim2.new(0, 0, 0, 95)
itemLabel.Text = "Item Path:"
itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
itemLabel.BackgroundTransparency = 1
itemLabel.Parent = frame

local itemBox = Instance.new("TextBox")
itemBox.Size = UDim2.new(1, -20, 0, 30)
itemBox.Position = UDim2.new(0, 10, 0, 120)
itemBox.Text = "ReplicatedStorage.Tools.vendingMachineIndustrial"
itemBox.TextColor3 = Color3.fromRGB(0, 0, 0)
itemBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
itemBox.Parent = frame

local darkDexButton = Instance.new("TextButton")
darkDexButton.Size = UDim2.new(1, -20, 0, 30)
darkDexButton.Position = UDim2.new(0, 10, 0, 160)
darkDexButton.Text = "Load Dark Dex"
darkDexButton.TextColor3 = Color3.fromRGB(255, 255, 255)
darkDexButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
darkDexButton.Parent = frame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0.3, -7, 0, 30)
scanButton.Position = UDim2.new(0, 10, 0, 200)
scanButton.Text = "Scan Remotes"
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
scanButton.Parent = frame

local vendingScanButton = Instance.new("TextButton")
vendingScanButton.Size = UDim2.new(0.3, -7, 0, 30)
vendingScanButton.Position = UDim2.new(0.35, 10, 0, 200)
vendingScanButton.Text = "Scan Vending"
vendingScanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
vendingScanButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
vendingScanButton.Parent = frame

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0.3, -7, 0, 30)
addButton.Position = UDim2.new(0.7, 10, 0, 200)
addButton.Text = "Add Item"
addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
addButton.Parent = frame

local function getInstanceByPath(path)
    if not path or path == "" then return nil end
    local parts = string.split(path, ".")
    local current = game
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end
    return current
end

darkDexButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
    print("Dark Dex loaded. Use it to find remotes and item paths.")
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 280)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BackgroundTransparency = 1
statusLabel.TextScaled = true
statusLabel.Parent = frame

scanButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "Status: Scanning remotes..."
    print("Scanning for possible item add remotes...")
    local found = 0
    local keywords = {"add", "give", "item", "inventory", "purchase", "buy", "sell", "trade", "equip", "unequip", "craft", "build", "place", "remove", "store", "withdraw", "net", "managed"}
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local lowerName = string.lower(remote.Name)
            for _, keyword in ipairs(keywords) do
                if string.find(lowerName, keyword) then
                    print("Possible remote: " .. remote.Name .. " at " .. remote:GetFullName())
                    found = found + 1
                    break
                end
            end
        end
    end
    print("Scan complete. Found " .. found .. " possible remotes.")
    statusLabel.Text = "Status: Scan complete (" .. found .. " found)"
    wait(3)
    statusLabel.Text = "Status: Ready"
end)

vendingScanButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "Status: Scanning vending machines..."
    print("Scanning for vending machines...")
    local found = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            if string.find(string.lower(obj.Name), "vending") or string.find(string.lower(obj.Name), "machine") then
                print("Vending machine: " .. obj.Name .. " at " .. tostring(obj.Position or obj:GetBoundingBox().Position))
                found = found + 1
            end
        end
    end
    print("Vending scan complete. Found " .. found .. " vending machines.")
    statusLabel.Text = "Status: Vending scan (" .. found .. " found)"
    wait(3)
    statusLabel.Text = "Status: Ready"
end)

addButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "Status: Adding item..."
    local amount = tonumber(amountBox.Text) or 1
    local itemPath = itemBox.Text
    local item = getInstanceByPath(itemPath)
    if item then
        local possibleRemotes = {"AddItem", "GiveItem", "PurchaseItem", "BuyItem", "AddToInventory", "AddItemToInventory", "GiveItemToPlayer", "AddToBackpack", "EquipItem", "UnequipItem", "CraftItem", "BuildItem", "PlaceItem", "StoreItem", "WithdrawItem", "TradeItem", "SellItem", "NetAddItem", "GiveItem"}
        local tried = false
        for _, name in ipairs(possibleRemotes) do
            local remote = game.ReplicatedStorage.Remotes:FindFirstChild(name) or game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
            if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(item.Name, amount)
                else
                    remote:InvokeServer(item.Name, amount)
                end
                print("Tried adding item '" .. item.Name .. "' with remote: " .. remote.Name)
                tried = true
            end
        end
        if tried then
            statusLabel.Text = "Status: Item added (check inventory)"
            wait(2)
            statusLabel.Text = "Status: Ready"
        else
            statusLabel.Text = "Status: No valid remotes found. Use Dark Dex to find one."
            wait(2)
            statusLabel.Text = "Status: Ready"
        end
        print("Tried all possible remotes for " .. item.Name .. " x" .. amount)
    else
        statusLabel.Text = "Status: Item not found at path: " .. itemPath
        warn("Item not found at path: " .. itemPath)
        wait(2)
        statusLabel.Text = "Status: Ready"
    end
end)

local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local duping = false
local dupeConnection

local dupeButton = Instance.new("TextButton")
dupeButton.Size = UDim2.new(1, -20, 0, 30)
dupeButton.Position = UDim2.new(0, 10, 0, 240)
dupeButton.Text = "Start Dupe"
dupeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dupeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
dupeButton.Parent = frame

dupeButton.MouseButton1Click:Connect(function()
    if duping then
        duping = false
        if dupeConnection then
            dupeConnection:Disconnect()
            dupeConnection = nil
        end
        dupeButton.Text = "Start Dupe"
        statusLabel.Text = "Status: Duping stopped"
        print("Duping stopped")
        wait(1)
        statusLabel.Text = "Status: Ready"
    else
        duping = true
        dupeButton.Text = "Stop Dupe"
        statusLabel.Text = "Status: Starting dupe..."
        local amount = tonumber(amountBox.Text) or 1
        local itemPath = itemBox.Text
        local item = getInstanceByPath(itemPath)
        if item then
            local lastFire = 0
            dupeConnection = runService.Heartbeat:Connect(function(dt)
                if not duping then return end
                lastFire = lastFire + dt
                if lastFire >= 0.1 then -- Fire every 0.1 seconds to avoid spam
                    lastFire = 0
                    local possibleRemotes = {"AddItem", "GiveItem", "PurchaseItem", "BuyItem", "AddToInventory", "NetAddItem"}
                    for _, name in ipairs(possibleRemotes) do
                        local remote = game.ReplicatedStorage.Remotes:FindFirstChild(name) or game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
                        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer(item.Name, amount)
                            else
                                remote:InvokeServer(item.Name, amount)
                            end
                        end
                    end
                end
            end)
            statusLabel.Text = "Status: Duping active"
            print("Duping started for " .. item.Name)
        else
            statusLabel.Text = "Status: Item not found at path: " .. itemPath
            warn("Item not found")
            duping = false
            dupeButton.Text = "Start Dupe"
            wait(2)
            statusLabel.Text = "Status: Ready"
        end
    end
end)

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) or uis:IsKeyDown(Enum.KeyCode.RightShift) then
            duping = false
            if dupeConnection then
                dupeConnection:Disconnect()
                dupeConnection = nil
            end
            gui:Destroy()
            print("GUI closed")
        else
            frame.Visible = not frame.Visible
        end
    end
end)

print("General Item Giver GUI loaded. Press G to toggle, Shift+G to close.")
print("For anniversary items, manually fire: game:GetService('ReplicatedStorage').rbxts_include.node_modules['@rbxts'].net.out._NetManaged.RedeemAnniversary:FireServer()")
print("client_request_35 may be related; try firing it similarly if needed.")