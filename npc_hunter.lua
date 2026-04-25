--[[
    NPC HUNTER — NO DUPLICATES (FIXED)
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
local TELEPORT_DELAY = 2

-- ==================== TRACK SENT NOTIFICATIONS (PREVENTS DUPLICATES) ====================
local sentThisSession = {}      -- Track which NPCs were sent this session
local sessionResetTime = 0
local hopSentThisSession = false

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

-- ==================== DISCORD FUNCTION (WITH DUPLICATE PROTECTION) ====================
local lastSendTime = 0
local lastMessageHash = ""

local function sendDiscord(message, isJump)
    if not httpRequest then
        print("[Discord] Cannot send - no HTTP")
        return false
    end
    
    -- Create a hash of the message to prevent exact duplicates
    local messageHash = tostring(#message) .. message:sub(1, 50)
    if messageHash == lastMessageHash then
        print("[Discord] Duplicate message blocked")
        return false
    end
    lastMessageHash = messageHash
    
    -- Rate limiting
    local now = os.time()
    if now - lastSendTime < 5 then
        print("[Discord] Rate limited, waiting...")
        task.wait(3)
    end
    lastSendTime = now
    
    local payload = {
        content = message,
        username = "NPC Hunter",
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
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
        print("[Discord] ✅ Sent")
        return true
    else
        print("[Discord] ❌ Failed: " .. tostring(err))
        return false
    end
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
        
        -- Check for Kraken
        if childName == "Kraken" then
            local krakenLow = child:FindFirstChild("kraken_low")
            if krakenLow then
                if not sentThisSession["Kraken (Low)"] then
                    table.insert(found, "Kraken (Low)")
                end
            else
                if not sentThisSession["Kraken"] then
                    table.insert(found, "Kraken")
                end
            end
        end
        
        -- Check for Cosmic Being
        if childName == "CosmicBeingBoss_Normal" or childName == "CosmicBeingBoss" then
            if not sentThisSession["Cosmic Being Boss"] then
                table.insert(found, "Cosmic Being Boss")
            end
        end
        
        -- Check for Sea Serpent
        if childName == "Sea Serpent" or childName == "SeaSerpent" then
            if not sentThisSession["Sea Serpent"] then
                table.insert(found, "Sea Serpent")
            end
        end
    end
    
    return found
end

-- ==================== JUMP TO GAME ====================
local function jumpToTargetGame()
    print(string.rep("=", 60))
    print("[Jump] No NPCs found! Jumping to game: " .. TARGET_PLACE_ID)
    print(string.rep("=", 60))
    
    -- Only send hop notification once per session
    if not hopSentThisSession then
        hopSentThisSession = true
        local playerCount = #Players:GetPlayers()
        local message = string.format(
            "🔄 **NO NPCS FOUND — JUMPING** 🔄\n" ..
            "👤 Player: %s\n" ..
            "👥 Players in server: %d\n" ..
            "🎮 Jumping to game ID: %d\n" ..
            "🌐 Leaving server: %s",
            LocalPlayer.Name,
            playerCount,
            TARGET_PLACE_ID,
            string.sub(game.JobId, 1, 16)
        )
        sendDiscord(message, true)
    end
    
    -- Show notification
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 60)
    frame.Position = UDim2.new(0.5, -200, 0.8, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.Parent = gui
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = "🔄 NO NPCS FOUND!\nJumping to new game in " .. TELEPORT_DELAY .. " seconds..."
    text.TextColor3 = Color3.fromRGB(255, 200, 0)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = frame
    
    task.wait(TELEPORT_DELAY)
    gui:Destroy()
    
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

-- ==================== SEND FOUND NOTIFICATION (ONCE PER NPC PER SESSION) ====================
local function sendFoundNotification(npcName)
    -- Mark as sent so we don't send again this session
    sentThisSession[npcName] = true
    
    local playerCount = #Players:GetPlayers()
    local serverTime = os.date("%H:%M:%S")
    
    local emoji = "👾"
    if npcName:find("Kraken") then emoji = "🐙"
    elseif npcName:find("Cosmic") then emoji = "🌌"
    elseif npcName:find("Sea Serpent") then emoji = "🐍"
    end
    
    local message = string.format(
        "%s **%s FOUND!** %s\n" ..
        "👤 Player: %s\n" ..
        "👥 Players: %d\n" ..
        "⏰ Time: %s\n" ..
        "🌐 Server: %s",
        emoji, npcName, emoji,
        LocalPlayer.Name,
        playerCount,
        serverTime,
        string.sub(game.JobId, 1, 16)
    )
    
    print(string.rep("!", 50))
    print(npcName .. " FOUND! - Sending Discord...")
    print(string.rep("!", 50))
    
    sendDiscord(message, false)
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
        -- Remove any existing connection to prevent duplicates
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
local lastScanTime = 0

local function main()
    print("=" .. string.rep("=", 60))
    print("👾 NPC HUNTER — NO DUPLICATES 👾")
    print(string.rep("=", 60))
    print("[Targets] Kraken | Cosmic Being | Sea Serpent")
    print(string.format("[Target Game ID] %d", TARGET_PLACE_ID))
    print(string.format("[HTTP] %s", httpRequest and "✅" or "❌"))
    print("=" .. string.rep("=", 60))
    
    -- Reset session tracking on new server
    resetSessionTracking()
    
    -- Setup auto-execute
    setupAutoExecute()
    
    -- Wait for game to load
    task.wait(4)
    
    -- On-screen status (brief)
    local statusGui = Instance.new("ScreenGui")
    statusGui.Name = "NPCHunterStatus"
    statusGui.ResetOnSpawn = false
    statusGui.Parent = game:GetService("CoreGui")
    
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0, 300, 0, 40)
    statusFrame.Position = UDim2.new(0.5, -150, 0, 10)
    statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statusFrame.BackgroundTransparency = 0.3
    statusFrame.Parent = statusGui
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.Text = "👾 NPC HUNTER ACTIVE"
    statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusText.TextScaled = true
    statusText.Font = Enum.Font.GothamBold
    statusText.Parent = statusFrame
    
    task.wait(2)
    statusFrame:Destroy()
    statusGui:Destroy()
    
    -- Main scanning loop
    while true do
        scanCount = scanCount + 1
        print(string.format("\n[Scan #%d] Server: %s", scanCount, string.sub(game.JobId, 1, 20)))
        
        local found = checkForNPCs()
        
        if #found > 0 then
            -- NPC found - send once per NPC
            for _, npc in ipairs(found) do
                sendFoundNotification(npc)
            end
            print(string.format("[Result] ✅ Found %d NPC(s)! Staying.", #found))
            scanCount = 0
            task.wait(SCAN_INTERVAL * 2)
        else
            -- No NPCs found
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

-- Run with error handling
local success, err = pcall(main)
if not success then
    print("[FATAL] " .. tostring(err))
end

-- Keep alive
while true do
    task.wait(1)
end
