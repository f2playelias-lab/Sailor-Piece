--[[
    NPC HUNTER — 10 SECOND DELAY + BEAUTIFUL DISCORD EMBEDS
    GitHub: https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua
]]

print("=" .. string.rep("=", 60))
print("NPC HUNTER — LOADING...")
print("=" .. string.rep("=", 60))

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ==================== CONFIGURATION ====================
local SCRIPT_URL = "https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua"
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1497331954293674106/4U2_9j_TmEhmkC4Ig3NR_UDega-2c0t4KP3gnw-bNpbxNkRYfa9wcY0J-XF4ETBvCRg1"
local TARGET_PLACE_ID = 77747658251236

local SCAN_INTERVAL = 3
local SCANS_BEFORE_JUMP = 2
local MIN_HOP_DELAY = 10          -- ← 10 seconds minimum before hopping
local MAX_HOP_DELAY = 10          -- ← Set to same value for exact timing

-- ==================== TRACK SENT NOTIFICATIONS ====================
local sentThisSession = {}
local hopSentThisSession = false
local sessionResetTime = 0

-- ==================== HTTP SETUP ====================
local httpRequest = nil

if syn and syn.request then
    httpRequest = syn.request
    print("[HTTP] Synapse X detected")
elseif request then
    httpRequest = request
    print("[HTTP] Krnl/ScriptWare detected")
elseif http and http.request then
    httpRequest = http.request
    print("[HTTP] Oxygen U detected")
else
    print("[HTTP] ⚠️ WARNING: No HTTP function found!")
end

-- ==================== GET SERVER TIME ====================
local function getServerTime()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return os.date("%H:%M:%S") end
    
    local serverTimeUI = playerGui:FindFirstChild("ServerTimeUI")
    if not serverTimeUI then return os.date("%H:%M:%S") end
    
    -- Try ServerInfo.AutoSizeHolder.ServerTime
    local serverInfo = serverTimeUI:FindFirstChild("ServerInfo")
    if serverInfo then
        local autoSizeHolder = serverInfo:FindFirstChild("AutoSizeHolder")
        if autoSizeHolder then
            local serverTime = autoSizeHolder:FindFirstChild("ServerTime")
            if serverTime and (serverTime:IsA("TextLabel") or serverTime:IsA("TextButton")) then
                local text = serverTime.Text
                if text and text ~= "" then return text end
            end
        end
    end
    
    -- Try ServerTimeClient
    local timeClient = serverTimeUI:FindFirstChild("ServerTimeClient")
    if timeClient and (timeClient:IsA("TextLabel") or timeClient:IsA("TextButton")) then
        local text = timeClient.Text
        if text and text ~= "" then return text end
    end
    
    -- Try ServerTimeClient_v1_BEFORE_X3_EVENTS
    local timeClientV1 = serverTimeUI:FindFirstChild("ServerTimeClient_v1_BEFORE_X3_EVENTS")
    if timeClientV1 and (timeClientV1:IsA("TextLabel") or timeClientV1:IsA("TextButton")) then
        local text = timeClientV1.Text
        if text and text ~= "" then return text end
    end
    
    -- Fallback
    for _, descendant in ipairs(serverTimeUI:GetDescendants()) do
        if (descendant:IsA("TextLabel") or descendant:IsA("TextButton")) and descendant.Text and descendant.Text ~= "" then
            local text = descendant.Text
            if text:match("%d+:%d+") or text:match("%d+") then
                return text
            end
        end
    end
    
    return os.date("%H:%M:%S")
end

-- ==================== GET GAME NAME ====================
local function getGameName()
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and info then
        return info.Name
    end
    return "Unknown Game"
end

-- ==================== BEAUTIFUL DISCORD EMBED FUNCTION ====================
local lastSendTime = 0
local lastMessageHash = ""

