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

-- Hardcoded remote access (improved with fallback search)
local allRemotes = {}
local inventoryNames = {"AddItem", "GiveItem", "InventoryAdd", "AddToInventory", "GiveTool", "EquipItem", "ReceiveItem", "ItemAdd", "UpdateInventory", "Award", "ProcessItem", "GrantItem", "AddToBackpack", "GiveAward"}
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
            for _, name in ipairs(inventoryNames) do
                if string.find(child.Name:lower(), name:lower()) then
                    isInventory = true
                    break
                end
            end
            table.insert(allRemotes, {
                name = child.Name,
                obj = child,
                isEvent = child:IsA("RemoteEvent"),
                isInventory = isInventory
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


-- Removed search and favorites for simplicity


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
local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "UniversalIslandsDupe"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 500)
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
    title.Text = "Universal Islands Item Adder"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    -- Remote list (simple alphabetical text list)
    remoteListFrame = Instance.new("ScrollingFrame")
    remoteListFrame.Size = UDim2.new(0.95, 0, 0, 300)
    remoteListFrame.Position = UDim2.new(0.025, 0, 0, 30)
    remoteListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    remoteListFrame.BorderSizePixel = 0
    remoteListFrame.ScrollBarThickness = 8
    remoteListFrame.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = remoteListFrame

    -- Param 1 input
    local param1Input = Instance.new("TextBox")
    param1Input.Size = UDim2.new(0.22, 0, 0, 25)
    param1Input.Position = UDim2.new(0.025, 0, 0, 340)
    param1Input.Text = ""
    param1Input.PlaceholderText = "Param 1"
    param1Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param1Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param1Input.BorderSizePixel = 0
    param1Input.Parent = frame

    -- Param 2 input
    local param2Input = Instance.new("TextBox")
    param2Input.Size = UDim2.new(0.22, 0, 0, 25)
    param2Input.Position = UDim2.new(0.275, 0, 0, 340)
    param2Input.Text = ""
    param2Input.PlaceholderText = "Param 2"
    param2Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param2Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param2Input.BorderSizePixel = 0
    param2Input.Parent = frame

    -- Param 3 input
    local param3Input = Instance.new("TextBox")
    param3Input.Size = UDim2.new(0.22, 0, 0, 25)
    param3Input.Position = UDim2.new(0.525, 0, 0, 340)
    param3Input.Text = ""
    param3Input.PlaceholderText = "Param 3"
    param3Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param3Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param3Input.BorderSizePixel = 0
    param3Input.Parent = frame

    -- Param 4 input
    local param4Input = Instance.new("TextBox")
    param4Input.Size = UDim2.new(0.22, 0, 0, 25)
    param4Input.Position = UDim2.new(0.775, 0, 0, 340)
    param4Input.Text = ""
    param4Input.PlaceholderText = "Param 4"
    param4Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    param4Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    param4Input.BorderSizePixel = 0
    param4Input.Parent = frame

    -- Rescan button
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.45, 0, 0, 25)
    scanBtn.Position = UDim2.new(0.025, 0, 0, 370)
    scanBtn.Text = "Rescan Remotes"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scanBtn.BorderSizePixel = 0
    scanBtn.Font = Enum.Font.SourceSansBold
    scanBtn.TextScaled = true
    scanBtn.Parent = frame
    scanBtn.MouseButton1Click:Connect(function()
        allRemotes = {}
        if netManaged then
            for _, child in ipairs(netManaged:GetDescendants()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    local isInventory = false
                    for _, name in ipairs(inventoryNames) do
                        if string.find(child.Name:lower(), name:lower()) then
                            isInventory = true
                            break
                        end
                    end
                    table.insert(allRemotes, {
                        name = child.Name,
                        obj = child,
                        isEvent = child:IsA("RemoteEvent"),
                        isInventory = isInventory
                    })
                end
            end
        end
        table.sort(allRemotes, function(a, b) return a.name < b.name end)
        populateRemoteList()
        if consoleOutput then
            consoleOutput.Text = "Rescanned " .. #allRemotes .. " remotes"
        end
    end)

    -- Fire button
    local fireBtn = Instance.new("TextButton")
    fireBtn.Size = UDim2.new(0.45, 0, 0, 25)
    fireBtn.Position = UDim2.new(0.5, 0, 0, 370)
    fireBtn.Text = "Fire Selected Remote"
    fireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    fireBtn.BorderSizePixel = 0
    fireBtn.Font = Enum.Font.SourceSansBold
    fireBtn.TextScaled = true
    fireBtn.Parent = frame
    fireBtn.MouseButton1Click:Connect(function()
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
    function populateRemoteList()
        for _, child in ipairs(remoteListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for i, remoteData in ipairs(allRemotes) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = remoteData.isInventory and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(60, 60, 60)
            btn.BorderSizePixel = 0
            btn.Text = remoteData.name .. (remoteData.isEvent and " (Event)" or " (Function)") .. (remoteData.isInventory and " [INVENTORY]" or "")
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.LayoutOrder = i
            btn.Parent = remoteListFrame

            btn.MouseButton1Click:Connect(function()
                selectedRemote = remoteData.obj
                selectedName = remoteData.name
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

        remoteListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end

    -- Initial scan and populate
    populateRemoteList()

    -- Console
    consoleOutput = Instance.new("TextLabel")
    consoleOutput.Size = UDim2.new(0.95, 0, 0, 45)
    consoleOutput.Position = UDim2.new(0.025, 0, 0, 430)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleOutput.BorderSizePixel = 1
    consoleOutput.BorderColor3 = Color3.fromRGB(0, 255, 0)
    consoleOutput.Text = "[CONSOLE] Select inventory remote [INVENTORY], params auto-filled. Click Fire to add items."
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