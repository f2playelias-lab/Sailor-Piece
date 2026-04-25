--[[
    NPC HUNTER — PERSISTENT AUTO-EXECUTE (FIXED)
    GitHub: https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua
]]

-- ==================== PREVENT DUPLICATE INSTANCES ====================
if _G.NPC_HUNTER_RUNNING then
    print("[NPC Hunter] Already running, skipping duplicate...")
    return
end
_G.NPC_HUNTER_RUNNING = true

-- ==================== AUTO-EXECUTE SETUP (PERSISTENT) ====================
local SCRIPT_URL = "https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua"

-- Detect queue_on_teleport for ALL executors
local queue_on_teleport_func = nil
local executor_name = "Unknown"

if syn and syn.queue_on_teleport then
    queue_on_teleport_func = syn.queue_on_teleport
    executor_name = "Synapse X"
elseif queue_on_teleport then
    queue_on_teleport_func = queue_on_teleport
    executor_name = "Standard"
elseif fluxus and fluxus.queue_on_teleport then
    queue_on_teleport_func = fluxus.queue_on_teleport
    executor_name = "Fluxus"
elseif krnl and krnl.queue_on_teleport then
    queue_on_teleport_func = krnl.queue_on_teleport
    executor_name = "Krnl"
elseif script_context and script_context.queue_on_teleport then
    queue_on_teleport_func = script_context.queue_on_teleport
    executor_name = "ScriptWare"
end

