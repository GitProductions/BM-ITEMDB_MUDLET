--  Current issue is when re-installing the module it seems we completely lose our token, despite doing the best we can to save it
-- seems that the cause may be due to mudlet completely deleting the table when uninstalling??
-- SO we may have to consider saving to documents folder if its possible?
-- ============================================================
-- Item DB - Core helpers and shared state
-- ============================================================
itemdb = itemdb or {}
itemdb.version = "1.0.3"
itemdb.BASE_URL = "https://bm-itemdb.gitago.dev"
-- itemdb.BASE_URL = "http://localhost:3000"

-- users token for submissions
itemdb.token = itemdb.token or ""
itemdb.tokenVerified = itemdb.tokenVerified or false

--  Save Paths  - DB-Util.lua
local configFile = "bmud_itemdb_config.lua"
local packagePath = getMudletHomeDir()
itemdb.savePath = packagePath .. "/" .. configFile

-- for makeHeader & makeFooter and other UI facing message prompts later
itemdb.ui = itemdb.ui or {}

-- Item-DB-Startup
itemdb.update = itemdb.update or {
    available = false,
    latestVersion = nil,
    patchNotes = nil
}

-- Used to silence the verify message until startup complete.. - can later be replaced by just registering and raising an event possibly 
itemdb.startupComplete = false

-- Inventory Data 
itemdb.inventory = {}

itemdb.defaultState = {
    userOOCPrefix = "New Item Submitted:",
    freshStart = true,
    debugMode = false,
    submissionTimeout = 30, -- seconds until we reset the item submission state in case something goes wrong and we don't get a response from the user or the ItemDB after submission
    windowAutoOption = "hide", -- options: hide / minimize / none - automatically hides the window by default after submissions. hide 

    captureActive = false,
    captureLines = {},
    captureName = nil,
    selectingInventoryItem = false,
    submitTimer = nil,
    searchCurrentUrl = nil,
    searchCurrentQuery = nil,
    searchHandlersRegistered = false

}

itemdb.state = itemdb.state or itemdb.defaultState

-- ============================================================
-- FOR DEVELOPMENT USE ONLY
-- ============================================================

local function killMDK()
    for pkgName, _ in pairs(package.loaded) do
        if pkgName:find("MDK") then
            debugc("Uncaching lua package " .. pkgName)
            package.loaded[pkgName] = nil
        end
    end
end
local function create_helper()
    if MDKhelper then
        MDKhelper:stop()
    end
    MDKhelper = Muddler:new({
        path = "C:\\Users\\GitPC\\Documents\\GitHub\\BM-ITEMDB_MUDLET\\BM-ITEMDB_MUDLET",
        watch = true,

        postremove = killMDK
    })
end
if not MDKhelper then
    registerAnonymousEventHandler("sysLoadEvent", create_helper)
end

-- -- ============================================================
-- -- UTIL FUNCTIONS
-- -- ============================================================

-- local function versionToNum(v)
--     local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)")
--     if not a then
--         return 0
--     end
--     return tonumber(a) * 10000 + tonumber(b) * 100 + tonumber(c)
-- end

-- local function hasMpackageAsset(assets)
--     if type(assets) ~= "table" then
--         return false
--     end
--     for _, asset in ipairs(assets) do
--         if type(asset.name) == "string" and asset.name:match("%.mpackage$") then
--             return true
--         end
--     end
--     return false
-- end

-- ============================================================
-- MESSAGE DISPLAYS
-- ============================================================

local function makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
    borderColor       = borderColor       or "spring_green"
    titleBracketColor = titleBracketColor or "orange_red"
    titleTextColor    = titleTextColor    or "yellow"
    boxWidth          = boxWidth          or 60

    local leftTag  = "[ ItemDB ]"
    local rightTag = "[ " .. title .. " ]"

    -- ┏━ + leftTag + ━ + middle + ━ + rightTag + ━┓
    -- that's 2 (┏━) + leftTag + 1 + middle + 1 + rightTag + 2 (━┓) = boxWidth
    local fixed  = 2 + #leftTag + 1 + 1 + #rightTag + 2
    local middle = string.rep("━", math.max(boxWidth - fixed, 1))

    cecho("\n<" .. borderColor .. ">┏━<" .. borderColor .. ">[ <white>ItemDB <" .. borderColor .. ">]<" ..
        borderColor .. ">━" .. middle .. "━<" .. titleBracketColor .. ">[ <" .. titleTextColor .. ">" .. title ..
        " <" .. titleBracketColor .. ">]<" .. borderColor .. ">━┓\n")
end

local function makeFooter(borderColor, boxWidth)
    borderColor = borderColor or "spring_green"
    boxWidth = boxWidth or 60
    local line = string.rep("━", boxWidth -2)
    cecho("<" .. borderColor .. ">┗" .. line .. "┛\n\n")
