--[[
    NPC HUNTER — FULLY FIXED
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
local RunService = game:GetService("RunService")

-- ==================== CONFIGURATION ====================
local SCRIPT_URL = "https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua"
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1497331954293674106/4U2_9j_TmEhmkC4Ig3NR_UDega-2c0t4KP3gnw-bNpbxNkRYfa9wcY0J-XF4ETBvCRg1"
local TARGET_PLACE_ID = 77747658251236

local SCAN_INTERVAL = 3
local SCANS_BEFORE_JUMP = 2
local TELEPORT_DELAY = 2

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
    print("[HTTP] ⚠️ WARNING: No HTTP function found! Discord will not work.")
end

-- ==================== DISCORD FUNCTION ====================
local lastSendTime = 0

local function sendDiscord(message, isJump)
    if not httpRequest then
        print("[Discord] Cannot send - no HTTP")
        return false
    end
    
    local now = os.time()
    if now - lastSendTime < 10 then
        print("[Discord] Rate limited, waiting...")
        task.wait(5)
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
        print("[Discord] ✅ Sent: " .. message:sub(1, 50))
        return true
    else
        print("[Discord] ❌ Failed: " .. tostring(err))
        return false
    end
end

-- ==================== CHECK NPCS ====================
local function checkForNPCs()
    print("[Scan] Looking for NPCs...")
    
    local found = {}
    local npcFolder = workspace:FindFirstChild("NPCs")
    
    if not npcFolder then
        print("[Scan] No 'NPCs' folder found in workspace")
        return found
    end
    
    print("[Scan] NPCs folder found! Scanning children...")
    
    for _, child in ipairs(npcFolder:GetChildren()) do
        local childName = child.Name
        print("[Scan] Checking: " .. childName)
        
        -- Check for Kraken
        if childName == "Kraken" then
            local krakenLow = child:FindFirstChild("kraken_low")
            if krakenLow then
                print("[✅] Kraken (Low) found!")
                table.insert(found, "Kraken (Low)")
            else
                print("[✅] Kraken found!")
                table.insert(found, "Kraken")
            end
        end
        
        -- Check for Cosmic Being
        if childName == "CosmicBeingBoss_Normal" or childName == "CosmicBeingBoss" then
            print("[✅] Cosmic Being Boss found!")
            table.insert(found, "Cosmic Being Boss")
        end
        
        -- Check for Sea Serpent
        if childName == "Sea Serpent" or childName == "SeaSerpent" then
            print("[✅] Sea Serpent found!")
            table.insert(found, "Sea Serpent")
        end
    end
    
    return found
end

-- ==================== JUMP TO GAME ====================
local function jumpToTargetGame()
    print(string.rep("=", 60))
    print("[Jump] No NPCs found! Jumping to game: " .. TARGET_PLACE_ID)
    print(string.rep("=", 60))
    
    -- Send Discord notification
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
        -- Fallback method
        pcall(function()
            TeleportService:QueueTeleport(TARGET_PLACE_ID, LocalPlayer)
            task.wait(0.5)
            LocalPlayer:Kick("Jumping to " .. TARGET_PLACE_ID)
        end)
    end
end

-- ==================== SEND FOUND NOTIFICATION ====================
local function sendFoundNotification(npcName)
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
    
    sendDiscord(message, false)
    
    -- Also print to console
    print(string.rep("!", 50))
    print(npcName .. " FOUND!")
    print("Player: " .. LocalPlayer.Name)
    print("Players: " .. playerCount)
    print("Server: " .. game.JobId)
    print(string.rep("!", 50))
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
        LocalPlayer.OnTeleport:Connect(function()
            print("[Auto-Execute] Teleport detected! Reloading script...")
            queue_func('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
        end)
        print("[Auto-Execute] ✅ ACTIVE — Will reload after teleport")
    else
        print("[Auto-Execute] ❌ INACTIVE — queue_on_teleport not available")
        print("[Auto-Execute] You will need to re-run the script manually after teleport")
    end
end

-- ==================== MAIN LOOP ====================
local scanCount = 0
local foundNPCs = {}

local function main()
    print("=" .. string.rep("=", 60))
    print("👾 NPC HUNTER — FULLY FIXED 👾")
    print(string.rep("=", 60))
    print("[Targets]")
    print("  🎯 Kraken (Low)")
    print("  🎯 Cosmic Being Boss")
    print("  🎯 Sea Serpent")
    print(string.format("[Target Game ID] %d", TARGET_PLACE_ID))
    print(string.format("[Scan Interval] %d seconds", SCAN_INTERVAL))
    print(string.format("[Scans Before Jump] %d", SCANS_BEFORE_JUMP))
    print(string.format("[HTTP] %s", httpRequest and "AVAILABLE ✅" or "NOT AVAILABLE ❌"))
    print("=" .. string.rep("=", 60))
    
    -- Setup auto-execute
    setupAutoExecute()
    
    -- Wait for game to load
    print("[Init] Waiting 4 seconds for game to load...")
    task.wait(4)
    
    -- On-screen status
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
    
    task.wait(3)
    statusFrame:Destroy()
    statusGui:Destroy()
    
    -- Main scanning loop
    while true do
        scanCount = scanCount + 1
        print(string.format("\n[Scan #%d] Server: %s", scanCount, string.sub(game.JobId, 1, 20)))
        
        local found = checkForNPCs()
        
        if #found > 0 then
            -- NPC found!
            for _, npc in ipairs(found) do
                sendFoundNotification(npc)
            end
            print(string.format("[Result] ✅ Found %d NPC(s)! Staying in this server.", #found))
            scanCount = 0
            task.wait(SCAN_INTERVAL * 2)
        else
            -- No NPCs found
            print("[Result] ❌ No NPCs found in this server.")
            
            if scanCount >= SCANS_BEFORE_JUMP then
                print(string.format("[Jump] %d scans with no results. Jumping...", SCANS_BEFORE_JUMP))
                jumpToTargetGame()
                break  -- Script ends, auto-execute will reload
            else
                print(string.format("[Wait] Scanning again in %d seconds...", SCAN_INTERVAL))
                task.wait(SCAN_INTERVAL)
            end
        end
    end
end

-- Run the script with error handling
local success, err = pcall(main)
if not success then
    print("[FATAL ERROR] " .. tostring(err))
    print("[FATAL ERROR] Script crashed. Check your executor.")
end

-- Keep script alive
while true do
    task.wait(1)
end