local function sendDiscordEmbed(title, description, color, fields, thumbnailUrl)
    if not httpRequest then
        print("[Discord] Cannot send - no HTTP")
        return false
    end
    
    -- Create message hash to prevent duplicates
    local messageHash = title .. tostring(#description) .. tostring(#fields)
    if messageHash == lastMessageHash then
        print("[Discord] Duplicate message blocked")
        return false
    end
    lastMessageHash = messageHash
    
    -- Rate limiting
    local now = os.time()
    if now - lastSendTime < 5 then
        task.wait(3)
    end
    lastSendTime = now
    
    local embed = {
        title = title,
        description = description,
        color = color,
        fields = fields,
        footer = {
            text = "NPC Hunter | " .. os.date("%Y-%m-%d %H:%M:%S UTC"),
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    if thumbnailUrl then
        embed.thumbnail = {url = thumbnailUrl}
    end
    
    local payload = {
        username = "🎯 NPC HUNTER",
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png",
        embeds = {embed}
    }
    
    local success, err = pcall(function()
        return httpRequest({
            Url = DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if success then
        print("[Discord] ✅ Embed sent")
        return true
    else
        print("[Discord] ❌ Failed: " .. tostring(err))
        return false
    end
end

-- ==================== SEND NPC FOUND EMBED ====================
local function sendFoundEmbed(npcName)
    sentThisSession[npcName] = true
    
    local playerCount = #Players:GetPlayers()
    local serverTime = getServerTime()
    local gameName = getGameName()
    
    local emoji = ""
    local color = 0x00FF00
    local thumbnail = ""
    
    if npcName:find("Kraken") then
        emoji = "🐙"
        color = 0x3498DB
        thumbnail = "https://static.wikia.nocookie.net/roblox/images/3/3a/Kraken.png"
    elseif npcName:find("Cosmic") then
        emoji = "🌌"
        color = 0x9B59B6
        thumbnail = "https://static.wikia.nocookie.net/roblox/images/6/6c/Cosmic_Being.png"
    elseif npcName:find("Sea Serpent") then
        emoji = "🐍"
        color = 0x1ABC9C
        thumbnail = "https://static.wikia.nocookie.net/roblox/images/5/5e/Sea_Serpent.png"
    else
        emoji = "👾"
        color = 0x00FF00
    end
    
    local title = string.format("%s **%s** %s", emoji, npcName, emoji)
    local description = string.format("**%s** found a rare NPC in the server!", LocalPlayer.Name)
    
    local fields = {
        {name = "👾 NPC", value = npcName, inline = true},
        {name = "👤 Player", value = LocalPlayer.Name, inline = true},
        {name = "👥 Players Online", value = tostring(playerCount), inline = true},
        {name = "⏰ Server Time", value = serverTime, inline = true},
        {name = "🎮 Game", value = gameName, inline = false},
        {name = "🌐 Server ID", value = string.format("`%s`", string.sub(game.JobId, 1, 20) .. "..."), inline = false},
    }
    
    print(string.rep("!", 50))
    print(npcName .. " FOUND! - Sending Discord embed...")
    print(string.rep("!", 50))
    
    sendDiscordEmbed(title, description, color, fields, thumbnail)
end

-- ==================== SEND HOPPING EMBED ====================
local function sendHoppingEmbed(delay)
    local playerCount = #Players:GetPlayers()
    local serverTime = getServerTime()
    local gameName = getGameName()
    
    local title = "🔄 **SERVER HOPPING** 🔄"
    local description = string.format("No target NPCs found in **%s**.\nHopping to a new server in **%d seconds**.", gameName, delay)
    local color = 0xF39C12
    
    local fields = {
        {name = "🔍 Targets Searched", value = "• Kraken (Low)\n• Cosmic Being Boss\n• Sea Serpent", inline = false},
        {name = "👤 Player", value = LocalPlayer.Name, inline = true},
        {name = "👥 Players in Server", value = tostring(playerCount), inline = true},
        {name = "⏰ Server Time", value = serverTime, inline = true},
        {name = "🎮 Target Game ID", value = string.format("`%d`", TARGET_PLACE_ID), inline = true},
        {name = "🌐 Current Server", value = string.format("`%s`", string.sub(game.JobId, 1, 24) .. "..."), inline = false},
        {name = "⏱️ Hop Timer", value = string.format("Hopping in **%d seconds**...", delay), inline = true},
    }
    
    print("[Discord] Sending hopping embed...")
    sendDiscordEmbed(title, description, color, fields)
end

-- ==================== RESET SESSION TRACKING ====================
local function resetSessionTracking()
    sentThisSession = {}
    hopSentThisSession = false
    sessionResetTime = os.time()
    print("[Session] Tracking reset")
end

-- ==================== CHECK NPCS ====================
local function checkForNPCs()
    print("[Scan] Looking for NPCs...")
    
    local found = {}
    local npcFolder = workspace:FindFirstChild("NPCs")
    
    if not npcFolder then
        print("[Scan] No 'NPCs' folder found")
        return found
    end
    
    for _, child in ipairs(npcFolder:GetChildren()) do
        local childName = child.Name
        
        if childName == "Kraken" then
            local krakenLow = child:FindFirstChild("kraken_low")
            if krakenLow and not sentThisSession["Kraken (Low)"] then
                table.insert(found, "Kraken (Low)")
            elseif not sentThisSession["Kraken"] then
                table.insert(found, "Kraken")
            end
        end
        
        if (childName == "CosmicBeingBoss_Normal" or childName == "CosmicBeingBoss") and not sentThisSession["Cosmic Being Boss"] then
            table.insert(found, "Cosmic Being Boss")
        end
        
        if (childName == "Sea Serpent" or childName == "SeaSerpent") and not sentThisSession["Sea Serpent"] then
            table.insert(found, "Sea Serpent")
        end
    end
    
    return found
end

-- ==================== JUMP TO GAME (WITH 10 SECOND DELAY) ====================
local function jumpToTargetGame()
    print(string.rep("=", 60))
    print("[Jump] No NPCs found! Preparing to jump...")
    print(string.format("[Jump] Target Game ID: %d", TARGET_PLACE_ID))
    print(string.rep("=", 60))
    
    local hopDelay = MIN_HOP_DELAY
    print(string.format("[Jump] Waiting %d seconds before hopping...", hopDelay))
    
    -- Send hopping embed to Discord (only once per session)
    if not hopSentThisSession then
        hopSentThisSession = true
        sendHoppingEmbed(hopDelay)
    end
    
    -- Create countdown GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "HopCountdown"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 100)
    frame.Position = UDim2.new(0.5, -250, 0.7, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔄 NO NPCS FOUND — HOPPING SOON 🔄"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Server time display
    local timeDisplay = Instance.new("TextLabel")
    timeDisplay.Size = UDim2.new(1, 0, 0, 25)
    timeDisplay.Position = UDim2.new(0, 0, 0, 45)
    timeDisplay.BackgroundTransparency = 1
    timeDisplay.Text = string.format("⏰ Server Time: %s", getServerTime())
    timeDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
    timeDisplay.TextScaled = true
    timeDisplay.Font = Enum.Font.Gotham
    timeDisplay.Parent = frame
    
    -- Countdown
    local countdownText = Instance.new("TextLabel")
    countdownText.Size = UDim2.new(1, 0, 0, 35)
    countdownText.Position = UDim2.new(0, 0, 0, 65)
    countdownText.BackgroundTransparency = 1
    countdownText.Text = string.format("Jumping in %d seconds...", hopDelay)
    countdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownText.TextScaled = true
    countdownText.Font = Enum.Font.GothamBold
    countdownText.Parent = frame
    
    -- Update server time and countdown
    for i = hopDelay, 1, -1 do
        countdownText.Text = string.format("Jumping in %d seconds...", i)
        timeDisplay.Text = string.format("⏰ Server Time: %s", getServerTime())
        task.wait(1)
    end
    
    gui:Destroy()
    
    -- Final notification
    local finalGui = Instance.new("ScreenGui")
    finalGui.ResetOnSpawn = false
    finalGui.Parent = game:GetService("CoreGui")
    
    local finalFrame = Instance.new("Frame")
    finalFrame.Size = UDim2.new(0, 400, 0, 60)
    finalFrame.Position = UDim2.new(0.5, -200, 0.8, 0)
    finalFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    finalFrame.BackgroundTransparency = 0.3
    finalFrame.Parent = finalGui
    
    local finalText = Instance.new("TextLabel")
    finalText.Size = UDim2.new(1, 0, 1, 0)
    finalText.Text = "🚀 JUMPING TO NEW GAME... 🚀"
    finalText.TextColor3 = Color3.fromRGB(0, 255, 0)
    finalText.TextScaled = true
    finalText.Font = Enum.Font.GothamBold
    finalText.Parent = finalFrame
    
    task.wait(0.5)
    finalGui:Destroy()
    
    -- Teleport
    local success, err = pcall(function()
        TeleportService:Teleport(TARGET_PLACE_ID, LocalPlayer)
    end)
    
    if not success then
        print("[Jump] Teleport failed: " .. tostring(err))
        pcall(function()
            TeleportService:QueueTeleport(TARGET_PLACE_ID, LocalPlayer)
            task.wait(0.5)
            LocalPlayer:Kick("Jumping to " .. TARGET_PLACE_ID)
        end)
    end
end

-- ==================== AUTO-EXECUTE SETUP ====================
local function setupAutoExecute()
    local queue_func = nil
    
    if syn and syn.queue_on_teleport then
        queue_func = syn.queue_on_teleport
    elseif queue_on_teleport then
        queue_func = queue_on_teleport
    elseif fluxus and fluxus.queue_on_teleport then
        queue_func = fluxus.queue_on_teleport
    end
    
    if queue_func then
        if _G.teleportConnection then
            _G.teleportConnection:Disconnect()
        end
        _G.teleportConnection = LocalPlayer.OnTeleport:Connect(function()
            print("[Auto-Execute] Teleport detected! Reloading script...")
            queue_func('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
        end)
        print("[Auto-Execute] ✅ ACTIVE")
    else
        print("[Auto-Execute] ❌ INACTIVE")
    end
end

-- ==================== MAIN LOOP ====================
local scanCount = 0

local function main()
    print("=" .. string.rep("=", 60))
    print("👾 NPC HUNTER — 10 SECOND HOP DELAY + BEAUTIFUL EMBEDS 👾")
    print(string.rep("=", 60))
    print("[Targets] Kraken | Cosmic Being | Sea Serpent")
    print(string.format("[Target Game ID] %d", TARGET_PLACE_ID))
    print(string.format("[Hop Delay] %d seconds", MIN_HOP_DELAY))
    print(string.format("[HTTP] %s", httpRequest and "✅" or "❌"))
    print("=" .. string.rep("=", 60))
    
    resetSessionTracking()
    setupAutoExecute()
    
    task.wait(4)
    
    -- Brief status popup
    local statusGui = Instance.new("ScreenGui")
    statusGui.Name = "NPCHunterStatus"
    statusGui.ResetOnSpawn = false
    statusGui.Parent = game:GetService("CoreGui")
    
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0, 400, 0, 60)
    statusFrame.Position = UDim2.new(0.5, -200, 0, 10)
    statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statusFrame.BackgroundTransparency = 0.3
    statusFrame.Parent = statusGui
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.Text = "👾 NPC HUNTER ACTIVE\n⏰ Will wait 10 seconds before hopping"
    statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusText.TextScaled = true
    statusText.Font = Enum.Font.GothamBold
    statusText.Parent = statusFrame
    
    task.wait(3)
    statusFrame:Destroy()
    statusGui:Destroy()
    
    while true do
        scanCount = scanCount + 1
        local currentTime = getServerTime()
        print(string.format("\n[Scan #%d] Server: %s", scanCount, string.sub(game.JobId, 1, 20)))
        print(string.format("[Scan #%d] Server Time: %s", scanCount, currentTime))
        
        local found = checkForNPCs()
        
        if #found > 0 then
            for _, npc in ipairs(found) do
                sendFoundEmbed(npc)
            end
            print(string.format("[Result] ✅ Found %d NPC(s)! Staying.", #found))
            scanCount = 0
            task.wait(SCAN_INTERVAL * 2)
        else
            print("[Result] ❌ No NPCs found.")
            
            if scanCount >= SCANS_BEFORE_JUMP then
                jumpToTargetGame()
                break
            else
                task.wait(SCAN_INTERVAL)
            end
        end
    end
end

pcall(main)

while true do
    task.wait(1)
end