end


function itemdb.ui.makeStatusFooter(borderColor, boxWidth)
    borderColor = borderColor or "spring_green"
    boxWidth    = boxWidth or 60
    local labelColor = "white"

    local innerWidth = boxWidth - 2
    local divider    = string.rep("━", innerWidth)

    local tokenStatus, tokenColor
    if itemdb.tokenVerified then
        tokenStatus = "Verified"
        tokenColor  = "spring_green"
    else
        tokenStatus = "Not Verified"
        tokenColor  = "yellow"
    end

    local updateStatus, updateColor
    if itemdb.update.available then
        updateStatus = "Available"
        updateColor  = "yellow"
    else
        updateStatus = "Up to Date"
        updateColor  = "spring_green"
    end

    local left  = " Token: " .. tokenStatus
    local right = "Update: " .. updateStatus .. " "

    local padding = innerWidth - #left - #right
    local spacer  = string.rep(" ", math.max(1, padding))

    cecho("<" .. borderColor .. ">┣" .. divider .. "┫\n")
    cecho("<" .. borderColor .. ">┃")
    cecho("<" .. labelColor .. "> Token: <" .. tokenColor .. ">" .. tokenStatus)
    cecho("<white>" .. spacer)
    cecho("<" .. labelColor .. ">Update: ")

    if itemdb.update.available then
        cechoLink(
            "<" .. updateColor .. ">" .. "<u>" .. updateStatus .. "</u> ",
            [[itemdb.showUpdateAvailable(itemdb.update.latestVersion, itemdb.version)]],
            "Click to view update details",
            true
        )
    else
        cecho("<" .. updateColor .. ">" .. updateStatus .. " ")
    end

    cecho("<" .. borderColor .. ">┃\n")
    cecho("<" .. borderColor .. ">┗" .. divider .. "┛\n")
end


function itemdb.ui.makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
    makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
end
function itemdb.ui.makeFooter(borderColor, boxWidth)
    makeFooter(borderColor, boxWidth)
end