-- Set up PERSISTENT auto-execute (works every time)
if queue_on_teleport_func then
    -- Remove the one-time flag — queue EVERY time
    LocalPlayer.OnTeleport:Connect(function(state)
        print("[Auto-Execute] Teleport detected! Queueing script reload...")
        queue_on_teleport_func('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
    end)
    print("[Auto-Execute] ✅ PERSISTENT auto-execute ACTIVE (" .. executor_name .. ")")
else
    print("[Auto-Execute] ❌ INACTIVE — queue_on_teleport not available for " .. executor_name)
end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- ==================== CONFIGURATION ====================
local CONFIG = {
    TARGETS = {
        {
            Name = "Kraken (Low)",
            Check = function()
                local npcs = workspace:FindFirstChild("NPCs")
                if npcs then
                    local kraken = npcs:FindFirstChild("Kraken")
                    if kraken then
                        return kraken:FindFirstChild("kraken_low") or kraken
                    end
                end
                return nil
            end
        },
        {
            Name = "Cosmic Being Boss",
            Check = function()
                local npcs = workspace:FindFirstChild("NPCs")
                if npcs then
                    return npcs:FindFirstChild("CosmicBeingBoss_Normal") or npcs:FindFirstChild("CosmicBeingBoss")
                end
                return nil
            end
        },
        {
            Name = "Sea Serpent",
            Check = function()
                local npcs = workspace:FindFirstChild("NPCs")
                if npcs then
                    return npcs:FindFirstChild("Sea Serpent") or npcs:FindFirstChild("SeaSerpent")
                end
                return nil
            end
        }
    },
    
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1497331954293674106/4U2_9j_TmEhmkC4Ig3NR_UDega-2c0t4KP3gnw-bNpbxNkRYfa9wcY0J-XF4ETBvCRg1",
    TARGET_PLACE_ID = 77747658251236,
    SCAN_INTERVAL = 3,
    SCANS_BEFORE_JUMP = 2,
    SCAN_DELAY_ON_JOIN = 4,
    TELEPORT_DELAY = 2,
}

-- ==================== HTTP SETUP ====================
local httpRequest = nil
if syn and syn.request then
    httpRequest = syn.request
elseif request then
    httpRequest = request
elseif http and http.request then
    httpRequest = http.request
end

-- ==================== GET PLAYER COUNT ====================
local function getPlayerCount()
    return #Players:GetPlayers()
end

-- ==================== GET SERVER TIME ====================
local function getServerTime()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return os.date("%H:%M:%S") end
    
    local serverTimeUI = playerGui:FindFirstChild("ServerTimeUI")
    if not serverTimeUI then return os.date("%H:%M:%S") end
    
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
    
    local timeClient = serverTimeUI:FindFirstChild("ServerTimeClient")
    if timeClient and (timeClient:IsA("TextLabel") or timeClient:IsA("TextButton")) then
        local text = timeClient.Text
        if text and text ~= "" then return text end
    end
    
    local timeClientV1 = serverTimeUI:FindFirstChild("ServerTimeClient_v1_BEFORE_X3_EVENTS")
    if timeClientV1 and (timeClientV1:IsA("TextLabel") or timeClientV1:IsA("TextButton")) then
        local text = timeClientV1.Text
        if text and text ~= "" then return text end
    end
    
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

-- ==================== CHECK NPC ====================
local function checkNPC(target)
    local instance = nil
    
    pcall(function()
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs then
            if target.Name == "Sea Serpent" then
                instance = npcs:FindFirstChild("Sea Serpent")
            elseif target.Name == "Kraken (Low)" then
                local kraken = npcs:FindFirstChild("Kraken")
                if kraken then
                    instance = kraken:FindFirstChild("kraken_low") or kraken
                end
            elseif target.Name == "Cosmic Being Boss" then
                instance = npcs:FindFirstChild("CosmicBeingBoss_Normal") or npcs:FindFirstChild("CosmicBeingBoss")
            end
        end
    end)
    
    if not instance and target.Check then
        instance = target.Check()
    end
    
    return instance ~= nil
end

-- ==================== DISCORD FUNCTIONS (WITH RATE LIMIT HANDLING) ====================
local lastSend = {}
local lastJumpSend = 0
local discordRateLimit = false

local function sendFoundDiscord(npcName)
    if not httpRequest then 
        print("[Discord] No HTTP function available")
        return 
    end
    
    if discordRateLimit then
        print("[Discord] Rate limited, skipping...")
        return
    end
    
    local now = os.time()
    if lastSend[npcName] and (now - lastSend[npcName]) < 60 then 
        print("[Discord] Cooldown for " .. npcName)
        return 
    end
    lastSend[npcName] = now
    
    local playerCount = getPlayerCount()
    local serverTime = getServerTime()
    local gameName = "Unknown"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        gameName = info.Name
    end)
    
    local emoji = npcName:find("Kraken") and "🐙" or (npcName:find("Cosmic") and "🌌" or "🐍")
    
    local embed = {
        title = string.format("%s %s FOUND! %s", emoji, npcName, emoji),
        description = string.format("**%s** found **%s** in the server!", LocalPlayer.Name, npcName),
        color = 0x00FF00,
        fields = {
            {name = "👾 NPC", value = npcName, inline = true},
            {name = "👤 Player", value = LocalPlayer.Name, inline = true},
            {name = "👥 Players", value = tostring(playerCount), inline = true},
            {name = "⏰ Server Time", value = serverTime, inline = true},
            {name = "🎮 Game", value = gameName, inline = false},
            {name = "🌐 Server", value = string.sub(game.JobId, 1, 20) .. "...", inline = false},
            {name = "🕐 Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = true}
        }
    }
    
    local payload = {username = "👾 NPC HUNTER 👾", embeds = {embed}}
    
    local success, response = pcall(function()
        return httpRequest({
            Url = CONFIG.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if success then
        print("[Discord] ✅ Sent: " .. npcName)
        discordRateLimit = false
    else
        print("[Discord] ❌ Failed: " .. tostring(response))
        if tostring(response):find("429") then
            discordRateLimit = true
            task.wait(5)
            discordRateLimit = false
        end
    end
end

local function sendJumpDiscord()
    if not httpRequest then return end
    if discordRateLimit then return end
    
    local now = os.time()
    if (now - lastJumpSend) < 30 then return end
    lastJumpSend = now
    
    local playerCount = getPlayerCount()
    local serverTime = getServerTime()
    local gameName = "Unknown"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        gameName = info.Name
    end)
    
    local targetsList = ""
    for i, t in ipairs(CONFIG.TARGETS) do
        targetsList = targetsList .. string.format("%d. %s\n", i, t.Name)
    end
    
    local embed = {
        title = "🔄 NO NPCS — JUMPING TO TARGET GAME 🔄",
        description = string.format("**%s** found **NO TARGET NPCS** in **%s**.\nJumping to game ID: **%d**", 
            LocalPlayer.Name, gameName, CONFIG.TARGET_PLACE_ID),
        color = 0xFFAA00,
        fields = {
            {name = "🔍 Targets", value = targetsList, inline = false},
            {name = "👥 Players", value = tostring(playerCount), inline = true},
            {name = "⏰ Server Time", value = serverTime, inline = true},
            {name = "🎮 Current Game", value = gameName, inline = true},
            {name = "🚀 Target Game ID", value = tostring(CONFIG.TARGET_PLACE_ID), inline = true},
            {name = "🌐 Leaving", value = string.sub(game.JobId, 1, 20) .. "...", inline = false}
        }
    }
    
    local payload = {username = "👾 NPC HUNTER 👾", embeds = {embed}}
    pcall(function()
        httpRequest({
            Url = CONFIG.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[Discord] 🔄 Jumping to " .. CONFIG.TARGET_PLACE_ID)
    end)
end

-- ==================== JUMP TO TARGET GAME ====================
local function jumpToTargetGame()
    print(string.rep("=", 60))
    print("[Jump] No NPCs found! Jumping to target game...")
    print(string.format("[Jump] Target Game ID: %d", CONFIG.TARGET_PLACE_ID))
    print(string.rep("=", 60))
    
    sendJumpDiscord()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "JumpNotification"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 80)
    frame.Position = UDim2.new(0.5, -250, 0.8, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.Parent = gui
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = string.format("🔄 NO NPCS FOUND!\nJumping to game %d in %d seconds...", 
        CONFIG.TARGET_PLACE_ID, CONFIG.TELEPORT_DELAY)
    text.TextColor3 = Color3.fromRGB(255, 200, 0)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = frame
    
    task.wait(CONFIG.TELEPORT_DELAY)
    gui:Destroy()
    
    local success, err = pcall(function()
        TeleportService:Teleport(CONFIG.TARGET_PLACE_ID, LocalPlayer)
    end)
    
    if not success then
        print("[Jump] Teleport failed: " .. tostring(err))
        pcall(function()
            TeleportService:QueueTeleport(CONFIG.TARGET_PLACE_ID, LocalPlayer)
            task.wait(0.5)
            LocalPlayer:Kick("Jumping to " .. CONFIG.TARGET_PLACE_ID)
        end)
    end
end

-- ==================== SCAN FOR NPCS ====================
local function scanForNPCs()
    local found = {}
    print(string.format("\n[Scan] Time: %s", getServerTime()))
    
    for _, target in ipairs(CONFIG.TARGETS) do
        local exists = checkNPC(target)
        if exists then
            print("[✅ FOUND] " .. target.Name)
            table.insert(found, target)
            sendFoundDiscord(target.Name)
        else
            print("[❌ NOT FOUND] " .. target.Name)
        end
    end
    return found
end

-- ==================== ON-SCREEN STATUS ====================
local function showStatus(message)
    local gui = Instance.new("ScreenGui")
    gui.Name = "NPCHunterStatus"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 450, 0, 50)
    frame.Position = UDim2.new(0.5, -225, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.Parent = gui
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = message
    text.TextColor3 = Color3.fromRGB(0, 255, 0)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = frame
    
    task.wait(3)
    gui:Destroy()
end

-- ==================== HEARTBEAT KEEPER (PREVENTS SCRIPT DEATH) ====================
local lastHeartbeat = tick()
RunService.Heartbeat:Connect(function()
    lastHeartbeat = tick()
end)

-- ==================== MAIN LOOP ====================
local scanCount = 0

local function start()
    print("=" .. string.rep("=", 70))
    print("👾 NPC HUNTER — PERSISTENT AUTO-EXECUTE (FIXED) 👾")
    print(string.rep("=", 70))
    for _, target in ipairs(CONFIG.TARGETS) do
        print(string.format("  🎯 %s", target.Name))
    end
    print(string.format("[Target Game ID] %d", CONFIG.TARGET_PLACE_ID))
    print(string.format("[Auto-Execute] PERSISTENT — will reload EVERY time"))
    print("=" .. string.rep("=", 70))
    
    showStatus("👾 NPC HUNTER ACTIVE — Persistent auto-execute enabled")
    task.wait(CONFIG.SCAN_DELAY_ON_JOIN)
    
    while true do
        scanCount = scanCount + 1
        local playerCount = getPlayerCount()
        local serverTime = getServerTime()
        
        print(string.format("\n[Scan #%d] Server: %s", scanCount, string.sub(game.JobId, 1, 20)))
        print(string.format("[Scan #%d] Players: %d | Time: %s", scanCount, playerCount, serverTime))
        
        local found = scanForNPCs()
        
        if #found > 0 then
            print(string.format("[Result] ✅ Found %d NPC(s)! Staying.", #found))
            scanCount = 0
            task.wait(CONFIG.SCAN_INTERVAL * 2)
        else
            print("[Result] ❌ No NPCs found.")
            
            if scanCount >= CONFIG.SCANS_BEFORE_JUMP then
                jumpToTargetGame()
                break
            else
                task.wait(CONFIG.SCAN_INTERVAL)
            end
        end
    end
end

-- Run with error recovery
local function runWithRecovery()
    local success, err = pcall(start)
    if not success then
        print("[NPC Hunter] CRASHED: " .. tostring(err))
        print("[NPC Hunter) Restarting in 5 seconds...")
        task.wait(5)
        runWithRecovery()
    end
end

runWithRecovery()

-- Keep alive
while true do
    task.wait(1)
end
