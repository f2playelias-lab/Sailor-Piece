--[[
    NPC HUNTER — Sailor Piece (Kraken, Cosmic Being, Sea Serpent)
    GitHub: https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ==================== AUTO-EXECUTE SETUP ====================

-- YOUR CORRECT GITHUB RAW URL
local SCRIPT_URL = "https://raw.githubusercontent.com/f2playelias-lab/Sailor-Piece/refs/heads/main/npc_hunter.lua"

-- SET THIS TO TRUE
local USE_URL_AUTOEXECUTE = true

-- Detect executor's queue_on_teleport function
local queue_on_teleport_func = nil

if syn and syn.queue_on_teleport then
    queue_on_teleport_func = syn.queue_on_teleport
    print("[Auto-Execute] Synapse X detected")
elseif queue_on_teleport then
    queue_on_teleport_func = queue_on_teleport
    print("[Auto-Execute] Standard queue_on_teleport detected")
elseif fluxus and fluxus.queue_on_teleport then
    queue_on_teleport_func = fluxus.queue_on_teleport
    print("[Auto-Execute] Fluxus detected")
elseif krnl and krnl.queue_on_teleport then
    queue_on_teleport_func = krnl.queue_on_teleport
    print("[Auto-Execute] Krnl detected")
else
    print("[Auto-Execute] ⚠️ No queue_on_teleport found! Auto-execute will NOT work.")
end

local teleportQueued = false

local function setupAutoExecute()
    if not queue_on_teleport_func then
        return false
    end
    
    if USE_URL_AUTOEXECUTE and SCRIPT_URL then
        queue_on_teleport_func('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
        print("[Auto-Execute] ✅ Queued reload from: " .. SCRIPT_URL)
        return true
    end
    return false
end

-- Listen for teleport
if queue_on_teleport_func then
    LocalPlayer.OnTeleport:Connect(function(state)
        if not teleportQueued then
            teleportQueued = true
            print("[Auto-Execute] Teleport detected! Queueing script reload...")
            setupAutoExecute()
        end
    end)
    print("[Auto-Execute] ✅ ACTIVE — Script will auto-reload after teleport")
else
    print("[Auto-Execute] ❌ INACTIVE — queue_on_teleport not available")
end

-- ==================== CONFIGURATION ====================
local CONFIG = {
    -- ALL 3 TARGET NPCs
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
    
    -- DISCORD WEBHOOK
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1497331954293674106/4U2_9j_TmEhmkC4Ig3NR_UDega-2c0t4KP3gnw-bNpbxNkRYfa9wcY0J-XF4ETBvCRg1",
    
    -- TARGET GAME TO JOIN IF NOTHING FOUND
    TARGET_PLACE_ID = 77747658251236,
    
    -- SCAN SETTINGS
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
    
    -- Try ServerInfo.AutoSizeHolder.ServerTime
    local serverInfo = serverTimeUI:FindFirstChild("ServerInfo")
    if serverInfo then
        local autoSizeHolder = serverInfo:FindFirstChild("AutoSizeHolder")
        if autoSizeHolder then
            local serverTime = autoSizeHolder:FindFirstChild("ServerTime")
            if serverTime and (serverTime:IsA("TextLabel") or serverTime:IsA("TextButton")) then
                local text = serverTime.Text
                if text and text ~= "" then
                    return text
                end
            end
        end
    end
    
    -- Try ServerTimeClient
    local timeClient = serverTimeUI:FindFirstChild("ServerTimeClient")
    if timeClient and (timeClient:IsA("TextLabel") or timeClient:IsA("TextButton")) then
        local text = timeClient.Text
        if text and text ~= "" then
            return text
        end
    end
    
    -- Try ServerTimeClient_v1_BEFORE_X3_EVENTS
    local timeClientV1 = serverTimeUI:FindFirstChild("ServerTimeClient_v1_BEFORE_X3_EVENTS")
    if timeClientV1 and (timeClientV1:IsA("TextLabel") or timeClientV1:IsA("TextButton")) then
        local text = timeClientV1.Text
        if text and text ~= "" then
            return text
        end
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

-- ==================== DISCORD FUNCTIONS ====================
local lastSend = {}
local lastJumpSend = 0

local function sendFoundDiscord(npcName)
    if not httpRequest then return end
    
    local now = os.time()
    if lastSend[npcName] and (now - lastSend[npcName]) < 60 then return end
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
    pcall(function()
        httpRequest({Url = CONFIG.DISCORD_WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        print("[Discord] ✅ Sent: " .. npcName)
    end)
end

local function sendJumpDiscord()
    if not httpRequest then return end
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
        httpRequest({Url = CONFIG.DISCORD_WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
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

-- ==================== MAIN LOOP ====================
local scanCount = 0

local function start()
    print("=" .. string.rep("=", 70))
    print("👾 NPC HUNTER — ALL 3 TARGETS (Kraken, Cosmic Being, Sea Serpent) 👾")
    print(string.rep("=", 70))
    for _, target in ipairs(CONFIG.TARGETS) do
        print(string.format("  🎯 %s", target.Name))
    end
    print(string.format("[Target Game ID] %d", CONFIG.TARGET_PLACE_ID))
    print(string.format("[Auto-Execute URL] %s", SCRIPT_URL))
    print(string.format("[Auto-Execute Status] %s", (queue_on_teleport_func and USE_URL_AUTOEXECUTE) and "ACTIVE ✅" or "INACTIVE ❌"))
    print("=" .. string.rep("=", 70))
    
    showStatus("👾 NPC HUNTER ACTIVE — Scanning for Kraken, Cosmic Being, Sea Serpent")
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

pcall(start)
while true do task.wait(1) end