-- We should rename all functions that show messages to be under itemdb.ui.<function> and move them to a UI file?
function itemdb.help()
    makeHeader("Available Commands", "light_blue", "light_blue", "white", 80)
    cecho("<light_blue>┃\n")

    local commands = {{
        display = "itemdb.setToken <green><token>",
        plain = "itemdb.setToken <token>",
        desc = "Set your user token for submissions"
    }, -- { display = "itemdb.show",
    -- plain = "itemdb.show",               
    -- desc = "Show your current user token"                  },
    {
        display = "itemdb.search <green><text>",
        plain = "itemdb.search <text>",
        desc = "Search items by name or keyword"
    }, {
        display = "itemdb.setMessage <green><prefix>",
        plain = "itemdb.setMessage <prefix>",
        desc = "Set custom OOC prefix for sharing submissions"
    }, {
        display = "itemdb.setTimeout <green><seconds>",
        plain = "itemdb.setTimeout <seconds>",
        desc = "Set custom timeout seconds for submission requests" ..
            (itemdb.state.submissionTimeout and (" <green>(" .. itemdb.state.submissionTimeout .. "s)") or "")
    }, {
        display = "itemdb.debug",
        plain = "itemdb.debug",
        desc = "Toggle debug mode for error logging" .. (itemdb.state.debugMode and " <green>(ON)" or " <red>(OFF)")
    }, {
        display = "itemdb.welcome",
        plain = "itemdb.welcome",
        desc = "Show the welcome message"
    }, {
        display = "itemdb.reset",
        plain = "itemdb.reset",
        desc = "Reset the ItemDB configuration"
    }, {
        display = "itemdb",
        plain = "itemdb",
        desc = "Show this help menu"
    }}

    local maxLen = 0
    for _, entry in ipairs(commands) do
        maxLen = math.max(maxLen, #entry.plain)
    end

    local headerGap = string.rep(" ", (maxLen + 4) - #"Command")
    cecho("<light_blue>┃  <dim_grey>Command" .. headerGap .. "<gray>│ <dim_grey>Description\n")
    cecho("<light_blue>┃  <dim_grey>" .. string.rep("─", maxLen + 4) .. "<gray>┼<dim_grey>" ..
              string.rep("─", 41) .. "\n")

    for _, entry in ipairs(commands) do
        local padding = string.rep(" ", (maxLen + 4) - #entry.plain)
        cecho("<light_blue>┃  <yellow>" .. entry.display .. padding .. "<gray>│ <wheat>" .. entry.desc .. "\n")
    end

    cecho("<light_blue>┃\n")
    makeFooter("light_blue", 80)
end

function itemdb.showFirstTimeSetup()
    makeHeader("First Time Setup", "spring_green", "spring_green", "white")

    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB " .. tostring(itemdb.version or "?") ..
              " - First Time Setup<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>To submit items, edits, or help grow the database,\n")
    cecho("<spring_green>┃ <white>you need to set your authentication token.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>Quick start guide:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  1. <light_cyan>Sign up or log in<reset> to get your token:\n")
    cecho("<spring_green>┃     ")
    cechoLink("<light_cyan>https://bm-itemdb.gitago.dev/account", [[openUrl("https://bm-itemdb.gitago.dev/account")]],
        "Click to open the account page in your browser", true)
    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃  2. Copy your <white>API Token<reset> from the account page.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  3. In-game, type:\n")
    cecho("<spring_green>┃     <white>itemdb.setToken YOUR_TOKEN_HERE\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Until the token is set, submissions are disabled.\n")
    cecho("<spring_green>┃ <dim_grey>It only takes a minute - thanks for helping build the DB!\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>><white> Type <yellow>itemdb <white>for a list of commands.\n")
    cecho("<spring_green>┃\n")

    itemdb.ui.makeStatusFooter("spring_green", 60)

    itemdb.state.freshStart = false
end





function itemdb.showStartupMessage()
    -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    itemdb.ui.makeHeader("Welcome Back!", "spring_green", "grey", "white", 60)
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB V" .. tostring(itemdb.version or "?") .. " - Ready<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>Welcome back! Your token is active.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>><white> Type <yellow>itemdb <white>for a list of commands.\n")
    cecho("<spring_green>┃\n")

    -- status footer includes the update status and if token is verified
    itemdb.ui.makeStatusFooter("spring_green", 60)
end


-- Utilized for patchnotes to go thru each line and prefix or add space to better fit our patchnotes window
local function echoBoxed(text, borderColor, textColor, boxWidth)
    borderColor = borderColor or "spring_green"
    textColor   = textColor   or "white"
    boxWidth    = boxWidth    or 60

    local innerWidth = boxWidth - 4 -- ┃ + space + text + space

    -- wrap long lines
    local function wrapLine(line, width)
        local wrapped = {}
        while #line > width do
            local chunk = line:sub(1, width)
            local breakAt = chunk:find("%s[%S]*$") -- break at last space
            if breakAt and breakAt > 1 then
                table.insert(wrapped, line:sub(1, breakAt - 1))
                line = line:sub(breakAt + 1)
            else
                table.insert(wrapped, chunk)
                line = line:sub(width + 1)
            end
        end
        table.insert(wrapped, line)
        return wrapped
    end

    for rawLine in (text .. "\n"):gmatch("([^\n]*)\n") do
        local lines = wrapLine(rawLine, innerWidth)
        for _, line in ipairs(lines) do
            cecho("<" .. borderColor .. ">  <" .. textColor .. ">" .. line .. "\n")
        end
    end
end

local function showPatchNotes()
    if itemdb.update.patchNotes and itemdb.update.patchNotes ~= "" then
        -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
        makeHeader("Latest Patch Notes", "spring_green", "yellow", "light_blue")
        cecho("<spring_green>┃\n")
        echoBoxed(itemdb.update.patchNotes, "spring_green", "white", 60)
        cecho("<spring_green>┃\n")
        cecho("<spring_green>┃\n")
        makeFooter("spring_green")
    end
end

function itemdb.showUpdateAvailable(latestVersion, currentVersion)
    -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    itemdb.ui.makeHeader("Update Available", "spring_green", "green", "white")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>Your version:   <red>v" .. currentVersion .. "<reset>\n")
    cecho("<spring_green>┃ <white>Latest version: <green>" .. latestVersion .. "<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>To update, click below or reinstall manually:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  ")
    cechoLink("► Click <royal_blue><u>here</u><reset> to install the latest update now!",
        [[installPackage("https://bm-itemdb.gitago.dev/itemdb.mpackage")]],
        "Click to automatically download and install the latest version", true)
    cecho("\n<spring_green>┃\n")

    cecho("<spring_green>┃  ")
    cechoLink("<light_cyan>► View release notes here   ", showPatchNotes, "Click to view the latest patch notes", true)

    cechoLink("    <light_cyan>► View release notes on GitHub",
        [[openUrl("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest")]],
        "Click to open the release page in your browser", true)

    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Mudlet will handle the install automatically.")
    cecho("\n<spring_green>┃\n")
    itemdb.ui.makeFooter("spring_green")
end




-- ============================================================
-- WHEN USER IDENTIFIES AN ITEM - CAPTURE LINES, ASK TO SUBMIT, HANDLE SELECTION
-- ============================================================

-- Used to reset captured lines after submission or cancellation
local function resetCaptureLines()
    itemdb.state.captureLines = {}
    itemdb.state.captureName = nil
end

-- When an identify line is received, capture it
function itemdb.startIdentifyCapture()
    if itemdb.state.selectingInventoryItem then
        cecho("<yellow>[ITEMDB] <gray>- <orange>[New identify detected - cancelling previous submission]\n")
        itemdb.clearItemSelection(true)
    end

    itemdb.state.captureActive = true
    resetCaptureLines()
    cecho("<yellow>[ITEMDB] <gray>- [Identify capture started...]\n")
    setTriggerStayOpen("IdentifyStart", 99)
end

function itemdb.captureIdentifyLine(line)
    if not (itemdb.state.captureActive and line) then
        return
    end

    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    if string.find(line, "You recite a scroll of identify", 1, true) or trimmed:match("^You feel informed:") or trimmed ==
        "" or (trimmed:match("^<") and trimmed:match("%d") and trimmed:match(">$")) or
        (#itemdb.state.captureLines > 0 and trimmed ==
            itemdb.state.captureLines[#itemdb.state.captureLines]:gsub("^%s+", ""):gsub("%s+$", "")) then
        setTriggerStayOpen("IdentifyStart", 1)
        return
    end

    table.insert(itemdb.state.captureLines, line)

    if not itemdb.state.captureName then
        local n = line:match("Object '([^']+)'")
        if n then
            itemdb.state.captureName = n
        end
    end

    setTriggerStayOpen("IdentifyStart", 1)
end

-- After identify has finished we process and display the captured lines 
function itemdb.finishIdentifyCapture()
    if not itemdb.state.captureActive then
        return
    end

    setTriggerStayOpen("IdentifyStart", 0)
    itemdb.state.captureActive = false

    if itemdb.state.debugMode == true then
        local count = #itemdb.state.captureLines
        if count > 0 then
            cecho("<cyan>+----------------- Item Identified -----------------+\n")
            for _, l in ipairs(itemdb.state.captureLines) do
                cecho("<cyan>| <white>" .. l .. "\n")
            end
            cecho("<cyan>+---------------------------------------------------+\n\n")
        else
            cecho("<yellow>[ITEMDB] <orange>No useful lines captured?\n")
        end
    end

    -- expandAlias("capture-item-button")

    -- Ask user initites a button to ask user if they want to submit item..
    -- if selecting yes, the users inventory is opened and parsed and we attach buttons to each line..
    -- we now want to move away from this and instead make the buttons in our UI window appear for the user.. and or we need to show the window
    itemdb.askUser()

    -- resetCaptureLines()
end

function itemdb.ui.showWindow()
    if itemdb.state.windowAutoOption == "hide" then
        itemdb.inventory.window:show()
        itemdb.inventory.window:restore()
    elseif itemdb.state.windowAutoOption == "minimize" then
        itemdb.inventory.window:show()
        itemdb.inventory.window:restore()
    end
end

-- Prompt user to open inventory to finalize the identify submission process by selecting short name
function itemdb.askUser()
    cecho("<yellow>[Item-DB]: <light_blue>Submit Item: ")
    cechoLink("<green><b>[ Open Inventory ]</b>", function()
        cecho("Preparing to submit item...\n")
        cecho("<yellow>Select the item from your inventory:\n\n")

        itemdb.startItemSelection(itemdb.state.submissionTimeout)
        send("inv")

        -- Showing the inventory window + restoring just to make 100% sure its available for user
        itemdb.ui.showWindow()

    end, "[Item-DB]: Click to submit item", true)

    cecho("  ") -- spacing

    cechoLink("<red><b>[ CANCEL ]</b>", function()
        cecho("<yellow>Item submission cancelled.\n")
        itemdb.clearItemSelection(true)
    end, "[Item-DB]: Cancel and discard this item", true)
    cecho("\n\n")
end

--  
function itemdb.startItemSelection(timeoutSeconds)

    itemdb.state.selectingInventoryItem = true

    if itemdb.state.submitTimer then
        killTimer(itemdb.state.submitTimer)
    end

    itemdb.state.submitTimer = tempTimer(timeoutSeconds or 15, function()
        if itemdb.state.selectingInventoryItem then
            cecho("\n<yellow>[ITEMDB] - <red>[TIMEOUT] Item submission cancelled automatically.\n")
            itemdb.clearItemSelection(true)
        end
    end)
end

-- this should be moved to inventory.. 
-- but resetCaptureLines needs to go to..
function itemdb.clearItemSelection(clearCapture)
    itemdb.state.selectingInventoryItem = false

    if itemdb.state.submitTimer then
        killTimer(itemdb.state.submitTimer)
        itemdb.state.submitTimer = nil
    end

    if clearCapture then
        resetCaptureLines()
    end
end
